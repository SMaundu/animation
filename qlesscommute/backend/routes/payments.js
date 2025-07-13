const express = require('express');
const { pool } = require('../config/database');
const { verifyToken, requireRole } = require('../middleware/auth');
const mpesaService = require('../utils/mpesa');

const router = express.Router();

// Input validation helper
const validateInput = (data, fields) => {
  const errors = [];
  
  fields.forEach(field => {
    if (!data[field] || data[field].toString().trim() === '') {
      errors.push(`${field} is required`);
    }
  });
  
  return errors;
};

// Validate phone number format
const validatePhone = (phone) => {
  const phoneRegex = /^(254|0)[7-9]\d{8}$/;
  return phoneRegex.test(phone);
};

// Initiate M-Pesa payment
router.post('/initiate-payment', verifyToken, requireRole(['passenger']), async (req, res) => {
  try {
    const { rideId, phoneNumber } = req.body;
    const userId = req.user.id;

    // Validate input
    const errors = validateInput(req.body, ['rideId', 'phoneNumber']);
    
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors
      });
    }

    // Validate phone number
    if (!validatePhone(phoneNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number format. Use format: 0712345678 or 254712345678'
      });
    }

    // Get ride details
    const [rides] = await pool.execute(
      'SELECT * FROM rides WHERE id = ? AND user_id = ?',
      [rideId, userId]
    );

    if (rides.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found or you do not have permission to pay for this ride'
      });
    }

    const ride = rides[0];

    // Check if ride is in correct status
    if (ride.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'This ride cannot be paid for. Current status: ' + ride.status
      });
    }

    // Check if there's already a pending or completed transaction for this ride
    const [existingTransactions] = await pool.execute(
      'SELECT * FROM transactions WHERE ride_id = ? AND status IN ("pending", "completed")',
      [rideId]
    );

    if (existingTransactions.length > 0) {
      const transaction = existingTransactions[0];
      if (transaction.status === 'completed') {
        return res.status(400).json({
          success: false,
          message: 'Payment has already been completed for this ride'
        });
      } else {
        return res.status(400).json({
          success: false,
          message: 'There is already a pending payment for this ride',
          data: {
            transactionId: transaction.id,
            checkoutRequestId: transaction.checkout_request_id
          }
        });
      }
    }

    // Create transaction record
    const [transactionResult] = await pool.execute(
      `INSERT INTO transactions (user_id, ride_id, amount, phone, status) 
       VALUES (?, ?, ?, ?, 'pending')`,
      [userId, rideId, ride.amount, phoneNumber]
    );

    const transactionId = transactionResult.insertId;

    // Initiate STK Push
    const accountReference = `RIDE${rideId}`;
    const transactionDesc = `Payment for ride from ${ride.origin} to ${ride.destination}`;

    const stkResult = await mpesaService.initiateSTKPush(
      phoneNumber,
      ride.amount,
      accountReference,
      transactionDesc
    );

    if (!stkResult.success) {
      // Update transaction status to failed
      await pool.execute(
        'UPDATE transactions SET status = "failed", updated_at = NOW() WHERE id = ?',
        [transactionId]
      );

      return res.status(400).json({
        success: false,
        message: 'Failed to initiate payment',
        error: stkResult.error
      });
    }

    // Update transaction with STK Push details
    await pool.execute(
      `UPDATE transactions 
       SET checkout_request_id = ?, merchant_request_id = ?, updated_at = NOW() 
       WHERE id = ?`,
      [stkResult.checkoutRequestId, stkResult.merchantRequestId, transactionId]
    );

    res.status(201).json({
      success: true,
      message: 'Payment initiated successfully. Please check your phone for the M-Pesa prompt.',
      data: {
        transactionId,
        checkoutRequestId: stkResult.checkoutRequestId,
        merchantRequestId: stkResult.merchantRequestId,
        amount: ride.amount,
        phoneNumber: phoneNumber,
        instructions: 'Please complete the payment on your phone to confirm your ride booking.'
      }
    });

  } catch (error) {
    console.error('Payment initiation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to initiate payment',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// M-Pesa payment callback
router.post('/payment-callback', async (req, res) => {
  try {
    console.log('M-Pesa Callback received:', JSON.stringify(req.body, null, 2));

    const result = await mpesaService.processCallback(req.body);

    if (result.success) {
      console.log('Payment processed successfully:', result.mpesaCode);
    } else {
      console.log('Payment failed:', result.error);
    }

    // Always respond with success to M-Pesa
    res.status(200).json({
      ResultCode: 0,
      ResultDesc: 'Callback processed successfully'
    });

  } catch (error) {
    console.error('Callback processing error:', error);
    
    // Still respond with success to avoid callback retries
    res.status(200).json({
      ResultCode: 0,
      ResultDesc: 'Callback received'
    });
  }
});

// Check payment status
router.get('/payment-status/:transactionId', verifyToken, async (req, res) => {
  try {
    const { transactionId } = req.params;
    const userId = req.user.id;

    // Get transaction details
    const [transactions] = await pool.execute(
      `SELECT t.*, r.origin, r.destination 
       FROM transactions t 
       JOIN rides r ON t.ride_id = r.id 
       WHERE t.id = ? AND t.user_id = ?`,
      [transactionId, userId]
    );

    if (transactions.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    const transaction = transactions[0];

    // If transaction is still pending and has checkout request ID, query M-Pesa
    if (transaction.status === 'pending' && transaction.checkout_request_id) {
      const queryResult = await mpesaService.querySTKPushStatus(transaction.checkout_request_id);
      
      if (queryResult.success) {
        const mpesaData = queryResult.data;
        
        // Update transaction based on M-Pesa response
        if (mpesaData.ResultCode === "0") {
          // Payment successful
          await pool.execute(
            'UPDATE transactions SET status = "completed", updated_at = NOW() WHERE id = ?',
            [transactionId]
          );
          
          // Update ride status
          await pool.execute(
            'UPDATE rides SET status = "confirmed", updated_at = NOW() WHERE id = ?',
            [transaction.ride_id]
          );
          
          transaction.status = 'completed';
        } else if (mpesaData.ResultCode === "1032") {
          // User cancelled
          await pool.execute(
            'UPDATE transactions SET status = "cancelled", updated_at = NOW() WHERE id = ?',
            [transactionId]
          );
          
          transaction.status = 'cancelled';
        } else if (mpesaData.ResultCode !== "1037") {
          // Failed (1037 means still pending)
          await pool.execute(
            'UPDATE transactions SET status = "failed", updated_at = NOW() WHERE id = ?',
            [transactionId]
          );
          
          transaction.status = 'failed';
        }
      }
    }

    res.json({
      success: true,
      message: 'Payment status retrieved successfully',
      data: {
        transactionId: transaction.id,
        rideId: transaction.ride_id,
        amount: transaction.amount,
        status: transaction.status,
        mpesaCode: transaction.mpesa_code,
        phoneNumber: transaction.phone,
        origin: transaction.origin,
        destination: transaction.destination,
        createdAt: transaction.created_at,
        updatedAt: transaction.updated_at
      }
    });

  } catch (error) {
    console.error('Payment status check error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check payment status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get user's transaction history
router.get('/transactions', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 10, status } = req.query;

    const offset = (page - 1) * limit;
    
    let query = `
      SELECT t.*, r.origin, r.destination 
      FROM transactions t 
      JOIN rides r ON t.ride_id = r.id 
      WHERE t.user_id = ?
    `;
    
    const queryParams = [userId];

    if (status) {
      query += ' AND t.status = ?';
      queryParams.push(status);
    }

    query += ' ORDER BY t.created_at DESC LIMIT ? OFFSET ?';
    queryParams.push(parseInt(limit), offset);

    const [transactions] = await pool.execute(query, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as total FROM transactions WHERE user_id = ?';
    const countParams = [userId];
    
    if (status) {
      countQuery += ' AND status = ?';
      countParams.push(status);
    }

    const [countResult] = await pool.execute(countQuery, countParams);
    const total = countResult[0].total;

    res.json({
      success: true,
      message: 'Transaction history retrieved successfully',
      data: {
        transactions,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalTransactions: total,
          hasNext: offset + transactions.length < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve transaction history',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Retry failed payment
router.post('/retry-payment/:transactionId', verifyToken, requireRole(['passenger']), async (req, res) => {
  try {
    const { transactionId } = req.params;
    const { phoneNumber } = req.body;
    const userId = req.user.id;

    // Validate phone number
    if (!validatePhone(phoneNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number format. Use format: 0712345678 or 254712345678'
      });
    }

    // Get transaction details
    const [transactions] = await pool.execute(
      `SELECT t.*, r.origin, r.destination 
       FROM transactions t 
       JOIN rides r ON t.ride_id = r.id 
       WHERE t.id = ? AND t.user_id = ?`,
      [transactionId, userId]
    );

    if (transactions.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    const transaction = transactions[0];

    // Check if transaction can be retried
    if (transaction.status !== 'failed' && transaction.status !== 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Only failed or cancelled transactions can be retried'
      });
    }

    // Reset transaction status
    await pool.execute(
      `UPDATE transactions 
       SET status = 'pending', phone = ?, checkout_request_id = NULL, 
           merchant_request_id = NULL, updated_at = NOW() 
       WHERE id = ?`,
      [phoneNumber, transactionId]
    );

    // Initiate new STK Push
    const accountReference = `RETRY${transactionId}`;
    const transactionDesc = `Retry payment for ride from ${transaction.origin} to ${transaction.destination}`;

    const stkResult = await mpesaService.initiateSTKPush(
      phoneNumber,
      transaction.amount,
      accountReference,
      transactionDesc
    );

    if (!stkResult.success) {
      // Update transaction status to failed
      await pool.execute(
        'UPDATE transactions SET status = "failed", updated_at = NOW() WHERE id = ?',
        [transactionId]
      );

      return res.status(400).json({
        success: false,
        message: 'Failed to retry payment',
        error: stkResult.error
      });
    }

    // Update transaction with new STK Push details
    await pool.execute(
      `UPDATE transactions 
       SET checkout_request_id = ?, merchant_request_id = ?, updated_at = NOW() 
       WHERE id = ?`,
      [stkResult.checkoutRequestId, stkResult.merchantRequestId, transactionId]
    );

    res.json({
      success: true,
      message: 'Payment retry initiated successfully. Please check your phone for the M-Pesa prompt.',
      data: {
        transactionId,
        checkoutRequestId: stkResult.checkoutRequestId,
        amount: transaction.amount,
        phoneNumber: phoneNumber
      }
    });

  } catch (error) {
    console.error('Payment retry error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retry payment',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;