# QLessCommute - Public Transport Booking App

A complete full-stack mobile application for public transport booking with M-Pesa integration, QR code ticketing, and real-time conductor validation.

## 🛠️ Tech Stack

**Frontend**: Flutter (Dart)
- Material Design 3
- Google Maps integration
- QR code generation/scanning
- State management with Provider
- Responsive UI with animations

**Backend**: Node.js with Express
- RESTful API architecture
- MySQL database with connection pooling
- M-Pesa Daraja API integration
- JWT authentication
- QR code generation and validation

## 🚀 Quick Start with VS Code

### Prerequisites Check
Run the setup verification script to check if you have all prerequisites installed:

**Linux/Mac:**
```bash
./setup_check.sh
```

**Windows:**
```batch
setup_check.bat
```

### Option 1: Open Workspace File (Recommended)
```bash
# Navigate to project directory
cd path/to/qlesscommute

# Open the workspace in VS Code
code qlesscommute.code-workspace
```

### Option 2: Open Project Folder
```bash
# Navigate to project directory
cd path/to/qlesscommute

# Open in VS Code
code .
```

### Install VS Code Extensions
The workspace will recommend these extensions:
- Flutter (`Dart-Code.flutter`)
- Dart (`Dart-Code.dart-code`)
- Thunder Client (`rangav.vscode-thunder-client`)
- MySQL (`cweijan.vscode-mysql-client2`)
- Prettier (`esbenp.prettier-vscode`)
- Error Lens (`usernamehw.errorlens`)

### Setup and Run
1. **Install Dependencies** - Use Command Palette (`Ctrl+Shift+P`):
   - `Tasks: Run Task` → `Setup Project`

2. **Configure Environment**:
   - Copy `backend/.env.example` to `backend/.env`
   - Update database and M-Pesa credentials

3. **Start Development**:
   - Press `F5` or use `Run and Debug` → `Launch Full Stack (Debug)`
   - Or use `Tasks: Run Task` → `Start Full Stack`

### Manual Setup (Alternative)

**Backend Terminal:**
```bash
cd backend
npm install
npm run dev
```

**Frontend Terminal:**
```bash
cd frontend
flutter pub get
flutter run
```

## 📖 Detailed Documentation

For comprehensive setup instructions, troubleshooting, and development workflow:

👉 **[VS Code Setup Guide](VSCODE_SETUP.md)** - Complete setup instructions

## 🔧 Development Features

### VS Code Integration
- **Debugging**: Full-stack debugging with breakpoints
- **Hot Reload**: Flutter hot reload on save
- **IntelliSense**: Auto-completion for both Dart and JavaScript
- **Tasks**: Pre-configured build and run tasks
- **Extensions**: Recommended extensions for optimal development

### API Testing
- **Thunder Client**: Built-in API testing tool
- **Pre-configured requests**: Sample API calls included
- **Real-time testing**: Test M-Pesa integration and QR validation

### Database Management
- **MySQL Extension**: Visual database management
- **Auto-initialization**: Database tables created automatically
- **Connection pooling**: Optimized database connections

## 🎯 Key Features

### For Passengers
- 📱 User registration and authentication
- 🗺️ Google Maps route selection
- 💰 M-Pesa STK Push payments
- 📋 QR code ticket generation
- 📊 Ride history and analytics

### For Conductors
- 📷 QR code scanning and validation
- ✅ Real-time ticket verification
- 📈 Daily ride statistics

### For Admins
- 📊 Comprehensive dashboard
- 💼 User and ride management
- 📈 Revenue analytics

## 🏗️ Project Structure

```
qlesscommute/
├── .vscode/                 # VS Code configuration
│   ├── settings.json        # Workspace settings
│   ├── tasks.json          # Build and run tasks
│   └── launch.json         # Debug configurations
├── backend/                 # Node.js API server
│   ├── routes/             # API endpoints
│   ├── middleware/         # Authentication & validation
│   ├── config/             # Database & M-Pesa config
│   └── server.js           # Main server file
├── frontend/               # Flutter mobile app
│   ├── lib/
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API & business logic
│   │   ├── models/         # Data models
│   │   └── main.dart       # App entry point
│   └── pubspec.yaml        # Flutter dependencies
├── VSCODE_SETUP.md         # Detailed setup guide
├── setup_check.sh          # Setup verification (Linux/Mac)
├── setup_check.bat         # Setup verification (Windows)
└── qlesscommute.code-workspace # VS Code workspace
```

## 🗄️ Database Schema

### Core Tables
- **users**: User accounts with role-based access
- **rides**: Trip bookings with route information
- **transactions**: M-Pesa payment records
- **travelinfo**: Travel route configurations

## 🔗 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login

### Ride Management
- `POST /api/rides/book` - Book a ride
- `GET /api/rides/user/:userId` - User ride history
- `POST /api/rides/estimate-fare` - Get fare estimate

### Payment Integration
- `POST /api/payment/initiate` - Start M-Pesa payment
- `POST /api/payment/callback` - M-Pesa callback handler
- `GET /api/payment/status/:transactionId` - Payment status

### QR Code System
- `GET /api/qr/generate/:transactionId` - Generate QR ticket
- `POST /api/qr/scan` - Validate QR code

## 🔐 Environment Configuration

Create `backend/.env` with:

```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=qlesscommute
DB_USER=your_db_user
DB_PASSWORD=your_db_password

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d

# M-Pesa (Safaricom Daraja API)
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_BUSINESS_SHORT_CODE=174379
MPESA_PASSKEY=your_passkey
MPESA_ENVIRONMENT=sandbox

# Server
PORT=3000
NODE_ENV=development
API_BASE_URL=http://localhost:3000/api
```

## 🚨 Troubleshooting

### Common Issues

**Flutter not found:**
- Install Flutter SDK
- Add Flutter to PATH
- Restart VS Code
- Run: `flutter doctor`

**Backend port already in use:**
```bash
npx kill-port 3000
```

**MySQL connection error:**
- Check MySQL service is running
- Verify credentials in `.env`
- Ensure database exists

**Dependencies issues:**
```bash
# Backend
cd backend && npm install

# Frontend  
cd frontend && flutter pub get
```

For more troubleshooting help, see [VSCODE_SETUP.md](VSCODE_SETUP.md)

## 🎉 Ready to Develop!

Your QLessCommute project is now configured for VS Code development. You can:

- ✅ Debug both frontend and backend simultaneously
- ✅ Use hot reload for rapid Flutter development
- ✅ Test APIs with integrated Thunder Client
- ✅ Manage MySQL database visually
- ✅ Access pre-configured tasks and launch configs

## 📞 Support

Need help? Check the detailed setup guide: [VSCODE_SETUP.md](VSCODE_SETUP.md)

Happy coding! 🚀