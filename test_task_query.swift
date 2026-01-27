#!/usr/bin/env swift

import Foundation

// Simple script to check if tasks exist in database
// Replace with your Supabase details

let supabaseUrl = "YOUR_SUPABASE_URL"
let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
let meetingId = "MEETING_ID_FROM_APP"

// Query tasks for meeting
let url = URL(string: "\(supabaseUrl)/rest/v1/tasks?meeting_id=eq.\(meetingId)")!
var request = URLRequest(url: url)
request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let data = data, let json = String(data: data, encoding: .utf8) {
        print("Tasks in database:")
        print(json)
    }
    exit(0)
}
task.resume()
RunLoop.main.run()
