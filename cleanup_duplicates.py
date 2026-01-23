#!/usr/bin/env python3
"""
Clean up duplicate file entries in Xcode project
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Remove the duplicate entries I created (F3601B795BE7416A8DFC67AE, BC38BEE0E3094676A9208EAE, etc.)
# Keep only the subagent's entries (51543D286E06437CA5D8C9B5, A7F83D71C850416BA0783B3E)

# 1. Remove my NameMatcher build file
content = re.sub(r'\s*22E384E40B8F4E11BCB53CD8 /\* NameMatcher\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = F3601B795BE7416A8DFC67AE /\* NameMatcher\.swift \*/; \};', '', content)

# 2. Remove my TaskService build file
content = re.sub(r'\s*916957285D6C470C8099E6EE /\* TaskService\.swift in Sources \*/ = \{isa = PBXBuildFile; fileRef = BC38BEE0E3094676A9208EAE /\* TaskService\.swift \*/; \};', '', content)

# 3. Remove my NameMatcher file reference
content = re.sub(r'\s*F3601B795BE7416A8DFC67AE /\* NameMatcher\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = NameMatcher\.swift; sourceTree = "<group>"; \};', '', content)

# 4. Remove my TaskService file reference
content = re.sub(r'\s*BC38BEE0E3094676A9208EAE /\* TaskService\.swift \*/ = \{isa = PBXFileReference; lastKnownFileType = sourcecode\.swift; path = TaskService\.swift; sourceTree = "<group>"; \};', '', content)

# 5. Remove duplicate NameMatcher from Utilities group
utilities_pattern = r'(AD183FCA94F44CD1B4076173 /\* Utilities \*/ = \{[^}]+children = \([^)]+)F3601B795BE7416A8DFC67AE /\* NameMatcher\.swift \*/,\s*'
content = re.sub(utilities_pattern, r'\1', content)

# 6. Remove duplicate TaskService from Services group (if any)
services_pattern = r'(8DBD85C42F194402006D34D1 /\* Services \*/ = \{[^}]+children = \([^)]+)BC38BEE0E3094676A9208EAE /\* TaskService\.swift \*/,\s*'
content = re.sub(services_pattern, r'\1', content)

print("✓ Removed duplicate entries")

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("✓ Project cleaned up")
