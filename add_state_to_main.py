#!/usr/bin/env python3
"""
Add State group to main MeetingManager group
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Add State group to MeetingManager group children (after Services)
pattern = r'(A1000021000000000000001 /\* MeetingManager \*/ = \{[^}]+children = \([^)]+8DBD85C42F194402006D34D1 /\* Services \*/,)'
match = re.search(pattern, content, re.DOTALL)

if match:
    main_children = match.group(1)
    if '8DBA775F2F22B37100C43859' not in main_children:
        new_main = main_children + '\n\t\t\t\t8DBA775F2F22B37100C43859 /* State */,'
        content = content.replace(main_children, new_main)
        print("✓ Added State group to MeetingManager group")
    else:
        print("State group already in MeetingManager group")
else:
    print("✗ Could not find MeetingManager group")
    exit(1)

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("✓ State group added to main MeetingManager group")
