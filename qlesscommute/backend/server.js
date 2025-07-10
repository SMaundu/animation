const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

// Import database configuration
const { initializeDatabase, testConnection } = require('./config/database');

// Import routes
const authRoutes = require('./routes/auth');
const rideRoutes = require('./routes/rides');
const paymentRoutes = require('./routes/payments');
const qrRoutes = require('./routes/qr');
const adminRoutes = require('./routes/admin');

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080', 'http://127.0.0.1:8080'],
  credentials: true,
  optionsSuccessStatus: 200
}));

app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'QLessCommute Backend API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API documentation endpoint
app.get('/api', (req, res) => {
  res.json({
    success: true,
    message: 'QLessCommute API v1.0.0',
    documentation: {
      authentication: {
        register: 'POST /api/register',
        login: 'POST /api/login',
        verify: 'GET /api/verify',
        changePassword: 'POST /api/change-password'
      },
      rides: {
        estimateFare: 'POST /api/rides/estimate-fare',
        bookRide: 'POST /api/rides/book-ride',
        getRide: 'GET /api/rides/:rideId',
        getUserRides: 'GET /api/rides/user-rides/:userId',
        cancelRide: 'PATCH /api/rides/:rideId/cancel'
      },
      payments: {
        initiatePayment: 'POST /api/payments/initiate-payment',
        paymentCallback: 'POST /api/payments/payment-callback',
        paymentStatus: 'GET /api/payments/payment-status/:transactionId',
        transactions: 'GET /api/payments/transactions',
        retryPayment: 'POST /api/payments/retry-payment/:transactionId'
      },
      qr: {
        generateQR: 'GET /api/qr/generate-qr/:transactionId',
        scanQR: 'POST /api/qr/scan-qr',
        qrDetails: 'GET /api/qr/qr-details/:transactionId',
        scannedHistory: 'GET /api/qr/scanned-history',
        ticketStats: 'GET /api/qr/ticket-stats',
        checkQRStatus: 'GET /api/qr/check-qr-status/:transactionId'
      },
      admin: {
        overview: 'GET /api/admin/overview',
        analytics: 'GET /api/admin/analytics',
        users: 'GET /api/admin/users',
        rides: 'GET /api/admin/rides',
        transactions: 'GET /api/admin/transactions',
        systemHealth: 'GET /api/admin/system-health'
      }
    },
    notes: {
      authentication: 'Most endpoints require Bearer token in Authorization header',
      roles: 'Users can be: passenger, conductor, or admin',
      mpesa: 'M-Pesa STK Push integration for payments',
      qr: 'QR codes are generated after successful payment and used for ticket validation'
    }
  });
});

// API Routes
app.use('/api', authRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/qr', qrRoutes);
app.use('/api/admin', adminRoutes);

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  
  res.status(error.status || 500).json({
    success: false,
    message: error.message || 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? error.stack : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    availableEndpoints: [
      'GET /health - Health check',
      'GET /api - API documentation',
      'POST /api/register - User registration',
      'POST /api/login - User login',
      'POST /api/rides/book-ride - Book a ride',
      'POST /api/payments/initiate-payment - Initiate M-Pesa payment',
      'GET /api/qr/generate-qr/:transactionId - Generate QR ticket',
      'POST /api/qr/scan-qr - Scan and validate QR ticket',
      'GET /api/admin/overview - Admin dashboard (admin only)'
    ]
  });
});

// Initialize and start server
const startServer = async () => {
  try {
    console.log('🚀 Starting QLessCommute Backend Server...');
    console.log('📦 Environment:', process.env.NODE_ENV || 'development');
    
    // Test database connection
    console.log('🔗 Testing database connection...');
    const dbConnected = await testConnection();
    
    if (!dbConnected) {
      console.error('❌ Failed to connect to database');
      process.exit(1);
    }
    
    // Initialize database tables
    console.log('🗃️  Initializing database tables...');
    await initializeDatabase();
    
    // Start the server
    app.listen(PORT, () => {
      console.log('✅ QLessCommute Backend Server is running!');
      console.log(`🌐 Server URL: http://localhost:${PORT}`);
      console.log(`📚 API Documentation: http://localhost:${PORT}/api`);
      console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
      console.log('');
      console.log('🎯 Available Services:');
      console.log('   • User Authentication (JWT)');
      console.log('   • Ride Booking & Management');
      console.log('   • M-Pesa STK Push Payments');
      console.log('   • QR Code Generation & Validation');
      console.log('   • Admin Dashboard & Analytics');
      console.log('');
      console.log('🔒 Security Features:');
      console.log('   • JWT Token Authentication');
      console.log('   • Role-based Access Control');
      console.log('   • Password Hashing (bcrypt)');
      console.log('   • Input Validation & Sanitization');
      console.log('');
      console.log('💳 Payment Integration:');
      console.log('   • M-Pesa Daraja API');
      console.log('   • STK Push Notifications');
      console.log('   • Payment Status Tracking');
      console.log('   • Transaction History');
      console.log('');
      console.log('🎫 Ticket System:');
      console.log('   • QR Code Generation');
      console.log('   • One-time Use Validation');
      console.log('   • Conductor Scanning Interface');
      console.log('   • Real-time Status Updates');
      console.log('');
      console.log('Ready to serve QLessCommute mobile app! 🚌📱');
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully...');
  process.exit(0);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Start the server
startServer();