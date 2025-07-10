const express = require('express');
const { pool } = require('../config/database');
const { verifyToken, requireRole } = require('../middleware/auth');
const qrCodeService = require('../utils/qrcode');

const router = express.Router();

// Generate QR code for a completed transaction
router.get('/generate-qr/:transactionId', verifyToken, async (req, res) => {
  try {
    const { transactionId } = req.params;
    const userId = req.user.id;

    // Verify transaction belongs to user (unless admin)
    if (req.user.role !== 'admin') {
      const [transactions] = await pool.execute(
        'SELECT user_id FROM transactions WHERE id = ?',
        [transactionId]
      );

      if (transactions.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found'
        });
      }

      if (transactions[0].user_id !== userId) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to generate QR code for this transaction'
        });
      }
    }

    // Generate QR code
    const result = await qrCodeService.generateQRCode(transactionId);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }

    res.json({
      success: true,
      message: 'QR code generated successfully',
      data: {
        qrCodeImage: result.qrCodeImage,
        qrCodeData: result.qrCodeData,
        rideDetails: result.rideDetails,
        instructions: 'Show this QR code to the conductor for validation'
      }
    });

  } catch (error) {
    console.error('QR code generation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate QR code',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Scan and validate QR code (for conductors)
router.post('/scan-qr', verifyToken, requireRole(['conductor', 'admin']), async (req, res) => {
  try {
    const { qrCodeData } = req.body;
    const scannerId = req.user.id;

    if (!qrCodeData) {
      return res.status(400).json({
        success: false,
        message: 'QR code data is required'
      });
    }

    // Validate QR code
    const result = await qrCodeService.validateQRCode(qrCodeData, scannerId);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.error,
        data: result.usedAt ? { usedAt: result.usedAt } : null
      });
    }

    res.json({
      success: true,
      message: result.message,
      data: {
        rideDetails: result.rideDetails,
        validatedBy: req.user.name,
        validatedAt: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('QR code validation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to validate QR code',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get QR code details
router.get('/qr-details/:transactionId', verifyToken, async (req, res) => {
  try {
    const { transactionId } = req.params;
    const userId = req.user.id;

    // Verify access permissions
    if (req.user.role !== 'admin' && req.user.role !== 'conductor') {
      const [transactions] = await pool.execute(
        'SELECT user_id FROM transactions WHERE id = ?',
        [transactionId]
      );

      if (transactions.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found'
        });
      }

      if (transactions[0].user_id !== userId) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to view this QR code details'
        });
      }
    }

    // Get QR code details
    const result = await qrCodeService.getQRCodeDetails(transactionId);

    if (!result.success) {
      return res.status(404).json({
        success: false,
        message: result.error
      });
    }

    res.json({
      success: true,
      message: 'QR code details retrieved successfully',
      data: result.qrDetails
    });

  } catch (error) {
    console.error('Get QR details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve QR code details',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get scanned tickets history (for conductors)
router.get('/scanned-history', verifyToken, requireRole(['conductor', 'admin']), async (req, res) => {
  try {
    const scannerId = req.user.id;
    const { page = 1, limit = 10, date } = req.query;

    const offset = (page - 1) * limit;
    
    let query = `
      SELECT ti.*, t.amount, t.mpesa_code, r.origin, r.destination, 
             u.name as passenger_name, u.phone as passenger_phone,
             scanner.name as scanner_name
      FROM travelinfo ti 
      JOIN transactions t ON ti.transaction_id = t.id 
      JOIN rides r ON t.ride_id = r.id 
      JOIN users u ON t.user_id = u.id 
      LEFT JOIN users scanner ON ti.scanned_by = scanner.id 
      WHERE ti.used = TRUE
    `;
    
    const queryParams = [];

    // Filter by scanner for conductors
    if (req.user.role === 'conductor') {
      query += ' AND ti.scanned_by = ?';
      queryParams.push(scannerId);
    }

    // Filter by date if provided
    if (date) {
      query += ' AND DATE(ti.scanned_at) = ?';
      queryParams.push(date);
    }

    query += ' ORDER BY ti.scanned_at DESC LIMIT ? OFFSET ?';
    queryParams.push(parseInt(limit), offset);

    const [scannedTickets] = await pool.execute(query, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as total FROM travelinfo ti WHERE ti.used = TRUE';
    const countParams = [];
    
    if (req.user.role === 'conductor') {
      countQuery += ' AND ti.scanned_by = ?';
      countParams.push(scannerId);
    }

    if (date) {
      countQuery += req.user.role === 'conductor' ? ' AND' : ' WHERE';
      countQuery += ' DATE(ti.scanned_at) = ?';
      countParams.push(date);
    }

    const [countResult] = await pool.execute(countQuery, countParams);
    const total = countResult[0].total;

    res.json({
      success: true,
      message: 'Scanned tickets history retrieved successfully',
      data: {
        scannedTickets,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalTickets: total,
          hasNext: offset + scannedTickets.length < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Get scanned history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve scanned tickets history',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get ticket statistics (for conductors and admins)
router.get('/ticket-stats', verifyToken, requireRole(['conductor', 'admin']), async (req, res) => {
  try {
    const scannerId = req.user.id;
    const { date = new Date().toISOString().split('T')[0] } = req.query;

    // Build base query
    let baseCondition = 'DATE(ti.scanned_at) = ?';
    let baseParams = [date];

    if (req.user.role === 'conductor') {
      baseCondition += ' AND ti.scanned_by = ?';
      baseParams.push(scannerId);
    }

    // Get total scanned tickets for the date
    const [totalScanned] = await pool.execute(
      `SELECT COUNT(*) as total FROM travelinfo ti WHERE ti.used = TRUE AND ${baseCondition}`,
      baseParams
    );

    // Get total revenue for the date
    const [totalRevenue] = await pool.execute(
      `SELECT SUM(t.amount) as revenue 
       FROM travelinfo ti 
       JOIN transactions t ON ti.transaction_id = t.id 
       WHERE ti.used = TRUE AND ${baseCondition}`,
      baseParams
    );

    // Get hourly breakdown
    const [hourlyStats] = await pool.execute(
      `SELECT HOUR(ti.scanned_at) as hour, COUNT(*) as count, SUM(t.amount) as revenue
       FROM travelinfo ti 
       JOIN transactions t ON ti.transaction_id = t.id 
       WHERE ti.used = TRUE AND ${baseCondition}
       GROUP BY HOUR(ti.scanned_at) 
       ORDER BY hour`,
      baseParams
    );

    // Get top routes for the date
    const [topRoutes] = await pool.execute(
      `SELECT CONCAT(r.origin, ' → ', r.destination) as route, 
              COUNT(*) as ticket_count, SUM(t.amount) as revenue
       FROM travelinfo ti 
       JOIN transactions t ON ti.transaction_id = t.id 
       JOIN rides r ON t.ride_id = r.id 
       WHERE ti.used = TRUE AND ${baseCondition}
       GROUP BY r.origin, r.destination 
       ORDER BY ticket_count DESC 
       LIMIT 10`,
      baseParams
    );

    res.json({
      success: true,
      message: 'Ticket statistics retrieved successfully',
      data: {
        date,
        totalTicketsScanned: totalScanned[0].total,
        totalRevenue: totalRevenue[0].revenue || 0,
        hourlyBreakdown: hourlyStats,
        topRoutes,
        scannerName: req.user.name
      }
    });

  } catch (error) {
    console.error('Get ticket stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve ticket statistics',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Check if transaction has valid QR code
router.get('/check-qr-status/:transactionId', verifyToken, async (req, res) => {
  try {
    const { transactionId } = req.params;
    const userId = req.user.id;

    // Verify transaction belongs to user (unless admin)
    if (req.user.role !== 'admin') {
      const [transactions] = await pool.execute(
        'SELECT user_id FROM transactions WHERE id = ?',
        [transactionId]
      );

      if (transactions.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found'
        });
      }

      if (transactions[0].user_id !== userId) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to check this transaction'
        });
      }
    }

    // Check QR code status
    const [qrStatus] = await pool.execute(
      `SELECT ti.used, ti.scanned_at, ti.created_at, t.status as transaction_status,
              scanner.name as scanned_by_name
       FROM transactions t 
       LEFT JOIN travelinfo ti ON t.id = ti.transaction_id 
       LEFT JOIN users scanner ON ti.scanned_by = scanner.id 
       WHERE t.id = ?`,
      [transactionId]
    );

    if (qrStatus.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    const status = qrStatus[0];

    let qrCodeStatus;
    if (status.transaction_status !== 'completed') {
      qrCodeStatus = 'payment_not_completed';
    } else if (!status.created_at) {
      qrCodeStatus = 'qr_not_generated';
    } else if (status.used) {
      qrCodeStatus = 'qr_used';
    } else {
      qrCodeStatus = 'qr_available';
    }

    res.json({
      success: true,
      message: 'QR code status retrieved successfully',
      data: {
        transactionId: parseInt(transactionId),
        qrCodeStatus,
        isUsed: status.used || false,
        scannedAt: status.scanned_at,
        scannedBy: status.scanned_by_name,
        qrCreatedAt: status.created_at,
        transactionStatus: status.transaction_status
      }
    });

  } catch (error) {
    console.error('Check QR status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check QR code status',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;