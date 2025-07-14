#!/usr/bin/env python3
"""
Dead File Detector for iOS ThriveUp Project

This script analyzes the ThriveUp iOS project to detect potentially dead/unused files:
- Swift files not included in the Xcode project build
- Swift files not imported by any other files
- Asset files not referenced in code
- Storyboard/XIB files not connected to code

Usage: python3 dead_file_detector.py
"""

import os
import re
import json
import sys
from pathlib import Path
from typing import Set, Dict, List, Tuple
from collections import defaultdict

class DeadFileDetector:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.pbxproj_path = self.project_root / "ThriveUp.xcodeproj" / "project.pbxproj"
        self.source_dir = self.project_root / "workingModel"
        
        # File sets
        self.all_swift_files: Set[Path] = set()
        self.xcode_included_files: Set[str] = set()
        self.imported_files: Set[str] = set()
        self.referenced_assets: Set[str] = set()
        self.storyboard_connections: Set[str] = set()
        
        # Results
        self.dead_swift_files: List[Path] = []
        self.dead_assets: List[Path] = []
        self.orphaned_storyboards: List[Path] = []
        
    def find_all_swift_files(self):
        """Find all .swift files in the project directory"""
        print("🔍 Finding all Swift files...")
        for swift_file in self.project_root.rglob("*.swift"):
            # Skip Pods directory and hidden files
            if "Pods/" not in str(swift_file) and not any(part.startswith('.') for part in swift_file.parts):
                self.all_swift_files.add(swift_file)
        print(f"   Found {len(self.all_swift_files)} Swift files")
    
    def parse_xcode_project(self):
        """Parse the Xcode project file to find files included in build"""
        print("📋 Parsing Xcode project file...")
        
        if not self.pbxproj_path.exists():
            print(f"   ⚠️  Project file not found: {self.pbxproj_path}")
            return
            
        try:
            with open(self.pbxproj_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Find Swift files referenced in the project
            # Pattern matches: filename.swift */ = {isa = PBXFileReference
            swift_pattern = r'/\* ([^*]+\.swift) \*/ = \{isa = PBXFileReference'
            matches = re.findall(swift_pattern, content)
            
            for match in matches:
                self.xcode_included_files.add(match)
            
            print(f"   Found {len(self.xcode_included_files)} Swift files in Xcode project")
            
        except Exception as e:
            print(f"   ❌ Error parsing project file: {e}")
    
    def analyze_imports_and_references(self):
        """Analyze import statements and file references in Swift files"""
        print("🔗 Analyzing imports and references...")
        
        for swift_file in self.all_swift_files:
            try:
                with open(swift_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find imports (basic analysis - could be extended)
                import_pattern = r'import\s+(\w+)'
                imports = re.findall(import_pattern, content)
                
                # Find potential file references (class names, struct names, etc.)
                # Look for potential Swift class/struct references
                class_pattern = r'\b([A-Z][a-zA-Z0-9]*(?:Controller|View|Cell|Manager|Service|Delegate))\b'
                references = re.findall(class_pattern, content)
                
                # Add references to imported files set
                for ref in references:
                    self.imported_files.add(ref)
                
                # Find asset references
                asset_patterns = [
                    r'UIImage\(named:\s*"([^"]+)"\)',
                    r'#imageLiteral\(resourceName:\s*"([^"]+)"\)',
                    r'Image\("([^"]+)"\)',  # SwiftUI
                ]
                
                for pattern in asset_patterns:
                    assets = re.findall(pattern, content)
                    self.referenced_assets.update(assets)
                
                # Find storyboard references
                storyboard_pattern = r'UIStoryboard\(name:\s*"([^"]+)"'
                storyboards = re.findall(storyboard_pattern, content)
                self.storyboard_connections.update(storyboards)
                
            except Exception as e:
                print(f"   ⚠️  Error analyzing {swift_file}: {e}")
        
        print(f"   Found {len(self.imported_files)} potential file references")
        print(f"   Found {len(self.referenced_assets)} asset references")
        print(f"   Found {len(self.storyboard_connections)} storyboard references")
    
    def find_dead_swift_files(self):
        """Identify Swift files that appear to be dead"""
        print("💀 Identifying potentially dead Swift files...")
        
        for swift_file in self.all_swift_files:
            filename = swift_file.name
            basename = swift_file.stem
            
            # Check if file is included in Xcode project
            if filename not in self.xcode_included_files:
                self.dead_swift_files.append(swift_file)
                continue
            
            # Check if the class/controller name appears to be referenced
            # This is a heuristic - could have false positives
            if (basename not in self.imported_files and 
                not any(basename in ref for ref in self.imported_files)):
                
                # Additional checks for common patterns
                is_likely_used = (
                    basename == "AppDelegate" or
                    basename == "SceneDelegate" or
                    basename.endswith("Extensions") or
                    basename.startswith("UI") or
                    "DataModel" in basename or
                    "Manager" in basename
                )
                
                if not is_likely_used:
                    self.dead_swift_files.append(swift_file)
        
        print(f"   Found {len(self.dead_swift_files)} potentially dead Swift files")
    
    def find_dead_assets(self):
        """Find unused asset files"""
        print("🖼️  Analyzing asset usage...")
        
        assets_dir = self.source_dir / "Assets.xcassets"
        if not assets_dir.exists():
            print("   ⚠️  Assets directory not found")
            return
        
        # Find all asset files
        all_assets = set()
        for asset_path in assets_dir.rglob("*.imageset"):
            asset_name = asset_path.name.replace(".imageset", "")
            all_assets.add(asset_name)
        
        # Find unused assets
        for asset in all_assets:
            if asset not in self.referenced_assets:
                self.dead_assets.append(assets_dir / f"{asset}.imageset")
        
        print(f"   Found {len(all_assets)} total assets, {len(self.dead_assets)} potentially unused")
    
    def find_orphaned_storyboards(self):
        """Find storyboard files not referenced in code"""
        print("📱 Checking storyboard usage...")
        
        storyboard_files = list(self.project_root.rglob("*.storyboard"))
        
        for storyboard in storyboard_files:
            storyboard_name = storyboard.stem
            if (storyboard_name not in self.storyboard_connections and 
                storyboard_name != "LaunchScreen"):  # LaunchScreen is usually referenced in Info.plist
                self.orphaned_storyboards.append(storyboard)
        
        print(f"   Found {len(storyboard_files)} storyboards, {len(self.orphaned_storyboards)} potentially orphaned")
    
    def generate_report(self) -> str:
        """Generate a detailed report of dead files"""
        report = []
        report.append("# Dead File Detection Report")
        report.append(f"Project: ThriveUp iOS")
        report.append(f"Analysis Date: {os.popen('date').read().strip()}")
        report.append("")
        
        # Summary
        total_dead = len(self.dead_swift_files) + len(self.dead_assets) + len(self.orphaned_storyboards)
        report.append("## Summary")
        report.append(f"- **Total potentially dead files**: {total_dead}")
        report.append(f"- **Dead Swift files**: {len(self.dead_swift_files)}")
        report.append(f"- **Unused assets**: {len(self.dead_assets)}")
        report.append(f"- **Orphaned storyboards**: {len(self.orphaned_storyboards)}")
        report.append("")
        
        # Dead Swift files
        if self.dead_swift_files:
            report.append("## 🔴 Potentially Dead Swift Files")
            report.append("*These files may not be referenced or used in the project:*")
            report.append("")
            for file_path in sorted(self.dead_swift_files):
                rel_path = file_path.relative_to(self.project_root)
                report.append(f"- `{rel_path}`")
            report.append("")
        
        # Unused assets
        if self.dead_assets:
            report.append("## 🖼️ Potentially Unused Assets")
            report.append("*These asset files don't appear to be referenced in code:*")
            report.append("")
            for asset_path in sorted(self.dead_assets):
                rel_path = asset_path.relative_to(self.project_root)
                report.append(f"- `{rel_path}`")
            report.append("")
        
        # Orphaned storyboards
        if self.orphaned_storyboards:
            report.append("## 📱 Potentially Orphaned Storyboards")
            report.append("*These storyboard files don't appear to be referenced in code:*")
            report.append("")
            for storyboard in sorted(self.orphaned_storyboards):
                rel_path = storyboard.relative_to(self.project_root)
                report.append(f"- `{rel_path}`")
            report.append("")
        
        # Recommendations
        report.append("## 📋 Recommendations")
        report.append("")
        report.append("**⚠️ Important Notes:**")
        report.append("- This analysis uses heuristics and may have false positives")
        report.append("- Always review files manually before deletion")
        report.append("- Some files may be used indirectly (reflection, string-based loading, etc.)")
        report.append("- Test thoroughly after removing any files")
        report.append("")
        report.append("**🔍 Manual Review Needed:**")
        report.append("- Check if files are loaded dynamically")
        report.append("- Verify storyboard segue connections")
        report.append("- Confirm asset usage in Interface Builder")
        report.append("- Look for string-based file references")
        report.append("")
        
        return "\n".join(report)
    
    def run_analysis(self):
        """Run the complete dead file analysis"""
        print("🚀 Starting Dead File Detection Analysis")
        print("=" * 50)
        
        self.find_all_swift_files()
        self.parse_xcode_project()
        self.analyze_imports_and_references()
        self.find_dead_swift_files()
        self.find_dead_assets()
        self.find_orphaned_storyboards()
        
        print("\n" + "=" * 50)
        print("📊 Analysis Complete!")
        
        return self.generate_report()

def main():
    # Determine project root
    project_root = "/home/runner/work/ThriveUp/ThriveUp"
    
    if not os.path.exists(project_root):
        print(f"❌ Project directory not found: {project_root}")
        sys.exit(1)
    
    # Run analysis
    detector = DeadFileDetector(project_root)
    report = detector.run_analysis()
    
    # Save report
    report_path = os.path.join(project_root, "dead_files_report.md")
    with open(report_path, 'w') as f:
        f.write(report)
    
    print(f"\n📄 Report saved to: {report_path}")
    print("\n" + report)

if __name__ == "__main__":
    main()