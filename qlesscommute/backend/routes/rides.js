const express = require('express');
const { pool } = require('../config/database');
const { verifyToken, requireRole } = require('../middleware/auth');

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

// Calculate distance between two points (Haversine formula)
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Radius of Earth in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c; // Distance in kilometers
  return distance;
};

// Calculate fare based on distance
const calculateFare = (distance) => {
  const basefare = 50; // Base fare in KES
  const ratePerKm = 15; // Rate per kilometer in KES
  const fare = basefare + (distance * ratePerKm);
  return Math.round(fare * 100) / 100; // Round to 2 decimal places
};

// Get fare estimation
router.post('/estimate-fare', verifyToken, async (req, res) => {
  try {
    const { 
      originLat, 
      originLng, 
      destinationLat, 
      destinationLng,
      origin,
      destination 
    } = req.body;

    // Validate input
    const errors = validateInput(req.body, [
      'originLat', 'originLng', 'destinationLat', 'destinationLng',
      'origin', 'destination'
    ]);
    
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors
      });
    }

    // Validate coordinates
    if (originLat < -90 || originLat > 90 || destinationLat < -90 || destinationLat > 90) {
      return res.status(400).json({
        success: false,
        message: 'Invalid latitude values'
      });
    }

    if (originLng < -180 || originLng > 180 || destinationLng < -180 || destinationLng > 180) {
      return res.status(400).json({
        success: false,
        message: 'Invalid longitude values'
      });
    }

    // Calculate distance
    const distance = calculateDistance(
      parseFloat(originLat),
      parseFloat(originLng),
      parseFloat(destinationLat),
      parseFloat(destinationLng)
    );

    // Calculate fare
    const estimatedFare = calculateFare(distance);

    res.json({
      success: true,
      message: 'Fare estimation calculated successfully',
      data: {
        distance: Math.round(distance * 100) / 100,
        estimatedFare,
        origin,
        destination,
        breakdown: {
          baseFare: 50,
          distanceFare: Math.round((distance * 15) * 100) / 100,
          totalFare: estimatedFare
        }
      }
    });

  } catch (error) {
    console.error('Fare estimation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate fare estimation',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Book a ride
router.post('/book-ride', verifyToken, requireRole(['passenger']), async (req, res) => {
  try {
    const { 
      origin,
      destination,
      originLat,
      originLng,
      destinationLat,
      destinationLng
    } = req.body;

    const userId = req.user.id;

    // Validate input
    const errors = validateInput(req.body, [
      'origin', 'destination', 'originLat', 'originLng', 
      'destinationLat', 'destinationLng'
    ]);
    
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors
      });
    }

    // Check if user has any pending rides
    const [pendingRides] = await pool.execute(
      'SELECT id FROM rides WHERE user_id = ? AND status IN ("pending", "confirmed")',
      [userId]
    );

    if (pendingRides.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'You already have a pending or confirmed ride. Complete it before booking a new one.'
      });
    }

    // Calculate distance and fare
    const distance = calculateDistance(
      parseFloat(originLat),
      parseFloat(originLng),
      parseFloat(destinationLat),
      parseFloat(destinationLng)
    );

    const amount = calculateFare(distance);

    // Create ride booking
    const [result] = await pool.execute(
      `INSERT INTO rides (
        user_id, origin, destination, origin_lat, origin_lng, 
        destination_lat, destination_lng, distance, amount, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [
        userId, origin.trim(), destination.trim(),
        parseFloat(originLat), parseFloat(originLng),
        parseFloat(destinationLat), parseFloat(destinationLng),
        distance, amount
      ]
    );

    // Get the created ride details
    const [rideDetails] = await pool.execute(
      `SELECT r.*, u.name as passenger_name, u.phone as passenger_phone 
       FROM rides r 
       JOIN users u ON r.user_id = u.id 
       WHERE r.id = ?`,
      [result.insertId]
    );

    res.status(201).json({
      success: true,
      message: 'Ride booked successfully',
      data: {
        ride: rideDetails[0],
        nextStep: 'Proceed to payment to confirm your booking'
      }
    });

  } catch (error) {
    console.error('Ride booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to book ride',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get user's ride history
router.get('/user-rides/:userId', verifyToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10, status } = req.query;

    // Check if user is requesting their own rides or is an admin
    if (req.user.id !== parseInt(userId) && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'You can only view your own ride history'
      });
    }

    const offset = (page - 1) * limit;
    
    let query = `
      SELECT r.*, t.mpesa_code, t.status as payment_status, 
             ti.used as ticket_used, ti.scanned_at
      FROM rides r 
      LEFT JOIN transactions t ON r.id = t.ride_id 
      LEFT JOIN travelinfo ti ON t.id = ti.transaction_id 
      WHERE r.user_id = ?
    `;
    
    const queryParams = [userId];

    if (status) {
      query += ' AND r.status = ?';
      queryParams.push(status);
    }

    query += ' ORDER BY r.created_at DESC LIMIT ? OFFSET ?';
    queryParams.push(parseInt(limit), offset);

    const [rides] = await pool.execute(query, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as total FROM rides WHERE user_id = ?';
    const countParams = [userId];
    
    if (status) {
      countQuery += ' AND status = ?';
      countParams.push(status);
    }

    const [countResult] = await pool.execute(countQuery, countParams);
    const total = countResult[0].total;

    res.json({
      success: true,
      message: 'Ride history retrieved successfully',
      data: {
        rides,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalRides: total,
          hasNext: offset + rides.length < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Get ride history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve ride history',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get ride details by ID
router.get('/:rideId', verifyToken, async (req, res) => {
  try {
    const { rideId } = req.params;

    const [rides] = await pool.execute(
      `SELECT r.*, u.name as passenger_name, u.phone as passenger_phone,
              t.mpesa_code, t.status as payment_status, t.amount as paid_amount,
              ti.used as ticket_used, ti.scanned_at, ti.qr_code_data
       FROM rides r 
       JOIN users u ON r.user_id = u.id 
       LEFT JOIN transactions t ON r.id = t.ride_id 
       LEFT JOIN travelinfo ti ON t.id = ti.transaction_id 
       WHERE r.id = ?`,
      [rideId]
    );

    if (rides.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found'
      });
    }

    const ride = rides[0];

    // Check if user has permission to view this ride
    if (req.user.id !== ride.user_id && req.user.role !== 'admin' && req.user.role !== 'conductor') {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to view this ride'
      });
    }

    res.json({
      success: true,
      message: 'Ride details retrieved successfully',
      data: { ride }
    });

  } catch (error) {
    console.error('Get ride details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve ride details',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Cancel a ride
router.patch('/:rideId/cancel', verifyToken, async (req, res) => {
  try {
    const { rideId } = req.params;
    const userId = req.user.id;

    // Get ride details
    const [rides] = await pool.execute(
      'SELECT * FROM rides WHERE id = ? AND user_id = ?',
      [rideId, userId]
    );

    if (rides.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Ride not found or you do not have permission to cancel this ride'
      });
    }

    const ride = rides[0];

    // Check if ride can be cancelled
    if (ride.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel a completed ride'
      });
    }

    if (ride.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Ride is already cancelled'
      });
    }

    // Update ride status
    await pool.execute(
      'UPDATE rides SET status = "cancelled", updated_at = NOW() WHERE id = ?',
      [rideId]
    );

    // Cancel any pending transactions
    await pool.execute(
      'UPDATE transactions SET status = "cancelled", updated_at = NOW() WHERE ride_id = ? AND status = "pending"',
      [rideId]
    );

    res.json({
      success: true,
      message: 'Ride cancelled successfully'
    });

  } catch (error) {
    console.error('Cancel ride error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel ride',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;