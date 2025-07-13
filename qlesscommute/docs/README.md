# QLessCommute - Public Transport Booking System

## 🚌 Overview

QLessCommute is a complete public transport booking system that allows passengers to book rides, pay via M-Pesa, and receive QR code tickets for validation. The system consists of a Flutter mobile app frontend and a Node.js backend with MySQL database.

## 🎯 Key Features

### 🎫 For Passengers
- **Ride Booking**: Select pickup and drop-off locations with fare estimation
- **M-Pesa Integration**: Secure payments via STK Push
- **QR Code Tickets**: Unique QR codes generated after successful payment
- **Real-time Tracking**: Live ride status updates
- **Ride History**: Complete transaction and ride history
- **User Profiles**: Manage personal information and preferences

### 👥 For Conductors
- **QR Code Scanning**: Validate passenger tickets
- **Ticket Management**: Mark tickets as used
- **Performance Analytics**: View daily scanning statistics
- **Revenue Tracking**: Monitor validated transactions

### 🎛️ For Administrators
- **System Dashboard**: Comprehensive analytics and insights
- **User Management**: Manage passengers and conductors
- **Financial Reports**: Revenue and transaction analytics
- **System Health**: Monitor application performance

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Node.js API   │    │   MySQL DB      │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   M-Pesa API    │
                       │   (Daraja)      │
                       └─────────────────┘
```

## 📋 Prerequisites

### Backend Requirements
- Node.js 18+ and npm
- MySQL 8.0+
- M-Pesa Developer Account (Daraja API credentials)

### Frontend Requirements
- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode (for mobile development)

## 🚀 Quick Start

### 1. Backend Setup

```bash
# Navigate to backend directory
cd qlesscommute/backend

# Install dependencies
npm install

# Configure environment variables
cp .env.example .env
# Edit .env with your configurations

# Start the server
npm start

# For development with auto-reload
npm run dev
```

### 2. Frontend Setup

```bash
# Navigate to frontend directory
cd qlesscommute/frontend

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

## ⚙️ Configuration

### Backend Environment Variables (.env)

```env
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=qlesscommute

# JWT Secret
JWT_SECRET=your_super_secret_jwt_key

# M-Pesa Configuration (Daraja API)
MPESA_CONSUMER_KEY=your_mpesa_consumer_key
MPESA_CONSUMER_SECRET=your_mpesa_consumer_secret
MPESA_BUSINESS_SHORT_CODE=your_business_short_code
MPESA_PASSKEY=your_mpesa_passkey
MPESA_CALLBACK_URL=http://localhost:3000/api/payment-callback

# Server Configuration
PORT=3000
NODE_ENV=development
```

### Frontend Configuration

Update `lib/services/api_service.dart` with your backend URL:

```dart
static const String baseUrl = 'http://your-backend-url:3000/api';
```

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('passenger', 'conductor', 'admin') DEFAULT 'passenger',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Rides Table
```sql
CREATE TABLE rides (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  origin VARCHAR(255) NOT NULL,
  destination VARCHAR(255) NOT NULL,
  origin_lat DECIMAL(10, 8),
  origin_lng DECIMAL(11, 8),
  destination_lat DECIMAL(10, 8),
  destination_lng DECIMAL(11, 8),
  distance DECIMAL(8, 2),
  amount DECIMAL(10, 2) NOT NULL,
  status ENUM('pending', 'confirmed', 'completed', 'cancelled') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  ride_id INT NOT NULL,
  mpesa_code VARCHAR(255),
  checkout_request_id VARCHAR(255),
  merchant_request_id VARCHAR(255),
  amount DECIMAL(10, 2) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (ride_id) REFERENCES rides(id)
);
```

### Travel Info Table (QR Codes)
```sql
CREATE TABLE travelinfo (
  id INT AUTO_INCREMENT PRIMARY KEY,
  transaction_id INT NOT NULL,
  qr_code_data TEXT NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  scanned_at TIMESTAMP NULL,
  scanned_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  FOREIGN KEY (scanned_by) REFERENCES users(id)
);
```

## 📡 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /api/register
Content-Type: application/json

{
  "name": "John Doe",
  "phone": "0712345678",
  "password": "securepassword",
  "role": "passenger"
}
```

#### Login User
```http
POST /api/login
Content-Type: application/json

{
  "phone": "0712345678",
  "password": "securepassword"
}
```

### Ride Management Endpoints

#### Estimate Fare
```http
POST /api/rides/estimate-fare
Authorization: Bearer <token>
Content-Type: application/json

{
  "originLat": -1.286389,
  "originLng": 36.817223,
  "destinationLat": -1.292066,
  "destinationLng": 36.821946,
  "origin": "Nairobi CBD",
  "destination": "Westlands"
}
```

#### Book Ride
```http
POST /api/rides/book-ride
Authorization: Bearer <token>
Content-Type: application/json

