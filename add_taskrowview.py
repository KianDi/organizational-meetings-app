#!/usr/bin/env python3
"""
Add TaskRowView.swift to Xcode project
"""

import re
import uuid

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Generate UUIDs
task_row_view_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])
task_row_view_build_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

print(f"Generated UUIDs:")
print(f"  TaskRowView.swift: {task_row_view_uuid}")
print(f"  TaskRowView build: {task_row_view_build_uuid}")

# 1. Add to PBXBuildFile section
build_file_section_end = re.search(r'/\* End PBXBuildFile section \*/', content)
if build_file_section_end:
    new_build_file = f"\t\t{task_row_view_build_uuid} /* TaskRowView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {task_row_view_uuid} /* TaskRowView.swift */; }};\n"
    insertion_point = build_file_section_end.start()
    content = content[:insertion_point] + new_build_file + content[insertion_point:]
    print("✓ Added to PBXBuildFile section")

# 2. Add to PBXFileReference section
file_ref_section_end = re.search(r'/\* End PBXFileReference section \*/', content)
if file_ref_section_end:
    new_file_ref = f"\t\t{task_row_view_uuid} /* TaskRowView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TaskRowView.swift; sourceTree = \"<group>\"; }};\n"
    insertion_point = file_ref_section_end.start()
    content = content[:insertion_point] + new_file_ref + content[insertion_point:]
    print("✓ Added to PBXFileReference section")

# 3. Add to PBXSourcesBuildPhase
sources_phase_pattern = r'(/\* Begin PBXSourcesBuildPhase section \*/.*?buildActionMask[^;]+;)'
match = re.search(sources_phase_pattern, content, re.DOTALL)
if match:
    sources_section = match.group(1)
    files_pattern = r'(files = \([^)]+)(\);)'
    files_match = re.search(files_pattern, sources_section)
    if files_match:
        files_list = files_match.group(1)
        new_files_list = files_list + f'\n\t\t\t\t{task_row_view_build_uuid} /* TaskRowView.swift in Sources */,'
        new_sources_section = sources_section.replace(files_list, new_files_list)
        content = content.replace(sources_section, new_sources_section)
        print("✓ Added to PBXSourcesBuildPhase")

# 4. Add to Meeting group
meeting_group_pattern = r'(16526F6BB89E4A14B0EE9E79 /\* Meeting \*/ = \{[^}]+children = \([^)]+)'
match = re.search(meeting_group_pattern, content, re.DOTALL)
if match:
    meeting_children = match.group(1)
    new_meeting_children = meeting_children + f'\n\t\t\t\t{task_row_view_uuid} /* TaskRowView.swift */,'
    content = content.replace(meeting_children, new_meeting_children)
    print("✓ Added to Meeting group")

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("\n✓ TaskRowView.swift added to project")
