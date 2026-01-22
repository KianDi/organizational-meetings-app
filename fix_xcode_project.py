#!/usr/bin/env python3
"""
Fix Xcode project.pbxproj to properly add Document group with DocumentPickerView.swift
"""

import re
import uuid

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Generate UUIDs for Document group
document_group_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

# Find the Views group and add Document subgroup to it
views_group_pattern = r'(E4D8353416E9E9075A524262 /\* Views \*/ = \{[^}]+children = \([^)]+)(\s+\);)'
match = re.search(views_group_pattern, content, re.DOTALL)
if match:
    # Add Document group to Views children
    views_children = match.group(1)
    if 'Document' not in views_children:
        new_views_children = views_children + f'\n\t\t\t\t{document_group_uuid} /* Document */,'
        content = content.replace(match.group(1), new_views_children)
        print(f"✓ Added Document group to Views children")
    else:
        print("Document group already in Views children")
else:
    print("✗ Could not find Views group")
    exit(1)

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

# Find where to insert the Document group (after Meeting group)
meeting_group_pattern = r'(16526F6BB89E4A14B0EE9E79 /\* Meeting \*/ = \{[^}]+\};)'
match = re.search(meeting_group_pattern, content, re.DOTALL)
if match:
    # Check if Document group already exists
    if document_group_uuid not in content:
        insertion_point = match.end()
        content = content[:insertion_point] + '\n' + document_group_def + content[insertion_point:]
        print(f"✓ Created Document group definition with UUID {document_group_uuid}")
    else:
        print("Document group definition already exists")
else:
    print("✗ Could not find Meeting group")
    exit(1)

# Write the modified project file
with open(project_path, 'w') as f:
    f.write(content)

print("\n✓ Project file updated successfully")
print(f"  Document group UUID: {document_group_uuid}")
print(f"  DocumentPickerView.swift UUID: CCD66591CAB246FC855B4E62")
print(f"  DocumentService.swift UUID: C704F854A2194E81B2B5FBC7")
