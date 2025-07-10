const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const { pool } = require('../config/database');

class QRCodeService {
  // Generate unique QR code for a transaction
  async generateQRCode(transactionId) {
    try {
      // Check if transaction exists and is completed
      const [transactionRows] = await pool.execute(
        `SELECT t.*, r.origin, r.destination, u.name, u.phone 
         FROM transactions t 
         JOIN rides r ON t.ride_id = r.id 
         JOIN users u ON t.user_id = u.id 
         WHERE t.id = ? AND t.status = 'completed'`,
        [transactionId]
      );

      if (transactionRows.length === 0) {
        throw new Error('Transaction not found or not completed');
      }

      const transaction = transactionRows[0];

      // Check if QR code already exists for this transaction
      const [existingQR] = await pool.execute(
        'SELECT qr_code_data FROM travelinfo WHERE transaction_id = ?',
        [transactionId]
      );

      if (existingQR.length > 0) {
        return {
          success: true,
          qrCodeData: existingQR[0].qr_code_data,
          message: 'QR code already exists'
        };
      }

      // Generate unique QR code data
      const qrData = {
        id: uuidv4(),
        transactionId: transactionId,
        rideId: transaction.ride_id,
        userId: transaction.user_id,
        amount: transaction.amount,
        origin: transaction.origin,
        destination: transaction.destination,
        passengerName: transaction.name,
        passengerPhone: transaction.phone,
        mpesaCode: transaction.mpesa_code,
        timestamp: new Date().toISOString(),
        appName: 'QLessCommute'
      };

      const qrCodeDataString = JSON.stringify(qrData);

      // Generate QR code image as base64
      const qrCodeImage = await QRCode.toDataURL(qrCodeDataString, {
        errorCorrectionLevel: 'M',
        type: 'image/png',
        quality: 0.92,
        margin: 1,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        },
        width: 256
      });

      // Save QR code to database
      await pool.execute(
        `INSERT INTO travelinfo (transaction_id, qr_code_data) 
         VALUES (?, ?)`,
        [transactionId, qrCodeDataString]
      );

      return {
        success: true,
        qrCodeData: qrCodeDataString,
        qrCodeImage: qrCodeImage,
        rideDetails: {
          origin: transaction.origin,
          destination: transaction.destination,
          amount: transaction.amount,
          passengerName: transaction.name,
          mpesaCode: transaction.mpesa_code
        }
      };

    } catch (error) {
      console.error('QR Code generation error:', error);
      return {
        success: false,
        error: error.message || 'Failed to generate QR code'
      };
    }
  }

  // Validate and mark QR code as used
  async validateQRCode(qrCodeData, scannedBy) {
    try {
      // Parse QR code data
      let parsedData;
      try {
        parsedData = JSON.parse(qrCodeData);
      } catch (parseError) {
        return {
          success: false,
          error: 'Invalid QR code format'
        };
      }

      // Verify QR code belongs to QLessCommute
      if (parsedData.appName !== 'QLessCommute') {
        return {
          success: false,
          error: 'Invalid QR code - not from QLessCommute'
        };
      }

      // Check if QR code exists and is not used
      const [qrRows] = await pool.execute(
        `SELECT ti.*, t.amount, r.origin, r.destination, u.name, u.phone 
         FROM travelinfo ti 
         JOIN transactions t ON ti.transaction_id = t.id 
         JOIN rides r ON t.ride_id = r.id 
         JOIN users u ON t.user_id = u.id 
         WHERE ti.qr_code_data = ?`,
        [qrCodeData]
      );

      if (qrRows.length === 0) {
        return {
          success: false,
          error: 'QR code not found'
        };
      }

      const qrInfo = qrRows[0];

      // Check if already used
      if (qrInfo.used) {
        return {
          success: false,
          error: 'QR code has already been used',
          usedAt: qrInfo.scanned_at
        };
      }

      // Check if QR code is not too old (e.g., valid for 24 hours)
      const qrAge = (new Date() - new Date(qrInfo.created_at)) / (1000 * 60 * 60);
      if (qrAge > 24) {
        return {
          success: false,
          error: 'QR code has expired'
        };
      }

      // Mark QR code as used
      await pool.execute(
        `UPDATE travelinfo 
         SET used = TRUE, scanned_at = NOW(), scanned_by = ? 
         WHERE id = ?`,
        [scannedBy, qrInfo.id]
      );

      // Update ride status to completed
      await pool.execute(
        `UPDATE rides 
         SET status = 'completed' 
         WHERE id = (
           SELECT ride_id FROM transactions WHERE id = ?
         )`,
        [qrInfo.transaction_id]
      );

      return {
        success: true,
        message: 'QR code validated successfully',
        rideDetails: {
          transactionId: qrInfo.transaction_id,
          passengerName: qrInfo.name,
          passengerPhone: qrInfo.phone,
          origin: qrInfo.origin,
          destination: qrInfo.destination,
          amount: qrInfo.amount,
          validatedAt: new Date().toISOString()
        }
      };

    } catch (error) {
      console.error('QR Code validation error:', error);
      return {
        success: false,
        error: 'Failed to validate QR code'
      };
    }
  }

  // Get QR code details
  async getQRCodeDetails(transactionId) {
    try {
      const [rows] = await pool.execute(
        `SELECT ti.*, t.amount, r.origin, r.destination, u.name 
         FROM travelinfo ti 
         JOIN transactions t ON ti.transaction_id = t.id 
         JOIN rides r ON t.ride_id = r.id 
         JOIN users u ON t.user_id = u.id 
         WHERE ti.transaction_id = ?`,
        [transactionId]
      );

      if (rows.length === 0) {
        return {
          success: false,
          error: 'QR code not found'
        };
      }

      const qrInfo = rows[0];

      return {
        success: true,
        qrDetails: {
          used: qrInfo.used,
          createdAt: qrInfo.created_at,
          scannedAt: qrInfo.scanned_at,
          passengerName: qrInfo.name,
          origin: qrInfo.origin,
          destination: qrInfo.destination,
          amount: qrInfo.amount
        }
      };

    } catch (error) {
      console.error('Get QR details error:', error);
      return {
        success: false,
        error: 'Failed to get QR code details'
      };
    }
  }
}

module.exports = new QRCodeService();