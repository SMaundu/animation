# Running QLessCommute in VS Code

## 🔧 Prerequisites

### 1. Install Required Software
- **VS Code** - [Download here](https://code.visualstudio.com/)
- **Node.js** (v16+) - [Download here](https://nodejs.org/)
- **Flutter SDK** - [Install guide](https://docs.flutter.dev/get-started/install)
- **MySQL** (v8.0+) - [Download here](https://dev.mysql.com/downloads/)
- **Git** - [Download here](https://git-scm.com/)

### 2. Install VS Code Extensions
Open VS Code and install these extensions:

1. **Flutter** (`Dart-Code.flutter`)
2. **Dart** (`Dart-Code.dart-code`)
3. **Thunder Client** (`rangav.vscode-thunder-client`) - For API testing
4. **MySQL** (`cweijan.vscode-mysql-client2`) - Database management
5. **ES7+ React/Redux/React-Native snippets** (`dsznajder.es7-react-js-snippets`)
6. **Prettier** (`esbenp.prettier-vscode`) - Code formatting
7. **Error Lens** (`usernamehw.errorlens`) - Inline error display

## 📁 Project Setup

### Step 1: Open Project in VS Code
```bash
# Navigate to your project directory
cd path/to/qlesscommute

# Open in VS Code
code .
```

### Step 2: VS Code Workspace Configuration
Create `.vscode/settings.json` in the project root:

```json
{
  "flutter.sdkPath": "path/to/flutter/sdk",
  "dart.flutterSdkPath": "path/to/flutter/sdk",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "files.associations": {
    "*.dart": "dart"
  },
  "emmet.includeLanguages": {
    "dart": "html"
  }
}
```

### Step 3: Create VS Code Tasks
Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start Backend",
      "type": "shell",
      "command": "npm",
      "args": ["run", "dev"],
      "options": {
        "cwd": "${workspaceFolder}/backend"
      },
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "new"
      }
    },
    {
      "label": "Start Flutter",
      "type": "shell",
      "command": "flutter",
      "args": ["run"],
      "options": {
        "cwd": "${workspaceFolder}/frontend"
      },
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "new"
      }
    },
    {
      "label": "Install Backend Dependencies",
      "type": "shell",
      "command": "npm",
      "args": ["install"],
      "options": {
        "cwd": "${workspaceFolder}/backend"
      },
      "group": "build"
    },
    {
      "label": "Install Flutter Dependencies",
      "type": "shell",
      "command": "flutter",
      "args": ["pub", "get"],
      "options": {
        "cwd": "${workspaceFolder}/frontend"
      },
      "group": "build"
    }
  ]
}
```

### Step 4: Create Launch Configurations
Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Debug)",
      "request": "launch",
      "type": "dart",
      "cwd": "${workspaceFolder}/frontend",
      "program": "lib/main.dart"
    },
    {
      "name": "Flutter (Release)",
      "request": "launch",
      "type": "dart",
      "cwd": "${workspaceFolder}/frontend",
      "program": "lib/main.dart",
      "flutterMode": "release"
    },
    {
      "name": "Backend (Node.js)",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/backend/server.js",
      "cwd": "${workspaceFolder}/backend",
      "env": {
        "NODE_ENV": "development"
      },
      "console": "integratedTerminal",
      "restart": true,
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"]
    }
  ],
  "compounds": [
    {
      "name": "Launch Full Stack",
      "configurations": [
        "Backend (Node.js)",
        "Flutter (Debug)"
      ]
    }
  ]
}
```

## 🗄️ Database Setup

### Step 1: Create MySQL Database
```sql
CREATE DATABASE qlesscommute;
CREATE USER 'qlesscommute_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON qlesscommute.* TO 'qlesscommute_user'@'localhost';
FLUSH PRIVILEGES;
```

### Step 2: Configure Environment
Create `backend/.env` file:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=qlesscommute
DB_USER=qlesscommute_user
DB_PASSWORD=your_password

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here-make-it-long-and-random
JWT_EXPIRES_IN=7d

# M-Pesa Configuration (Get from Safaricom Daraja)
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_BUSINESS_SHORT_CODE=174379
MPESA_PASSKEY=your_passkey
MPESA_ENVIRONMENT=sandbox

# Server Configuration
PORT=3000
NODE_ENV=development

