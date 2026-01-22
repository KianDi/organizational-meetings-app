#!/usr/bin/env python3
"""
Fix Xcode project.pbxproj to properly add Document group with DocumentPickerView.swift
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Use the Document group UUID that was already added to Views children
document_group_uuid = 'A5575E0C94A541F58296F370'

# Create the Document group definition
document_group_def = f"""\t\t{document_group_uuid} /* Document */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tCCD66591CAB246FC855B4E62 /* DocumentPickerView.swift */,
\t\t\t);
\t\t\tpath = Document;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

# Find the PBXGroup section end marker and insert before it
pbx_group_end_pattern = r'(/\* End PBXGroup section \*/)'
match = re.search(pbx_group_end_pattern, content)
if match:
    # Check if Document group already exists
    if f'{document_group_uuid} /* Document */ = {{' not in content:
        insertion_point = match.start()
        content = content[:insertion_point] + document_group_def + content[insertion_point:]
        print(f"✓ Created Document group definition")
    else:
        print("Document group definition already exists")
else:
    print("✗ Could not find PBXGroup section end")
    exit(1)

# Write the modified project file
with open(project_path, 'w') as f:
    f.write(content)

print("\n✓ Project file updated successfully")
print(f"  Document group UUID: {document_group_uuid}")
