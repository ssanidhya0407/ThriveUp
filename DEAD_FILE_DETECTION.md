# Dead File Detection for ThriveUp iOS Project

This directory contains tools to detect and analyze potentially dead (unused) files in the ThriveUp iOS project.

## 🛠️ Tools Included

### 1. `dead_file_detector.py`
The main Python script that performs comprehensive dead file analysis:
- Analyzes Swift files not included in Xcode project build
- Detects Swift files not imported/referenced by other files  
- Finds unused asset files in Assets.xcassets
- Identifies orphaned storyboard files

### 2. `verify_dead_files.py`
Verification script that provides additional analysis:
- Cross-references detected files with actual usage patterns
- Provides confidence levels for deletion safety
- Checks if files are included in Xcode build phases
- Generates detailed verification reports

### 3. `detect_dead_files.sh`
Command-line interface for easy usage:
- Provides simple commands for detection and verification
- Colorized output for better readability
- Summary reports and cleanup utilities

## 🚀 Quick Start

### Run Full Analysis
```bash
./detect_dead_files.sh
```

### Generate Report Only
```bash
./detect_dead_files.sh --report
```

### Verify Existing Results
```bash
./detect_dead_files.sh --verify
```

### Show Help
```bash
./detect_dead_files.sh --help
```

## 📊 Latest Analysis Results

### Summary
- **Total potentially dead files**: 73
- **Dead Swift files**: 21
- **Unused assets**: 52
- **Orphaned storyboards**: 0

### Key Findings

#### High-Risk Dead Files
Files that appear to be completely unused and safe for deletion:
- Several Hackathon-related view controllers (not in build)
- Unused protocol and adapter files

#### Medium-Risk Files  
Files with minimal references that need manual review:
- Some EventGroup related files
- UI components with few references

#### Asset Cleanup Opportunities
52 potentially unused assets including:
- Event/speaker profile images
- Event logos and branding assets
- Onboarding images

## ⚠️ Important Safety Notes

**Before deleting any files:**

1. **Manual Review Required**: All results are heuristic-based and may have false positives
2. **Check Interface Builder**: Some files may be referenced in storyboards/XIBs
3. **Dynamic Loading**: Files may be loaded using string-based names
4. **Version Control**: Always commit current state before cleanup
5. **Testing**: Run full test suite after any deletions

## 🔍 Analysis Methodology

### Swift File Detection
- Parses Xcode project file (`.pbxproj`) for included files
- Analyzes import statements and class references
- Uses heuristics to detect usage patterns
- Cross-references with build configurations

### Asset Analysis
- Scans Assets.xcassets directory structure
- Searches for UIImage(named:) and similar patterns
- Checks for string-based asset references
- Analyzes Interface Builder connections

### Verification Process
- Multiple confidence levels based on reference count
- Build phase inclusion analysis  
- Pattern matching for indirect usage
- Safe deletion recommendations

## 📋 Maintenance

### Regular Usage
Run the analysis monthly or before major releases:
```bash
./detect_dead_files.sh --all
```

### Integration with CI/CD
The tools can be integrated into build pipelines:
```bash
# In your CI script
python3 dead_file_detector.py
# Check exit code and parse results
```

### Customization
Edit the Python scripts to:
- Add new file type detection
- Modify confidence scoring
- Include additional analysis patterns
- Export results in different formats

## 🤝 Contributing

When adding new features:
1. Update detection patterns in `dead_file_detector.py`
2. Add verification logic in `verify_dead_files.py` 
3. Update CLI options in `detect_dead_files.sh`
4. Test with current codebase
5. Update this documentation

## 📝 Generated Reports

The tools generate two main reports:

- `dead_files_report.md` - Main analysis results
- `dead_files_verification.md` - Detailed verification with confidence levels

Both reports are automatically generated and saved in the project root directory.