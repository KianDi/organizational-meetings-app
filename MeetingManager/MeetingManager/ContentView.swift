//
//  ContentView.swift
//  MeetingManager
//
//  Created on 2026-01-14.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "calendar")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Meeting Manager")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
