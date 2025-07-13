import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../main.dart';
import '../services/qr_service.dart';
import '../utils/routes.dart';

class TicketScanScreen extends StatefulWidget {
  const TicketScanScreen({super.key});

  @override
  State<TicketScanScreen> createState() => _TicketScanScreenState();
}

class _TicketScanScreenState extends State<TicketScanScreen>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;
  bool _isProcessing = false;
  bool _flashOn = false;
  bool _frontCamera = false;

  late AnimationController _scanAnimationController;
  late AnimationController _successController;
  late AnimationController _errorController;
  late Animation<double> _scanAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _scanAnimationController.repeat();
  }

  @override
  void dispose() {
    controller?.dispose();
    _scanAnimationController.dispose();
    _successController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processQRCode(scanData.code!);
      }
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Pause scanning while processing
    await controller?.pauseCamera();

    final response = await QRService.scanQRCode(qrCode);

    if (response.isSuccess) {
      _showValidationResult(response.data!, true);
    } else {
      _showValidationResult(null, false, response.error);
    }
  }

  void _showValidationResult(QRValidation? validation, bool isSuccess, [String? errorMessage]) {
    if (isSuccess) {
      _successController.forward();
    } else {
      _errorController.forward();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _buildValidationResult(validation, isSuccess, errorMessage),
    );
  }

  Widget _buildValidationResult(QRValidation? validation, bool isSuccess, String? errorMessage) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSuccess ? Colors.green : colorScheme.error,
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess ? Colors.green : colorScheme.error).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isSuccess ? Icons.check : Icons.close,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Status message
          Text(
            isSuccess ? 'Ticket Valid!' : 'Invalid Ticket',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green : colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          if (isSuccess && validation != null) ...[
            // Success details
            Text(
              validation.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Passenger details
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passenger Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    'Name',
                    validation.rideDetails.passengerName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Phone',
                    validation.rideDetails.passengerPhone,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Route',
                    validation.rideDetails.routeText,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Amount',
                    validation.rideDetails.formattedAmount,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Transaction ID',
                    validation.rideDetails.transactionId.toString(),
                  ),
                ],
              ),
            ),
          ] else if (!isSuccess) ...[
            // Error details
            Text(
              errorMessage ?? 'This ticket could not be validated',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Possible reasons:\n• Ticket already used\n• Invalid QR code\n• Network error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _continueScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? Colors.green : colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Continue Scanning'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _continueScan() {
    Navigator.of(context).pop();
    setState(() {
      _isProcessing = false;
    });
    _successController.reset();
    _errorController.reset();
    controller?.resumeCamera();
  }

  void _toggleFlash() {
    controller?.toggleFlash();
    setState(() {
      _flashOn = !_flashOn;
    });
  }

  void _flipCamera() {
    controller?.flipCamera();
    setState(() {
      _frontCamera = !_frontCamera;
    });
  }

  void _viewScanHistory() {
    Navigator.of(context).pushNamed(Routes.scanHistory);
  }

  void _viewProfile() {
    Navigator.of(context).pushNamed(Routes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // QR Scanner
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: colorScheme.primary,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 300,
            ),
          ),

          // Top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'QR Ticket Scanner',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _viewScanHistory,
                        icon: const Icon(
                          Icons.history,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _viewProfile,
                        icon: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scanning animation overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScanLinePainter(
                    animation: _scanAnimation.value,
                    color: colorScheme.primary,
                  ),
                );
              },
            ),
          ),

          // Instructions
          Positioned(
            bottom: 150,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Position QR code within the frame',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The ticket will be validated automatically',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash toggle
                      _buildControlButton(
                        icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                        label: 'Flash',
                        onPressed: _toggleFlash,
                      ),

                      // Flip camera
                      _buildControlButton(
                        icon: Icons.flip_camera_android,
                        label: 'Flip',
                        onPressed: _flipCamera,
                      ),

                      // Conductor info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.currentUser?.name ?? 'Conductor',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.3),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double animation;
  final Color color;

  ScanLinePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanAreaSize = 300.0;
    
    final top = centerY - scanAreaSize / 2;
    final bottom = centerY + scanAreaSize / 2;
    final left = centerX - scanAreaSize / 2;
    final right = centerX + scanAreaSize / 2;

    // Calculate scan line position
    final lineY = top + (bottom - top) * animation;

    // Draw scan line
    canvas.drawLine(
      Offset(left, lineY),
      Offset(right, lineY),
      paint,
    );

    // Draw gradient effect
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        color.withOpacity(0.3),
        Colors.transparent,
      ],
    );

    final rect = Rect.fromLTWH(left, lineY - 20, scanAreaSize, 40);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect);

    canvas.drawRect(rect, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}