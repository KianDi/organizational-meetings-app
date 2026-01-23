#!/usr/bin/env python3
"""
Add NameMatcher and TaskService to PBXSourcesBuildPhase
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# UUIDs from previous script
name_matcher_build_uuid = "22E384E40B8F4E11BCB53CD8"
task_service_build_uuid = "916957285D6C470C8099E6EE"

# Find PBXSourcesBuildPhase section with files list
sources_phase_pattern = r'(/\* Begin PBXSourcesBuildPhase section \*/.*?buildActionMask[^;]+;)'
match = re.search(sources_phase_pattern, content, re.DOTALL)

if match:
    sources_section = match.group(1)

    # Find the files = ( ... ); block within this section
    files_pattern = r'(files = \([^)]+)(\);)'
    files_match = re.search(files_pattern, sources_section)

    if files_match:
        files_list = files_match.group(1)

        # Add our new build file references
        new_files_list = files_list + f'\n\t\t\t\t{name_matcher_build_uuid} /* NameMatcher.swift in Sources */,\n\t\t\t\t{task_service_build_uuid} /* TaskService.swift in Sources */,'

        # Replace in the original content
        new_sources_section = sources_section.replace(files_list, new_files_list)
        content = content.replace(sources_section, new_sources_section)

        print("✓ Added files to PBXSourcesBuildPhase")
    else:
        print("✗ Could not find files list in PBXSourcesBuildPhase")
        exit(1)
else:
    print("✗ Could not find PBXSourcesBuildPhase section")
    exit(1)

# Write the modified project file
with open(project_path, 'w') as f:
    f.write(content)

print("✓ Project file updated successfully")