{
  "origin": "Nairobi CBD",
  "destination": "Westlands",
  "originLat": -1.286389,
  "originLng": 36.817223,
  "destinationLat": -1.292066,
  "destinationLng": 36.821946
}
```

### Payment Endpoints

#### Initiate M-Pesa Payment
```http
POST /api/payments/initiate-payment
Authorization: Bearer <token>
Content-Type: application/json

{
  "rideId": 1,
  "phoneNumber": "254712345678"
}
```

#### Check Payment Status
```http
GET /api/payments/payment-status/1
Authorization: Bearer <token>
```

### QR Code Endpoints

#### Generate QR Code
```http
GET /api/qr/generate-qr/1
Authorization: Bearer <token>
```

#### Scan QR Code (Conductor)
```http
POST /api/qr/scan-qr
Authorization: Bearer <token>
Content-Type: application/json

{
  "qrCodeData": "encrypted_qr_data_string"
}
```

## 🎨 Flutter App Structure

```
lib/
├── models/           # Data models (User, Ride, Transaction)
├── screens/          # UI screens
├── services/         # API and business logic services
├── widgets/          # Reusable UI components
├── utils/           # Utilities (theme, routes, helpers)
└── main.dart        # App entry point
```

### Key Flutter Screens

1. **SplashScreen**: App initialization and authentication check
2. **LoginScreen**: User authentication
3. **RegisterScreen**: New user registration
4. **HomeScreen**: Main dashboard with map and booking
5. **FareConfirmationScreen**: Review and confirm ride details
6. **QRCodeScreen**: Display QR ticket after payment
7. **TicketScanScreen**: QR code scanner for conductors
8. **ProfileScreen**: User profile management
9. **RideHistoryScreen**: Past rides and transactions
10. **AdminDashboardScreen**: Administrative controls and analytics

## 💳 M-Pesa Integration

The app uses Safaricom's Daraja API for M-Pesa integration:

1. **STK Push**: Initiated from the app for payment
2. **Callback Handling**: Server receives payment confirmations
3. **Status Checking**: Real-time payment status updates
4. **Transaction Logging**: All M-Pesa transactions are recorded

### M-Pesa Flow
1. User selects ride and confirms fare
2. App initiates STK Push to user's phone
3. User enters M-Pesa PIN on their phone
4. M-Pesa sends callback to server
5. Server updates payment status
6. QR code is generated for successful payments

## 🔐 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt for password security
- **Role-based Access**: Different permissions for passengers, conductors, and admins
- **Input Validation**: Comprehensive input sanitization
- **QR Code Encryption**: Secure QR code generation with unique identifiers
- **One-time Use**: QR codes can only be scanned once

## 📱 Mobile App Features

### Material Design 3
- Modern UI with light and dark themes
- Smooth animations and transitions
- Responsive design for different screen sizes

### State Management
- Provider for efficient state management
- Real-time updates for payment and ride status
- Offline capability with local storage

### Location Services
- GPS integration for accurate pickup locations
- Google Maps integration for route visualization
- Geofencing for location-based features

## 🚀 Deployment

### Backend Deployment
1. Set up production MySQL database
2. Configure production environment variables
3. Deploy to cloud platform (AWS, Google Cloud, etc.)
4. Set up SSL certificates for HTTPS
5. Configure M-Pesa production credentials

### Frontend Deployment
1. Build production APK/IPA
2. Update API endpoints to production URLs
3. Submit to Google Play Store / Apple App Store
4. Configure app signing and security

## 🧪 Testing

### Backend Testing
```bash
# Run API tests
npm test

# Test M-Pesa integration (sandbox)
npm run test:mpesa
```

### Frontend Testing
```bash
# Run Flutter tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📊 Analytics & Monitoring

The admin dashboard provides:
- Real-time transaction monitoring
- Revenue analytics
- User engagement metrics
- System performance monitoring
- Route popularity analysis

## 🛠️ Troubleshooting

### Common Issues

1. **M-Pesa Sandbox Issues**
   - Verify credentials in M-Pesa Developer Portal
   - Check callback URL configuration
   - Ensure proper phone number formatting

2. **Database Connection**
   - Verify MySQL service is running
   - Check database credentials
   - Ensure database exists and tables are created

3. **Flutter Build Issues**
   - Run `flutter clean && flutter pub get`
   - Check dependency versions
   - Verify Android/iOS setup

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Email: support@qlesscommute.com
- Documentation: [https://docs.qlesscommute.com](https://docs.qlesscommute.com)
- Issues: Create an issue in the GitHub repository

## 🔄 Version History

- **v1.0.0**: Initial release with core features
  - User authentication
  - Ride booking
  - M-Pesa payments
  - QR code tickets
  - Admin dashboard

---

**QLessCommute** - Making public transport smarter, one ride at a time! 🚌✨