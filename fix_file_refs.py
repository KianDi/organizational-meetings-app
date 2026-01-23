#!/usr/bin/env python3
"""
Fix file references to include proper path attribute
"""

import re

# Read the project file
project_path = "/Users/kian/projects/MeetingManager/MeetingManager.xcodeproj/project.pbxproj"
with open(project_path, 'r') as f:
    content = f.read()

# Fix NameMatcher.swift file reference - change from root to Utilities/NameMatcher.swift
name_matcher_pattern = r'51543D286E06437CA5D8C9B5 /\* NameMatcher\.swift \*/ = \{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode\.swift; path = NameMatcher\.swift; sourceTree = "<group>"; \};'
name_matcher_fixed = r'51543D286E06437CA5D8C9B5 /* NameMatcher.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NameMatcher.swift; sourceTree = "<group>"; };'
content = re.sub(name_matcher_pattern, name_matcher_fixed, content)
print("✓ Fixed NameMatcher.swift file reference")

# Fix TaskService.swift file reference
task_service_pattern = r'A7F83D71C850416BA0783B3E /\* TaskService\.swift \*/ = \{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode\.swift; path = TaskService\.swift; sourceTree = "<group>"; \};'
task_service_fixed = r'A7F83D71C850416BA0783B3E /* TaskService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TaskService.swift; sourceTree = "<group>"; };'
content = re.sub(task_service_pattern, task_service_fixed, content)
print("✓ Fixed TaskService.swift file reference")

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("\n✓ File references updated")
