#!/bin/bash

# QLessCommute Setup Script
# This script helps set up the complete QLessCommute application

echo "🚌 QLessCommute Setup Script"
echo "=============================="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter 3.0+ and try again."
    exit 1
fi

# Check if MySQL is installed
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL is not installed. Please install MySQL 8.0+ and try again."
    exit 1
fi

echo "✅ Prerequisites check passed!"
echo ""

# Setup Backend
echo "🔧 Setting up Backend..."
cd backend

# Install dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << EOL
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=qlesscommute

# JWT Secret
JWT_SECRET=qlesscommute_super_secret_jwt_key_change_this_in_production

# Server Configuration
PORT=3000
NODE_ENV=development

# M-Pesa Configuration (Daraja API)
MPESA_CONSUMER_KEY=your_mpesa_consumer_key
MPESA_CONSUMER_SECRET=your_mpesa_consumer_secret
MPESA_BUSINESS_SHORT_CODE=your_business_short_code
MPESA_PASSKEY=your_mpesa_passkey
MPESA_CALLBACK_URL=http://localhost:3000/api/payment-callback

# Application Settings
APP_NAME=QLessCommute
BASE_URL=http://localhost:3000
EOL
    echo "✅ .env file created! Please update it with your configurations."
else
    echo "✅ .env file already exists."
fi

echo ""
echo "🗄️ Setting up Database..."

# Prompt for MySQL credentials
read -p "Enter MySQL root password: " -s mysql_password
echo ""

# Create database
echo "📊 Creating database..."
mysql -u root -p${mysql_password} -e "CREATE DATABASE IF NOT EXISTS qlesscommute;"

if [ $? -eq 0 ]; then
    echo "✅ Database created successfully!"
else
    echo "❌ Failed to create database. Please check your MySQL credentials."
    exit 1
fi

# Update .env with actual password
sed -i "s/your_mysql_password/${mysql_password}/g" .env

echo ""
echo "🚀 Starting Backend Server..."
npm start &
BACKEND_PID=$!

echo "✅ Backend server started (PID: $BACKEND_PID)"
echo ""

# Setup Frontend
echo "🎨 Setting up Frontend..."
cd ../frontend

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Flutter dependencies installed successfully!"
else
    echo "❌ Failed to install Flutter dependencies."
    kill $BACKEND_PID
    exit 1
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Update the .env file with your M-Pesa credentials"
echo "2. Run 'npm start' in the backend directory to start the server"
echo "3. Run 'flutter run' in the frontend directory to start the app"
echo ""
echo "📖 Documentation: See docs/README.md for detailed setup instructions"
echo ""
echo "🌐 Backend API: http://localhost:3000"
echo "📚 API Docs: http://localhost:3000/api"
echo "❤️ Health Check: http://localhost:3000/health"
echo ""
echo "Happy coding! 🚌✨"