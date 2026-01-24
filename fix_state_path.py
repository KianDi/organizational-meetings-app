#!/usr/bin/env python3
"""
Fix State group path in Xcode project
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Fix the State group path
# Change from: path = MeetingManager/State;
# To: path = State;
pattern = r'(8DBA775F2F22B37100C43859 /\* State \*/ = \{[^}]+name = State;\s+path = )MeetingManager/State;'
replacement = r'\1State;'

if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    print("✓ Fixed State group path (MeetingManager/State → State)")
else:
    print("✗ Could not find State group with incorrect path")
    print("Trying alternative pattern...")

    # Try to find and fix it differently
    content = content.replace(
        'name = State;\n\t\t\tpath = MeetingManager/State;',
        'name = State;\n\t\t\tpath = State;'
    )
    print("✓ Fixed using alternative method")

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("✓ State group path corrected")
