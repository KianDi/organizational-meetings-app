#!/usr/bin/env python3
"""
Add NameMatcher and TaskService to their respective groups
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# 1. Add NameMatcher to Utilities group (if it exists), otherwise create it
utilities_group_pattern = r'(AD183FCA94F44CD1B4076173 /\* Utilities \*/ = \{[^}]+children = \([^)]+)'
match = re.search(utilities_group_pattern, content, re.DOTALL)

if match:
    utilities_children = match.group(1)
    if '51543D286E06437CA5D8C9B5' not in utilities_children:
        new_utilities = utilities_children + '\n\t\t\t\t51543D286E06437CA5D8C9B5 /* NameMatcher.swift */,'
        content = content.replace(utilities_children, new_utilities)
        print("✓ Added NameMatcher to Utilities group")
    else:
        print("NameMatcher already in Utilities group")
else:
    print("✗ Utilities group not found")

# 2. Add TaskService to Services group
services_group_pattern = r'(8DBD85C42F194402006D34D1 /\* Services \*/ = \{[^}]+children = \([^)]+)'
match = re.search(services_group_pattern, content, re.DOTALL)

if match:
    services_children = match.group(1)
    if 'A7F83D71C850416BA0783B3E' not in services_children:
        new_services = services_children + '\n\t\t\t\tA7F83D71C850416BA0783B3E /* TaskService.swift */,'
        content = content.replace(services_children, new_services)
        print("✓ Added TaskService to Services group")
    else:
        print("TaskService already in Services group")
else:
    print("✗ Services group not found")

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("\n✓ Groups updated")
