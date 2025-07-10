const express = require('express');
const { pool } = require('../config/database');
const { verifyToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get admin overview/dashboard data
router.get('/overview', verifyToken, requireRole(['admin']), async (req, res) => {
  try {
    const { period = '30' } = req.query; // days
    const periodDays = parseInt(period);

    // Get total users by role
    const [userStats] = await pool.execute(`
      SELECT role, COUNT(*) as count 
      FROM users 
      GROUP BY role
    `);

    // Get ride statistics for the period
    const [rideStats] = await pool.execute(`
      SELECT 
        status,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM rides 
      WHERE created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
      GROUP BY status
    `, [periodDays]);

    // Get transaction statistics for the period
    const [transactionStats] = await pool.execute(`
      SELECT 
        status,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM transactions 
      WHERE created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
      GROUP BY status
    `, [periodDays]);

    // Get daily revenue for the period
    const [dailyRevenue] = await pool.execute(`
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as transactions,
        SUM(amount) as revenue
      FROM transactions 
      WHERE status = 'completed' 
        AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    `, [periodDays]);

    // Get top routes
    const [topRoutes] = await pool.execute(`
      SELECT 
        CONCAT(origin, ' → ', destination) as route,
        COUNT(*) as ride_count,
        SUM(amount) as total_revenue,
        AVG(amount) as avg_fare
      FROM rides 
      WHERE status IN ('confirmed', 'completed')
        AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
      GROUP BY origin, destination
      ORDER BY ride_count DESC
      LIMIT 10
    `, [periodDays]);

    // Get QR code usage statistics
    const [qrStats] = await pool.execute(`
      SELECT 
        COUNT(*) as total_qr_generated,
        SUM(CASE WHEN used = TRUE THEN 1 ELSE 0 END) as qr_used,
        SUM(CASE WHEN used = FALSE THEN 1 ELSE 0 END) as qr_unused
      FROM travelinfo 
      WHERE created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
    `, [periodDays]);

    // Get conductor performance
    const [conductorPerformance] = await pool.execute(`
      SELECT 
        u.name as conductor_name,
        u.id as conductor_id,
        COUNT(ti.id) as tickets_scanned,
        SUM(t.amount) as revenue_validated
      FROM users u
      LEFT JOIN travelinfo ti ON u.id = ti.scanned_by 
        AND ti.scanned_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
      LEFT JOIN transactions t ON ti.transaction_id = t.id
      WHERE u.role = 'conductor'
      GROUP BY u.id, u.name
      ORDER BY tickets_scanned DESC
    `, [periodDays]);

    // Calculate totals
    const totalUsers = userStats.reduce((sum, stat) => sum + stat.count, 0);
    const totalRevenue = transactionStats
      .filter(stat => stat.status === 'completed')
      .reduce((sum, stat) => sum + (stat.total_amount || 0), 0);
    const totalRides = rideStats.reduce((sum, stat) => sum + stat.count, 0);
    const totalTransactions = transactionStats.reduce((sum, stat) => sum + stat.count, 0);

    res.json({
      success: true,
      message: 'Admin overview data retrieved successfully',
      data: {
        period: `${periodDays} days`,
        summary: {
          totalUsers,
          totalRides,
          totalTransactions,
          totalRevenue
        },
        userStatistics: userStats,
        rideStatistics: rideStats,
        transactionStatistics: transactionStats,
        dailyRevenue,
        topRoutes,
        qrStatistics: qrStats[0],
        conductorPerformance
      }
    });

  } catch (error) {
    console.error('Admin overview error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve admin overview',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get detailed analytics
router.get('/analytics', verifyToken, requireRole(['admin']), async (req, res) => {
  try {
    const { 
      startDate, 
      endDate, 
      groupBy = 'day' // day, week, month
    } = req.query;

    let dateCondition = '';
    let dateParams = [];

    if (startDate && endDate) {
      dateCondition = 'WHERE DATE(created_at) BETWEEN ? AND ?';
      dateParams = [startDate, endDate];
    } else {
      dateCondition = 'WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
    }

    // Determine date grouping format
    let dateFormat;
    switch (groupBy) {
      case 'week':
        dateFormat = '%Y-%u'; // Year-Week
        break;
      case 'month':
        dateFormat = '%Y-%m'; // Year-Month
        break;
      default:
        dateFormat = '%Y-%m-%d'; // Year-Month-Day
    }

    // Revenue analytics
    const [revenueAnalytics] = await pool.execute(`
      SELECT 
        DATE_FORMAT(created_at, ?) as period,
        COUNT(*) as transaction_count,
        SUM(amount) as total_revenue,
        AVG(amount) as avg_transaction_value
      FROM transactions 
      ${dateCondition} AND status = 'completed'
      GROUP BY DATE_FORMAT(created_at, ?)
      ORDER BY period DESC
    `, [dateFormat, ...dateParams, dateFormat]);

    // Ride analytics
    const [rideAnalytics] = await pool.execute(`
      SELECT 
        DATE_FORMAT(created_at, ?) as period,
        COUNT(*) as total_rides,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_rides,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_rides,
        AVG(distance) as avg_distance,
        AVG(amount) as avg_fare
      FROM rides 
      ${dateCondition}
      GROUP BY DATE_FORMAT(created_at, ?)
      ORDER BY period DESC
    `, [dateFormat, ...dateParams, dateFormat]);

    // User registration analytics
    const [userAnalytics] = await pool.execute(`
      SELECT 
        DATE_FORMAT(created_at, ?) as period,
        COUNT(*) as new_users,
        SUM(CASE WHEN role = 'passenger' THEN 1 ELSE 0 END) as new_passengers,
        SUM(CASE WHEN role = 'conductor' THEN 1 ELSE 0 END) as new_conductors
      FROM users 
      ${dateCondition}
      GROUP BY DATE_FORMAT(created_at, ?)
      ORDER BY period DESC
    `, [dateFormat, ...dateParams, dateFormat]);

    // Route popularity analytics
    const [routeAnalytics] = await pool.execute(`
      SELECT 
        origin,
        destination,
        COUNT(*) as trip_count,
        SUM(amount) as total_revenue,
        AVG(amount) as avg_fare,
        AVG(distance) as avg_distance
      FROM rides 
      ${dateCondition} AND status IN ('confirmed', 'completed')
      GROUP BY origin, destination
      ORDER BY trip_count DESC
      LIMIT 20
    `, dateParams);

    // Payment method analytics (all M-Pesa for now)
    const [paymentAnalytics] = await pool.execute(`
      SELECT 
        'M-Pesa' as payment_method,
        COUNT(*) as transaction_count,
        SUM(amount) as total_amount,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as successful_transactions,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_transactions
      FROM transactions 
      ${dateCondition}
    `, dateParams);

    res.json({
      success: true,
      message: 'Analytics data retrieved successfully',
      data: {
        period: {
          startDate: startDate || 'Last 30 days',
          endDate: endDate || 'Today',
          groupBy
        },
        revenueAnalytics,
        rideAnalytics,
        userAnalytics,
        routeAnalytics,
        paymentAnalytics
      }
    });

  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve analytics data',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get all users (with pagination and filtering)
router.get('/users', verifyToken, requireRole(['admin']), async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      role, 
      search 
    } = req.query;

    const offset = (page - 1) * limit;
    
    let query = `
      SELECT id, name, phone, role, created_at, updated_at
      FROM users 
      WHERE 1=1
    `;
    const queryParams = [];

    if (role) {
      query += ' AND role = ?';
      queryParams.push(role);
    }

    if (search) {
      query += ' AND (name LIKE ? OR phone LIKE ?)';
      queryParams.push(`%${search}%`, `%${search}%`);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    queryParams.push(parseInt(limit), offset);

    const [users] = await pool.execute(query, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as total FROM users WHERE 1=1';
    const countParams = [];
    
    if (role) {
      countQuery += ' AND role = ?';
      countParams.push(role);
    }

    if (search) {
      countQuery += ' AND (name LIKE ? OR phone LIKE ?)';
      countParams.push(`%${search}%`, `%${search}%`);
    }

    const [countResult] = await pool.execute(countQuery, countParams);
    const total = countResult[0].total;

    res.json({
      success: true,
      message: 'Users retrieved successfully',
      data: {
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / limit),
          totalUsers: total,
          hasNext: offset + users.length < total,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve users',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get all rides (with pagination and filtering)
router.get('/rides', verifyToken, requireRole(['admin']), async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status, 
      startDate,
      endDate 
    } = req.query;

    const offset = (page - 1) * limit;
    
    let query = `
      SELECT r.*, u.name as passenger_name, u.phone as passenger_phone,
             t.status as payment_status, t.mpesa_code
      FROM rides r 
      JOIN users u ON r.user_id = u.id 
      LEFT JOIN transactions t ON r.id = t.ride_id 
      WHERE 1=1
    `;
    const queryParams = [];

    if (status) {
      query += ' AND r.status = ?';
      queryParams.push(status);
    }

    if (startDate && endDate) {
      query += ' AND DATE(r.created_at) BETWEEN ? AND ?';
      queryParams.push(startDate, endDate);
    }

    query += ' ORDER BY r.created_at DESC LIMIT ? OFFSET ?';
    queryParams.push(parseInt(limit), offset);

    const [rides] = await pool.execute(query, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as total FROM rides r WHERE 1=1';
    const countParams = [];
    
    if (status) {
      countQuery += ' AND r.status = ?';
      countParams.push(status);
    }

    if (startDate && endDate) {
      countQuery += ' AND DATE(r.created_at) BETWEEN ? AND ?';
      countParams.push(startDate, endDate);
    }

    const [countResult] = await pool.execute(countQuery, countParams);
    const total = countResult[0].total;

    res.json({
      success: true,
      message: 'Rides retrieved successfully',
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
    console.error('Get rides error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve rides',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// Get all transactions (with pagination and filtering)
router.get('/transactions', verifyToken, requireRole(['admin']), async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      status, 
      startDate,
      endDate 
    } = req.query;

    const offset = (page - 1) * limit;
    
    let query = `
      SELECT t.*, r.origin, r.destination, u.name as user_name, u.phone as user_phone
      FROM transactions t 
      JOIN rides r ON t.ride_id = r.id 
      JOIN users u ON t.user_id = u.id 
      WHERE 1=1
    `;
    const queryParams = [];

    if (status) {
      query += ' AND t.status = ?';
      queryParams.push(status);
    }

    if (startDate && endDate) {
      query += ' AND DATE(t.created_at) BETWEEN ? AND ?';
      queryParams.push(startDate, endDate);
    }

    query += ' ORDER BY t.created_at DESC LIMIT ? OFFSET ?';
    queryParams.push(parseInt(limit), offset);

    const [transactions] = await pool.execute(query, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) as total FROM transactions t WHERE 1=1';
    const countParams = [];
    
    if (status) {
      countQuery += ' AND t.status = ?';
      countParams.push(status);
    }

    if (startDate && endDate) {
      countQuery += ' AND DATE(t.created_at) BETWEEN ? AND ?';
      countParams.push(startDate, endDate);
    }

    const [countResult] = await pool.execute(countQuery, countParams);
    const total = countResult[0].total;

    res.json({
      success: true,
      message: 'Transactions retrieved successfully',
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
      message: 'Failed to retrieve transactions',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

// System health check
router.get('/system-health', verifyToken, requireRole(['admin']), async (req, res) => {
  try {
    // Database connection check
    const [dbCheck] = await pool.execute('SELECT 1 as status');
    const dbStatus = dbCheck.length > 0 ? 'healthy' : 'unhealthy';

    // Get database statistics
    const [tableStats] = await pool.execute(`
      SELECT 
        table_name,
        table_rows,
        data_length,
        index_length
      FROM information_schema.tables 
      WHERE table_schema = ?
    `, [process.env.DB_NAME]);

    // Get recent error logs (if any)
    const systemInfo = {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      nodeVersion: process.version,
      platform: process.platform,
      environment: process.env.NODE_ENV
    };

    res.json({
      success: true,
      message: 'System health check completed',
      data: {
        database: {
          status: dbStatus,
          tableStatistics: tableStats
        },
        system: systemInfo,
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('System health check error:', error);
    res.status(500).json({
      success: false,
      message: 'System health check failed',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
});

module.exports = router;