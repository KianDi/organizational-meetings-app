#!/usr/bin/env python3
"""
Add NameMatcher.swift and TaskService.swift to Xcode project
"""

import re
import uuid

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Generate UUIDs for new files
name_matcher_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])
name_matcher_build_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])
task_service_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])
task_service_build_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])
utilities_group_uuid = ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

print(f"Generated UUIDs:")
print(f"  NameMatcher.swift: {name_matcher_uuid}")
print(f"  NameMatcher build: {name_matcher_build_uuid}")
print(f"  TaskService.swift: {task_service_uuid}")
print(f"  TaskService build: {task_service_build_uuid}")
print(f"  Utilities group: {utilities_group_uuid}")

# 1. Add to PBXBuildFile section
build_file_section_end = re.search(r'/\* End PBXBuildFile section \*/', content)
if build_file_section_end:
    new_build_files = f"""\t\t{name_matcher_build_uuid} /* NameMatcher.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {name_matcher_uuid} /* NameMatcher.swift */; }};
\t\t{task_service_build_uuid} /* TaskService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {task_service_uuid} /* TaskService.swift */; }};
"""
    insertion_point = build_file_section_end.start()
    content = content[:insertion_point] + new_build_files + content[insertion_point:]
    print("✓ Added to PBXBuildFile section")

# 2. Add to PBXFileReference section
file_ref_section_end = re.search(r'/\* End PBXFileReference section \*/', content)
if file_ref_section_end:
    new_file_refs = f"""\t\t{name_matcher_uuid} /* NameMatcher.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NameMatcher.swift; sourceTree = "<group>"; }};
\t\t{task_service_uuid} /* TaskService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TaskService.swift; sourceTree = "<group>"; }};
"""
    insertion_point = file_ref_section_end.start()
    content = content[:insertion_point] + new_file_refs + content[insertion_point:]
    print("✓ Added to PBXFileReference section")

# 3. Add to PBXSourcesBuildPhase
sources_phase_pattern = r'(files = \([^)]+)(\s+\);[^}]+buildActionMask[^}]+isa = PBXSourcesBuildPhase)'
match = re.search(sources_phase_pattern, content, re.DOTALL)
if match:
    files_list = match.group(1)
    new_files_list = files_list + f'\n\t\t\t\t{name_matcher_build_uuid} /* NameMatcher.swift in Sources */,\n\t\t\t\t{task_service_build_uuid} /* TaskService.swift in Sources */,'
    content = content.replace(match.group(1), new_files_list)
    print("✓ Added to PBXSourcesBuildPhase")

# 4. Create Utilities group
utilities_group_def = f"""\t\t{utilities_group_uuid} /* Utilities */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{name_matcher_uuid} /* NameMatcher.swift */,
\t\t\t);
\t\t\tpath = Utilities;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

# Find PBXGroup section end and insert Utilities group
pbx_group_end_pattern = r'/\* End PBXGroup section \*/'
match = re.search(pbx_group_end_pattern, content)
if match:
    insertion_point = match.start()
    content = content[:insertion_point] + utilities_group_def + content[insertion_point:]
    print("✓ Created Utilities group")

# 5. Add TaskService to Services group
services_group_pattern = r'(8DBD85C42F194402006D34D1 /\* Services \*/ = \{[^}]+children = \([^)]+)'
match = re.search(services_group_pattern, content, re.DOTALL)
if match:
    services_children = match.group(1)
    new_services_children = services_children + f'\n\t\t\t\t{task_service_uuid} /* TaskService.swift */,'
    content = content.replace(match.group(1), new_services_children)
    print("✓ Added TaskService to Services group")

# 6. Add Utilities group to main MeetingManager group
# Find the MeetingManager group (the one that contains Services, Models, etc.)
main_group_pattern = r'(8DBD85B32F194400006D34D1 /\* MeetingManager \*/ = \{[^}]+children = \([^)]+8DBD85C42F194402006D34D1 /\* Services \*/,[^)]+)'
match = re.search(main_group_pattern, content, re.DOTALL)
if match:
    main_group_children = match.group(1)
    # Add Utilities after Services
    new_main_group = main_group_children.replace(
        '8DBD85C42F194402006D34D1 /* Services */,',
        f'8DBD85C42F194402006D34D1 /* Services */,\n\t\t\t\t{utilities_group_uuid} /* Utilities */,'
    )
    content = content.replace(match.group(1), new_main_group)
    print("✓ Added Utilities group to MeetingManager group")

# Write the modified project file
with open(project_path, 'w') as f:
    f.write(content)

print("\n✓ Project file updated successfully")
