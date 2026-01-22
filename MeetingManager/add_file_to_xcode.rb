#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'MeetingManager.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'MeetingManager' }

# Find the Models group
models_group = project.main_group['MeetingManager']['Models']

# Add the file reference
file_ref = models_group.new_file('ProcessingState.swift')

# Add to target
target.add_file_references([file_ref])

# Save the project
project.save

puts "Successfully added ProcessingState.swift to Xcode project"
