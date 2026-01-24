#!/usr/bin/env python3
"""
Remove State group from root level - it should only be in MeetingManager group
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Remove State from root group (A1000020000000000000001)
# It should only be in MeetingManager group (A1000021000000000000001)
pattern = r'(A1000020000000000000001 = \{[^}]+children = \([^)]+)\s*8DBA775F2F22B37100C43859 /\* State \*/,\s*'
match = re.search(pattern, content, re.DOTALL)

if match:
    root_children = match.group(1)
    content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
    print("✓ Removed State group from root level")
else:
    print("State group not found in root, or already removed")

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("✓ State group now only in MeetingManager subgroup")
