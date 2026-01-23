#!/usr/bin/env python3
"""
Add Utilities group to main MeetingManager group
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Add Utilities group to main MeetingManager group (after Services)
main_group_pattern = r'(A1000021000000000000001 /\* MeetingManager \*/ = \{[^}]+children = \([^)]+8DBD85C42F194402006D34D1 /\* Services \*/,)'
match = re.search(main_group_pattern, content, re.DOTALL)

if match:
    main_children = match.group(1)
    if 'AD183FCA94F44CD1B4076173' not in main_children:
        new_main = main_children + '\n\t\t\t\tAD183FCA94F44CD1B4076173 /* Utilities */,'
        content = content.replace(main_children, new_main)
        print("✓ Added Utilities group to MeetingManager group")
    else:
        print("Utilities group already in MeetingManager group")
else:
    print("✗ Could not find MeetingManager group")

# Also add Config group if needed (for OpenRouterConfig)
# Check if Config group exists
if 'Config */ = {' in content:
    print("✓ Config group already exists")
else:
    print("Config group not found - OpenRouterConfig might not be in a group")

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("\n✓ Groups updated")
