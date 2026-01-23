#!/usr/bin/env python3
"""
Add TaskRowView to PBXSourcesBuildPhase
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Find the line with TaskService and add TaskRowView after it
pattern = r'(62E23F86D70C4E729D76F9B0 /\* TaskService\.swift in Sources \*/,)'
replacement = r'\1\n\t\t\t\tDEFD0D9AAF704C909D51FBB4 /* TaskRowView.swift in Sources */,'

if re.search(pattern, content):
    content = re.sub(pattern, replacement, content)
    print("✓ Added TaskRowView to PBXSourcesBuildPhase")
else:
    print("✗ Could not find TaskService in sources phase")
    exit(1)

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("✓ Done")
