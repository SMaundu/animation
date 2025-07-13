import 'package:flutter/material.dart';
import 'dart:async';

import '../services/payment_service.dart';
import '../utils/routes.dart';

class PaymentStatusScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;

  const PaymentStatusScreen({
    super.key,
    required this.paymentData,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with TickerProviderStateMixin {
  PaymentStatus? _paymentStatus;
  bool _isLoading = true;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 100; // 5 minutes max polling

  late AnimationController _loadingController;
  late AnimationController _successController;
  late AnimationController _errorController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPaymentPolling();
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _loadingController.repeat();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _loadingController.dispose();
    _successController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  int get transactionId => widget.paymentData['transactionId'] as int;
  int get rideId => widget.paymentData['rideId'] as int;
  PaymentInitiation get paymentInitiation =>
      widget.paymentData['paymentInitiation'] as PaymentInitiation;

  void _startPaymentPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_pollAttempts >= _maxPollAttempts) {
        timer.cancel();
        _handlePaymentTimeout();
        return;
      }

      _pollAttempts++;
      await _checkPaymentStatus();
    });

    // Initial check
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    final response = await PaymentService.getPaymentStatus(transactionId);

    if (response.isSuccess) {
      final status = response.data!;

      setState(() {
        _paymentStatus = status;
        _isLoading = false;
      });

      if (status.isCompleted) {
        _pollTimer?.cancel();
        _loadingController.stop();
        _successController.forward();
      } else if (status.isFailed || status.isCancelled) {
        _pollTimer?.cancel();
        _loadingController.stop();
        _errorController.forward();
      }
    }
  }

  void _handlePaymentTimeout() {
    setState(() {
      _isLoading = false;
    });
    _loadingController.stop();
    _errorController.forward();
  }

  void _retryPayment() {
    // Navigate back to fare confirmation with same data
    Navigator.of(context).pushReplacementNamed(
      Routes.fareConfirmation,
      arguments: widget.paymentData,
    );
  }

  void _goToQRCode() {
    Navigator.of(context).pushReplacementNamed(
      Routes.qrCode,
      arguments: {
        'transactionId': transactionId,
        'rideId': rideId,
      },
    );
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        'Payment Status',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),

                const SizedBox(height: 32),

                // Status content
                Expanded(
                  child: _buildStatusContent(),
                ),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading || _paymentStatus == null) {
      return _buildLoadingState();
    }

    if (_paymentStatus!.isCompleted) {
      return _buildSuccessState();
    }

    if (_paymentStatus!.isFailed || _paymentStatus!.isCancelled) {
      return _buildErrorState();
    }

    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated loading indicator
        AnimatedBuilder(
          animation: _loadingAnimation,
          builder: (context, child) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.2),
                    colorScheme.primary,
                    colorScheme.secondary,
                    colorScheme.primary.withOpacity(0.2),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  transform: GradientRotation(_loadingAnimation.value * 2 * 3.14159),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                ),
                child: Icon(
                  Icons.phone_android,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        Text(
          'Processing Payment',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          'We\'ve sent an STK push to ${paymentInitiation.phoneNumber}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Instructions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Check your phone for the M-Pesa popup\n'
                '2. Enter your M-Pesa PIN\n'
                '3. Confirm the payment',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Payment details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Amount',
                paymentInitiation.formattedAmount,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Phone',
                paymentInitiation.phoneNumber,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Transaction ID',
                transactionId.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Payment Successful!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          'Your ride has been booked successfully',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Success details
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'M-Pesa Code',
                _paymentStatus!.mpesaCode ?? 'N/A',
                isHighlighted: true,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Amount Paid',
                _paymentStatus!.formattedAmount,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Route',
                _paymentStatus!.routeText,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Transaction ID',
                transactionId.toString(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.qr_code,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your QR code ticket is ready! Show this to the conductor when boarding.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Error animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.error,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.error.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          _paymentStatus?.isCancelled == true ? 'Payment Cancelled' : 'Payment Failed',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          _paymentStatus?.isCancelled == true
              ? 'You cancelled the payment'
              : 'There was an issue processing your payment',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Error details
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.error.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Status',
                _paymentStatus?.statusDisplayText ?? 'Failed',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Amount',
                paymentInitiation.formattedAmount,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Transaction ID',
                transactionId.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading || _paymentStatus == null) {
      return ElevatedButton(
        onPressed: () {
          _pollTimer?.cancel();
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surfaceVariant,
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
        child: const Text('Cancel'),
      );
    }

    if (_paymentStatus!.isCompleted) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goToQRCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('View QR Ticket'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _goHome,
              child: const Text('Book Another Ride'),
            ),
          ),
        ],
      );
    }

    // Failed or cancelled
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _retryPayment,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goHome,
            child: const Text('Go Home'),
          ),
        ),
      ],
    );
  }
}