# API Base URL
API_BASE_URL=http://localhost:3000/api
```

## 🚀 Running the Project

### Method 1: Using VS Code Tasks (Recommended)

1. **Open Command Palette** (`Ctrl+Shift+P` / `Cmd+Shift+P`)
2. **Run Task** > Select task:
   - `Install Backend Dependencies`
   - `Install Flutter Dependencies`
   - `Start Backend`
   - `Start Flutter`

### Method 2: Using Integrated Terminal

Open terminal in VS Code (`Ctrl+`` ` or `View > Terminal`)

**Backend Terminal:**
```bash
cd backend
npm install
npm run dev
```

**Frontend Terminal (New Terminal):**
```bash
cd frontend
flutter pub get
flutter run
```

### Method 3: Using Debug Configuration

1. **Go to Run and Debug** (`Ctrl+Shift+D`)
2. **Select "Launch Full Stack"** from dropdown
3. **Press F5** to start debugging

## 📱 Flutter Device Setup

### For Android Development:
1. **Enable Developer Options** on your Android device
2. **Enable USB Debugging**
3. **Connect via USB** or use emulator
4. **Check device** with: `flutter devices`

### For iOS Development (Mac only):
1. **Install Xcode** from App Store
2. **Setup iOS Simulator** or connect iPhone
3. **Check device** with: `flutter devices`

### For Web Development:
```bash
flutter config --enable-web
```

## 🔧 VS Code Shortcuts for QLessCommute

### Flutter Shortcuts:
- **Hot Reload**: `Ctrl+F5` / `Cmd+F5`
- **Hot Restart**: `Ctrl+Shift+F5` / `Cmd+Shift+F5`
- **Flutter Doctor**: `Ctrl+Shift+P` > "Flutter: Run Flutter Doctor"
- **Flutter Clean**: `Ctrl+Shift+P` > "Flutter: Clean"

### General Shortcuts:
- **Quick Open**: `Ctrl+P` / `Cmd+P`
- **Command Palette**: `Ctrl+Shift+P` / `Cmd+Shift+P`
- **Integrated Terminal**: `Ctrl+`` ` / `Cmd+`` `
- **Split Terminal**: `Ctrl+Shift+5` / `Cmd+Shift+5`

## 🛠️ API Testing with Thunder Client

1. **Install Thunder Client** extension
2. **Open Thunder Client** tab
3. **Import collection** or create requests:

### Sample API Requests:

**Register User:**
```
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "phoneNumber": "254712345678",
  "password": "password123",
  "role": "passenger"
}
```

**Login:**
```
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "phoneNumber": "254712345678",
  "password": "password123"
}
```

## 🐛 Troubleshooting

### Common Issues:

**1. Flutter Doctor Issues:**
```bash
flutter doctor
flutter doctor --android-licenses  # Accept Android licenses
```

**2. Backend Port Already in Use:**
```bash
# Kill process on port 3000
npx kill-port 3000
# Or change PORT in .env file
```

**3. MySQL Connection Error:**
- Check MySQL service is running
- Verify credentials in .env file
- Ensure database exists

**4. Flutter Dependencies Issues:**
```bash
cd frontend
flutter clean
flutter pub get
```

**5. Node.js Dependencies Issues:**
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

### Environment Path Issues:

**Flutter not found:**
- Add Flutter SDK to PATH
- Restart VS Code
- Check with: `flutter --version`

**Node.js not found:**
- Install Node.js from official website
- Restart VS Code
- Check with: `node --version`

## 📊 VS Code Workspace Layout

### Recommended Layout:
1. **Explorer Panel** (left) - File navigation
2. **Editor** (center) - Code editing
3. **Terminal** (bottom) - Multiple terminals for backend/frontend
4. **Debug Console** (bottom) - When debugging
5. **Problems Panel** (bottom) - Error display

### Multi-Root Workspace:
Create `qlesscommute.code-workspace`:

```json
{
  "folders": [
    {
      "name": "Backend",
      "path": "./backend"
    },
    {
      "name": "Frontend",
      "path": "./frontend"
    }
  ],
  "settings": {
    "flutter.sdkPath": "path/to/flutter/sdk"
  }
}
```

## 🎯 Development Workflow

### Daily Development:
1. **Open VS Code** with QLessCommute project
2. **Start MySQL** service
3. **Run backend** (`npm run dev`)
4. **Run frontend** (`flutter run`)
5. **Use hot reload** for quick Flutter changes
6. **Test API** with Thunder Client

### Code Editing:
- **Backend files** in `backend/` folder
- **Frontend files** in `frontend/lib/` folder
- **Use VS Code IntelliSense** for autocomplete
- **Format on save** enabled for consistent code style

## 🚀 Ready to Code!

Your QLessCommute project is now ready for development in VS Code! You can:

- ✅ Edit backend APIs in Node.js
- ✅ Develop Flutter UI screens
- ✅ Debug both frontend and backend
- ✅ Test APIs with Thunder Client
- ✅ Manage database with MySQL extension
- ✅ Use version control with Git integration

Happy coding! 🎉