#!/bin/bash

# gdtoolkit wrapper script for negaboku project
# GDScript code quality management tools

# Set PATH to include pipx installed tools
export PATH="$PATH:$HOME/.local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GDSCRIPT_DIR="$PROJECT_ROOT/GodotProject/Scripts"

echo -e "${GREEN}negaboku GDScript Quality Tools${NC}"
echo "================================"

# Function to lint all GDScript files
lint_all() {
    echo -e "${YELLOW}Running GDScript Linter...${NC}"
    local lint_output
    lint_output=$(find "$GDSCRIPT_DIR" -name "*.gd" -exec gdlint {} + 2>&1)
    local lint_result=$?
    
    if [ $lint_result -eq 0 ]; then
        echo -e "${GREEN}✅ Linting completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Linting found issues:${NC}"
        echo "$lint_output"
        return 1
    fi
}

# Function to format all GDScript files
format_all() {
    echo -e "${YELLOW}Running GDScript Formatter...${NC}"
    if find "$GDSCRIPT_DIR" -name "*.gd" -exec gdformat {} + 2>/dev/null; then
        echo -e "${GREEN}✅ Formatting completed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Formatting failed${NC}"
        return 1
    fi
}

# Function to check formatting (dry run)
check_format() {
    echo -e "${YELLOW}Checking GDScript formatting...${NC}"
    if find "$GDSCRIPT_DIR" -name "*.gd" -exec gdformat --check {} + 2>/dev/null; then
        echo -e "${GREEN}✅ All files are properly formatted${NC}"
        return 0
    else
        echo -e "${RED}❌ Some files need formatting${NC}"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  lint        Run GDScript linter on all .gd files"
    echo "  format      Format all GDScript files"
    echo "  check       Check if files are properly formatted (dry run)"
    echo "  all         Run linter and formatter"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 lint     # Check code quality"
    echo "  $0 format   # Format all GDScript files"
    echo "  $0 all      # Run both linter and formatter"
}

# Main command handling
case "${1:-help}" in
    lint)
        lint_all
        ;;
    format)
        format_all
        ;;
    check)
        check_format
        ;;
    all)
        echo "Running complete GDScript quality check..."
        lint_all
        lint_result=$?
        format_all
        format_result=$?
        
        if [ $lint_result -eq 0 ] && [ $format_result -eq 0 ]; then
            echo -e "${GREEN}🎉 All quality checks passed!${NC}"
            exit 0
        else
            echo -e "${RED}⚠️  Some quality checks failed${NC}"
            exit 1
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac