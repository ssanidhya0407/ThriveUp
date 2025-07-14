#!/usr/bin/env python3
"""
Dead File Verification Script

This script provides additional verification and analysis for the dead files detected
by the main dead_file_detector.py script.

Usage: python3 verify_dead_files.py
"""

import os
import re
import json
from pathlib import Path
from typing import Set, Dict, List

class DeadFileVerifier:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.source_dir = self.project_root / "workingModel"
        
    def check_file_usage_patterns(self, filename: str) -> Dict[str, List[str]]:
        """Check for various usage patterns of a file in the codebase"""
        usage_patterns = {
            'direct_imports': [],
            'string_references': [],
            'class_instantiations': [],
            'segue_references': [],
            'nib_references': []
        }
        
        base_name = Path(filename).stem
        
        # Search through all Swift files for references
        for swift_file in self.project_root.rglob("*.swift"):
            if "Pods/" in str(swift_file):
                continue
                
            try:
                with open(swift_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check for direct class references
                patterns = [
                    rf'\b{base_name}\b',  # Direct class name
                    rf'"{base_name}"',     # String reference
                    rf"'{base_name}'",     # String reference (single quotes)
                    rf'{base_name}\(',     # Class instantiation
                    rf'segue.*"{base_name}"',  # Segue reference
                    rf'nibName.*"{base_name}"'  # NIB reference
                ]
                
                for i, pattern in enumerate(patterns):
                    matches = re.findall(pattern, content, re.IGNORECASE)
                    if matches:
                        key = list(usage_patterns.keys())[i % len(usage_patterns)]
                        rel_path = swift_file.relative_to(self.project_root)
                        usage_patterns[key].append(str(rel_path))
                        
            except Exception as e:
                continue
        
        return usage_patterns
    
    def analyze_xcode_inclusion(self, filename: str) -> bool:
        """Check if file is actually included in Xcode build phases"""
        pbxproj_path = self.project_root / "ThriveUp.xcodeproj" / "project.pbxproj"
        
        if not pbxproj_path.exists():
            return False
            
        try:
            with open(pbxproj_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Check if file is in PBXBuildFile section (actually included in build)
            build_pattern = rf'{Path(filename).name}.*in Sources'
            return bool(re.search(build_pattern, content))
            
        except Exception:
            return False
    
    def verify_dead_files(self, dead_files_list: List[str]) -> Dict[str, Dict]:
        """Verify each file in the dead files list"""
        verification_results = {}
        
        print("🔍 Verifying potentially dead files...")
        
        for file_path in dead_files_list:
            print(f"   Checking: {file_path}")
            
            usage = self.check_file_usage_patterns(file_path)
            in_build = self.analyze_xcode_inclusion(file_path)
            
            # Calculate confidence score
            total_references = sum(len(refs) for refs in usage.values())
            
            if total_references == 0 and not in_build:
                confidence = "High"
            elif total_references <= 2 and not in_build:
                confidence = "Medium"
            elif total_references <= 5 or in_build:
                confidence = "Low"
            else:
                confidence = "Very Low"
            
            verification_results[file_path] = {
                'confidence': confidence,
                'in_build_phase': in_build,
                'total_references': total_references,
                'usage_patterns': usage,
                'recommendation': self._get_recommendation(confidence, in_build, total_references)
            }
        
        return verification_results
    
    def _get_recommendation(self, confidence: str, in_build: bool, references: int) -> str:
        """Get recommendation based on analysis"""
        if confidence == "High":
            return "SAFE TO DELETE - No references found"
        elif confidence == "Medium":
            return "PROBABLY SAFE - Few references, manual review recommended"
        elif confidence == "Low":
            return "CAUTION - Multiple references or included in build"
        else:
            return "DO NOT DELETE - Likely in use"
    
    def generate_verification_report(self, verification_results: Dict) -> str:
        """Generate a detailed verification report"""
        report = []
        report.append("# Dead File Verification Report")
        report.append("")
        
        # Group by confidence level
        by_confidence = {}
        for file_path, data in verification_results.items():
            confidence = data['confidence']
            if confidence not in by_confidence:
                by_confidence[confidence] = []
            by_confidence[confidence].append((file_path, data))
        
        # High confidence (safe to delete)
        if "High" in by_confidence:
            report.append("## 🟢 High Confidence - Safe to Delete")
            report.append("*Files with no detected references:*")
            report.append("")
            for file_path, data in by_confidence["High"]:
                report.append(f"- `{file_path}` - {data['recommendation']}")
            report.append("")
        
        # Medium confidence
        if "Medium" in by_confidence:
            report.append("## 🟡 Medium Confidence - Review Recommended")
            report.append("*Files with minimal references:*")
            report.append("")
            for file_path, data in by_confidence["Medium"]:
                report.append(f"- `{file_path}` - {data['total_references']} references - {data['recommendation']}")
            report.append("")
        
        # Low confidence
        if "Low" in by_confidence:
            report.append("## 🟠 Low Confidence - Caution Advised")
            report.append("*Files that may be in use:*")
            report.append("")
            for file_path, data in by_confidence["Low"]:
                status = "In build" if data['in_build_phase'] else "Not in build"
                report.append(f"- `{file_path}` - {data['total_references']} references ({status}) - {data['recommendation']}")
            report.append("")
        
        # Very low confidence
        if "Very Low" in by_confidence:
            report.append("## 🔴 Very Low Confidence - Do Not Delete")
            report.append("*Files that are likely in use:*")
            report.append("")
            for file_path, data in by_confidence["Very Low"]:
                report.append(f"- `{file_path}` - {data['total_references']} references - {data['recommendation']}")
            report.append("")
        
        return "\n".join(report)

def main():
    project_root = "/home/runner/work/ThriveUp/ThriveUp"
    
    # Read the previously detected dead files
    report_path = os.path.join(project_root, "dead_files_report.md")
    if not os.path.exists(report_path):
        print("❌ Please run dead_file_detector.py first to generate the initial report")
        return
    
    # Extract dead Swift files from the report
    dead_swift_files = []
    with open(report_path, 'r') as f:
        content = f.read()
        
    # Parse dead Swift files from the report
    in_swift_section = False
    for line in content.split('\n'):
        if "🔴 Potentially Dead Swift Files" in line:
            in_swift_section = True
            continue
        elif line.startswith("##") and in_swift_section:
            break
        elif in_swift_section and line.startswith("- `") and line.endswith(".swift`"):
            file_path = line.replace("- `", "").replace("`", "")
            dead_swift_files.append(file_path)
    
    if not dead_swift_files:
        print("No dead Swift files found in the report to verify")
        return
    
    # Verify the files
    verifier = DeadFileVerifier(project_root)
    results = verifier.verify_dead_files(dead_swift_files)
    
    # Generate verification report
    verification_report = verifier.generate_verification_report(results)
    
    # Save verification report
    verification_path = os.path.join(project_root, "dead_files_verification.md")
    with open(verification_path, 'w') as f:
        f.write(verification_report)
    
    print(f"\n📄 Verification report saved to: {verification_path}")
    print("\n" + verification_report)

if __name__ == "__main__":
    main()