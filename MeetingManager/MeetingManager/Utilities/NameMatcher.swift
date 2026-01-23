import Foundation

/// Utility for matching extracted assignee names to organization members
/// and parsing natural language due dates
struct NameMatcher {
    /// Match an extracted name to a list of users
    /// Returns userId if confident match found, nil otherwise
    /// - Parameters:
    ///   - name: Name extracted from document (may contain typos, be partial, etc.)
    ///   - candidates: List of organization members to match against
    /// - Returns: Matched user ID, or nil if no confident match
    static func matchAssignee(
        name: String,
        candidates: [User]
    ) -> UUID? {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Exact match on full name (highest confidence)
        if let match = candidates.first(where: { $0.name.lowercased() == normalizedName }) {
            return match.id
        }

        // 2. Match on email prefix (before @) - high confidence
        let emailPrefix = normalizedName.components(separatedBy: "@").first ?? normalizedName
        if let match = candidates.first(where: {
            $0.email.lowercased().hasPrefix(emailPrefix)
        }) {
            return match.id
        }

        // 3. Partial match on name components (first or last name) - medium confidence
        let nameComponents = normalizedName.split(separator: " ")
        if !nameComponents.isEmpty {
            for candidate in candidates {
                let candidateComponents = candidate.name.lowercased().split(separator: " ")
                // Check if any component matches
                for component in nameComponents {
                    if candidateComponents.contains(where: { $0.hasPrefix(component) || component.hasPrefix($0) }) {
                        return candidate.id
                    }
                }
            }
        }

        // 4. No confident match - return nil
        return nil
    }

    /// Parse natural language due date to Date
    /// Returns nil if can't parse confidently
    /// - Parameter text: Date string (ISO8601, "tomorrow", "next week", weekday names, etc.)
    /// - Returns: Parsed Date, or nil if unable to parse
    static func parseDate(from text: String) -> Date? {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Try ISO8601 first (YYYY-MM-DD format)
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withFullDate]
        if let date = iso8601Formatter.date(from: text) {
            return date
        }

        // Handle common patterns
        let calendar = Calendar.current
        let now = Date()

        // "tomorrow"
        if normalized.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        }

        // "next week"
        if normalized.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        }

        // "friday", "monday", etc. - find next occurrence
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for (index, weekday) in weekdays.enumerated() {
            if normalized.contains(weekday) {
                // Find next occurrence of this weekday
                let targetWeekday = index + 1  // Calendar weekday is 1-indexed
                var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
                components.weekday = targetWeekday

                if let date = calendar.date(from: components), date > now {
                    return date
                } else {
                    // Next week's occurrence
                    components.weekOfYear! += 1
                    return calendar.date(from: components)
                }
            }
        }

        // Can't parse - return nil
        return nil
    }
}
