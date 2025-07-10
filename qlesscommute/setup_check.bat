@echo off
REM QLessCommute Setup Verification Script for Windows
echo 🚀 QLessCommute Setup Verification
echo ==================================
echo.

REM Function to check if command exists
:check_command
where %1 >nul 2>nul
if %errorlevel% == 0 (
    echo ✅ %1 is installed
    if "%1"=="node" (
        for /f "tokens=*" %%i in ('node --version') do echo    Version: %%i
    )
    if "%1"=="flutter" (
        for /f "tokens=*" %%i in ('flutter --version ^| findstr /r "^Flutter"') do echo    Version: %%i
    )
    if "%1"=="mysql" (
        for /f "tokens=*" %%i in ('mysql --version 2^>nul') do echo    Version: %%i
    )
    exit /b 0
) else (
    echo ❌ %1 is not installed
    exit /b 1
)

:check_vscode
where code >nul 2>nul
if %errorlevel% == 0 (
    echo ✅ VS Code is installed
    for /f "tokens=*" %%i in ('code --version ^| findstr /n "." ^| findstr "^1:"') do (
        for /f "tokens=2 delims=:" %%j in ("%%i") do echo    Version: %%j
    )
    exit /b 0
) else (
    echo ❌ VS Code is not installed or not in PATH
    exit /b 1
)

REM Check prerequisites
echo 📋 Checking Prerequisites:
echo -------------------------

call :check_command node
set NODE_OK=%errorlevel%

call :check_command npm
set NPM_OK=%errorlevel%

call :check_command flutter
set FLUTTER_OK=%errorlevel%

call :check_command mysql
set MYSQL_OK=%errorlevel%

call :check_vscode
set VSCODE_OK=%errorlevel%

call :check_command git
set GIT_OK=%errorlevel%

echo.

REM Check project structure
echo 📁 Checking Project Structure:
echo ------------------------------

if exist "backend" (
    echo ✅ Backend folder exists
    set BACKEND_OK=0
) else (
    echo ❌ Backend folder missing
    set BACKEND_OK=1
)

if exist "frontend" (
    echo ✅ Frontend folder exists
    set FRONTEND_OK=0
) else (
    echo ❌ Frontend folder missing
    set FRONTEND_OK=1
)

if exist "backend\package.json" (
    echo ✅ Backend package.json exists
) else (
    echo ❌ Backend package.json missing
)

if exist "frontend\pubspec.yaml" (
    echo ✅ Frontend pubspec.yaml exists
) else (
    echo ❌ Frontend pubspec.yaml missing
)

if exist "backend\.env.example" (
    echo ✅ Environment configuration found
) else if exist "backend\.env" (
    echo ✅ Environment configuration found
) else (
    echo ⚠️  Environment file not found (create backend\.env)
)

echo.

REM Check VS Code configuration
echo ⚙️  Checking VS Code Configuration:
echo -----------------------------------

if exist ".vscode" (
    echo ✅ .vscode folder exists
    
    if exist ".vscode\settings.json" (
        echo ✅ VS Code settings configured
    )
    
    if exist ".vscode\tasks.json" (
        echo ✅ VS Code tasks configured
    )
    
    if exist ".vscode\launch.json" (
        echo ✅ VS Code launch configurations ready
    )
) else (
    echo ❌ .vscode folder missing
)

if exist "qlesscommute.code-workspace" (
    echo ✅ VS Code workspace file exists
) else (
    echo ⚠️  VS Code workspace file missing
)

echo.

REM Flutter doctor check
if %FLUTTER_OK% == 0 (
    echo 🔍 Running Flutter Doctor:
    echo --------------------------
    flutter doctor
    echo.
)

REM Summary
echo 📊 Setup Summary:
echo ==================

set TOTAL_ERRORS=0

if %NODE_OK% neq 0 (
    echo ❌ Install Node.js from https://nodejs.org/
    set /a TOTAL_ERRORS+=1
)

if %FLUTTER_OK% neq 0 (
    echo ❌ Install Flutter from https://docs.flutter.dev/get-started/install
    set /a TOTAL_ERRORS+=1
)

if %MYSQL_OK% neq 0 (
    echo ❌ Install MySQL from https://dev.mysql.com/downloads/
    set /a TOTAL_ERRORS+=1
)

if %VSCODE_OK% neq 0 (
    echo ❌ Install VS Code from https://code.visualstudio.com/
    set /a TOTAL_ERRORS+=1
)

if %TOTAL_ERRORS% == 0 (
    echo 🎉 All prerequisites are installed!
    echo.
    echo 📋 Next Steps:
    echo 1. Open VS Code: code .
    echo 2. Install recommended extensions
    echo 3. Configure backend\.env file
    echo 4. Run: Ctrl+Shift+P ^> 'Tasks: Run Task' ^> 'Setup Project'
    echo 5. Start development: F5 or 'Launch Full Stack'
) else (
    echo ⚠️  Please install missing prerequisites before proceeding
)

echo.
echo 📖 For detailed setup instructions, see: VSCODE_SETUP.md
echo 🆘 Need help? Check troubleshooting section in the setup guide

pause