#!/bin/bash

# QLessCommute Setup Verification Script
echo "🚀 QLessCommute Setup Verification"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        if [ "$1" = "node" ]; then
            echo -e "   Version: $(node --version)"
        elif [ "$1" = "flutter" ]; then
            echo -e "   Version: $(flutter --version | head -n 1)"
        elif [ "$1" = "mysql" ]; then
            echo -e "   Version: $(mysql --version 2>/dev/null || echo "MySQL server may not be running")"
        fi
        return 0
    else
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    fi
}

# Function to check if VS Code is installed
check_vscode() {
    if command -v code &> /dev/null; then
        echo -e "${GREEN}✅ VS Code is installed${NC}"
        echo -e "   Version: $(code --version | head -n 1)"
        return 0
    else
        echo -e "${RED}❌ VS Code is not installed or not in PATH${NC}"
        return 1
    fi
}

# Check prerequisites
echo "📋 Checking Prerequisites:"
echo "-------------------------"

check_command "node"
NODE_OK=$?

check_command "npm"
NPM_OK=$?

check_command "flutter"
FLUTTER_OK=$?

check_command "mysql"
MYSQL_OK=$?

check_vscode
VSCODE_OK=$?

check_command "git"
GIT_OK=$?

echo ""

# Check project structure
echo "📁 Checking Project Structure:"
echo "------------------------------"

if [ -d "backend" ]; then
    echo -e "${GREEN}✅ Backend folder exists${NC}"
    BACKEND_OK=0
else
    echo -e "${RED}❌ Backend folder missing${NC}"
    BACKEND_OK=1
fi

if [ -d "frontend" ]; then
    echo -e "${GREEN}✅ Frontend folder exists${NC}"
    FRONTEND_OK=0
else
    echo -e "${RED}❌ Frontend folder missing${NC}"
    FRONTEND_OK=1
fi

if [ -f "backend/package.json" ]; then
    echo -e "${GREEN}✅ Backend package.json exists${NC}"
else
    echo -e "${RED}❌ Backend package.json missing${NC}"
fi

if [ -f "frontend/pubspec.yaml" ]; then
    echo -e "${GREEN}✅ Frontend pubspec.yaml exists${NC}"
else
    echo -e "${RED}❌ Frontend pubspec.yaml missing${NC}"
fi

if [ -f "backend/.env.example" ] || [ -f "backend/.env" ]; then
    echo -e "${GREEN}✅ Environment configuration found${NC}"
else
    echo -e "${YELLOW}⚠️  Environment file not found (create backend/.env)${NC}"
fi

echo ""

# Check VS Code configuration
echo "⚙️  Checking VS Code Configuration:"
echo "-----------------------------------"

if [ -d ".vscode" ]; then
    echo -e "${GREEN}✅ .vscode folder exists${NC}"
    
    if [ -f ".vscode/settings.json" ]; then
        echo -e "${GREEN}✅ VS Code settings configured${NC}"
    fi
    
    if [ -f ".vscode/tasks.json" ]; then
        echo -e "${GREEN}✅ VS Code tasks configured${NC}"
    fi
    
    if [ -f ".vscode/launch.json" ]; then
        echo -e "${GREEN}✅ VS Code launch configurations ready${NC}"
    fi
else
    echo -e "${RED}❌ .vscode folder missing${NC}"
fi

if [ -f "qlesscommute.code-workspace" ]; then
    echo -e "${GREEN}✅ VS Code workspace file exists${NC}"
else
    echo -e "${YELLOW}⚠️  VS Code workspace file missing${NC}"
fi

echo ""

# Flutter doctor check
if [ $FLUTTER_OK -eq 0 ]; then
    echo "🔍 Running Flutter Doctor:"
    echo "--------------------------"
    flutter doctor
    echo ""
fi

# Summary
echo "📊 Setup Summary:"
echo "=================="

TOTAL_ERRORS=0

if [ $NODE_OK -ne 0 ]; then
    echo -e "${RED}❌ Install Node.js from https://nodejs.org/${NC}"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
fi

if [ $FLUTTER_OK -ne 0 ]; then
    echo -e "${RED}❌ Install Flutter from https://docs.flutter.dev/get-started/install${NC}"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
fi

if [ $MYSQL_OK -ne 0 ]; then
    echo -e "${RED}❌ Install MySQL from https://dev.mysql.com/downloads/${NC}"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
fi

if [ $VSCODE_OK -ne 0 ]; then
    echo -e "${RED}❌ Install VS Code from https://code.visualstudio.com/${NC}"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
fi

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All prerequisites are installed!${NC}"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Open VS Code: code ."
    echo "2. Install recommended extensions"
    echo "3. Configure backend/.env file"
    echo "4. Run: Ctrl+Shift+P > 'Tasks: Run Task' > 'Setup Project'"
    echo "5. Start development: F5 or 'Launch Full Stack'"
else
    echo -e "${RED}⚠️  Please install missing prerequisites before proceeding${NC}"
fi

echo ""
echo "📖 For detailed setup instructions, see: VSCODE_SETUP.md"
echo "🆘 Need help? Check troubleshooting section in the setup guide"