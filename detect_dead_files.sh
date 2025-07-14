#!/bin/bash
#
# ThriveUp Dead File Detection Tool
# 
# This script provides a simple command-line interface for detecting dead files
# in the ThriveUp iOS project.
#
# Usage: ./detect_dead_files.sh [options]
#

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$PROJECT_ROOT/dead_file_detector.py"
VERIFY_SCRIPT="$PROJECT_ROOT/verify_dead_files.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_help() {
    echo "ThriveUp Dead File Detection Tool"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -r, --report      Generate dead files report only"
    echo "  -v, --verify      Verify previously detected dead files"
    echo "  -a, --all         Run full analysis (detect + verify)"
    echo "  --clean           Clean up generated reports"
    echo ""
    echo "Examples:"
    echo "  $0                # Run full analysis (default)"
    echo "  $0 --report       # Generate report only"
    echo "  $0 --verify       # Verify existing results"
    echo ""
}

run_detection() {
    echo -e "${BLUE}🔍 Running dead file detection...${NC}"
    echo "=================================================="
    
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        echo -e "${RED}❌ Error: dead_file_detector.py not found${NC}"
        exit 1
    fi
    
    python3 "$PYTHON_SCRIPT"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Dead file detection completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Dead file detection failed${NC}"
        return 1
    fi
}

run_verification() {
    echo -e "${BLUE}🔧 Running verification analysis...${NC}"
    echo "=================================================="
    
    if [ ! -f "$VERIFY_SCRIPT" ]; then
        echo -e "${RED}❌ Error: verify_dead_files.py not found${NC}"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/dead_files_report.md" ]; then
        echo -e "${YELLOW}⚠️  No existing report found. Running detection first...${NC}"
        run_detection
    fi
    
    python3 "$VERIFY_SCRIPT"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Verification completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Verification failed${NC}"
        return 1
    fi
}

clean_reports() {
    echo -e "${BLUE}🧹 Cleaning up reports...${NC}"
    
    files_to_clean=(
        "$PROJECT_ROOT/dead_files_report.md"
        "$PROJECT_ROOT/dead_files_verification.md"
    )
    
    for file in "${files_to_clean[@]}"; do
        if [ -f "$file" ]; then
            rm "$file"
            echo "   Removed: $(basename "$file")"
        fi
    done
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

show_summary() {
    echo ""
    echo -e "${BLUE}📊 Analysis Summary${NC}"
    echo "=================================================="
    
    if [ -f "$PROJECT_ROOT/dead_files_report.md" ]; then
        echo -e "${GREEN}📄 Generated reports:${NC}"
        echo "   • dead_files_report.md - Main analysis report"
        
        if [ -f "$PROJECT_ROOT/dead_files_verification.md" ]; then
            echo "   • dead_files_verification.md - Verification report"
        fi
        
        echo ""
        echo -e "${YELLOW}📋 Quick Summary:${NC}"
        
        # Extract summary from report
        dead_swift=$(grep "Dead Swift files" "$PROJECT_ROOT/dead_files_report.md" | grep -o '[0-9]\+' | head -1)
        unused_assets=$(grep "Unused assets" "$PROJECT_ROOT/dead_files_report.md" | grep -o '[0-9]\+' | head -1)
        total_dead=$(grep "Total potentially dead files" "$PROJECT_ROOT/dead_files_report.md" | grep -o '[0-9]\+' | head -1)
        
        echo "   • Total potentially dead files: ${total_dead:-0}"
        echo "   • Dead Swift files: ${dead_swift:-0}"
        echo "   • Unused assets: ${unused_assets:-0}"
        
    else
        echo -e "${RED}❌ No reports found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}💡 Next Steps:${NC}"
    echo "   1. Review the generated reports carefully"
    echo "   2. Manually verify files before deletion"
    echo "   3. Test thoroughly after removing any files"
    echo "   4. Consider using version control before cleanup"
}

# Parse command line arguments
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -r|--report)
        run_detection
        show_summary
        ;;
    -v|--verify)
        run_verification
        show_summary
        ;;
    -a|--all|"")
        run_detection
        if [ $? -eq 0 ]; then
            run_verification
        fi
        show_summary
        ;;
    --clean)
        clean_reports
        ;;
    *)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac