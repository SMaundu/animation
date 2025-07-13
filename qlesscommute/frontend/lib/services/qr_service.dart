import 'api_service.dart';

class QRService {
  // Generate QR code for a transaction
  static Future<ApiResponse<QRTicket>> generateQRCode(int transactionId) async {
    return await ApiService.get<QRTicket>(
      '/qr/generate-qr/$transactionId',
      QRTicket.fromJson,
    );
  }

  // Scan and validate QR code
  static Future<ApiResponse<QRValidation>> scanQRCode(String qrCodeData) async {
    return await ApiService.post<QRValidation>(
      '/qr/scan-qr',
      {
        'qrCodeData': qrCodeData,
      },
      QRValidation.fromJson,
    );
  }

  // Get QR code details
  static Future<ApiResponse<QRDetails>> getQRDetails(int transactionId) async {
    return await ApiService.get<QRDetails>(
      '/qr/qr-details/$transactionId',
      QRDetails.fromJson,
    );
  }

  // Get scanned ticket history (for conductors)
  static Future<ApiResponse<List<ScannedTicket>>> getScannedHistory({
    int page = 1,
    int limit = 10,
    String? date,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (date != null) {
      queryParams['date'] = date;
    }

    return await ApiService.getList<ScannedTicket>(
      '/qr/scanned-history',
      ScannedTicket.fromJson,
      'scannedTickets',
      queryParams: queryParams,
    );
  }

  // Get ticket statistics
  static Future<ApiResponse<TicketStats>> getTicketStats({
    String? date,
  }) async {
    final queryParams = <String, String>{};

    if (date != null) {
      queryParams['date'] = date;
    }

    return await ApiService.get<TicketStats>(
      '/qr/ticket-stats',
      TicketStats.fromJson,
      queryParams: queryParams,
    );
  }

  // Check QR code status
  static Future<ApiResponse<QRStatus>> checkQRStatus(int transactionId) async {
    return await ApiService.get<QRStatus>(
      '/qr/check-qr-status/$transactionId',
      QRStatus.fromJson,
    );
  }
}

class QRTicket {
  final String qrCodeImage;
  final String qrCodeData;
  final RideDetails rideDetails;
  final String instructions;

  QRTicket({
    required this.qrCodeImage,
    required this.qrCodeData,
    required this.rideDetails,
    required this.instructions,
  });

  factory QRTicket.fromJson(Map<String, dynamic> json) {
    return QRTicket(
      qrCodeImage: json['qrCodeImage'],
      qrCodeData: json['qrCodeData'],
      rideDetails: RideDetails.fromJson(json['rideDetails']),
      instructions: json['instructions'],
    );
  }
}

class RideDetails {
  final String origin;
  final String destination;
  final double amount;
  final String passengerName;
  final String mpesaCode;

  RideDetails({
    required this.origin,
    required this.destination,
    required this.amount,
    required this.passengerName,
    required this.mpesaCode,
  });

  factory RideDetails.fromJson(Map<String, dynamic> json) {
    return RideDetails(
      origin: json['origin'],
      destination: json['destination'],
      amount: (json['amount'] as num).toDouble(),
      passengerName: json['passengerName'],
      mpesaCode: json['mpesaCode'],
    );
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get routeText => '$origin → $destination';
}

class QRValidation {
  final String message;
  final ValidationDetails rideDetails;
  final String validatedBy;
  final String validatedAt;

  QRValidation({
    required this.message,
    required this.rideDetails,
    required this.validatedBy,
    required this.validatedAt,
  });

  factory QRValidation.fromJson(Map<String, dynamic> json) {
    return QRValidation(
      message: json['message'],
      rideDetails: ValidationDetails.fromJson(json['rideDetails']),
      validatedBy: json['validatedBy'],
      validatedAt: json['validatedAt'],
    );
  }
}

class ValidationDetails {
  final int transactionId;
  final String passengerName;
  final String passengerPhone;
  final String origin;
  final String destination;
  final double amount;
  final String validatedAt;

  ValidationDetails({
    required this.transactionId,
    required this.passengerName,
    required this.passengerPhone,
    required this.origin,
    required this.destination,
    required this.amount,
    required this.validatedAt,
  });

  factory ValidationDetails.fromJson(Map<String, dynamic> json) {
    return ValidationDetails(
      transactionId: json['transactionId'],
      passengerName: json['passengerName'],
      passengerPhone: json['passengerPhone'],
      origin: json['origin'],
      destination: json['destination'],
      amount: (json['amount'] as num).toDouble(),
      validatedAt: json['validatedAt'],
    );
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get routeText => '$origin → $destination';
}

class QRDetails {
  final bool used;
  final DateTime createdAt;
  final DateTime? scannedAt;
  final String passengerName;
  final String origin;
  final String destination;
  final double amount;

  QRDetails({
    required this.used,
    required this.createdAt,
    this.scannedAt,
    required this.passengerName,
    required this.origin,
    required this.destination,
    required this.amount,
  });

  factory QRDetails.fromJson(Map<String, dynamic> json) {
    return QRDetails(
      used: json['used'],
      createdAt: DateTime.parse(json['createdAt']),
      scannedAt: json['scannedAt'] != null 
          ? DateTime.parse(json['scannedAt'])
          : null,
      passengerName: json['passengerName'],
      origin: json['origin'],
      destination: json['destination'],
      amount: (json['amount'] as num).toDouble(),
    );
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get routeText => '$origin → $destination';
}

class ScannedTicket {
  final int id;
  final double amount;
  final String mpesaCode;
  final String origin;
  final String destination;
  final String passengerName;
  final String passengerPhone;
  final String scannerName;
  final DateTime scannedAt;

  ScannedTicket({
    required this.id,
    required this.amount,
    required this.mpesaCode,
    required this.origin,
    required this.destination,
    required this.passengerName,
    required this.passengerPhone,
    required this.scannerName,
    required this.scannedAt,
  });

  factory ScannedTicket.fromJson(Map<String, dynamic> json) {
    return ScannedTicket(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      mpesaCode: json['mpesa_code'],
      origin: json['origin'],
      destination: json['destination'],
      passengerName: json['passenger_name'],
      passengerPhone: json['passenger_phone'],
      scannerName: json['scanner_name'],
      scannedAt: DateTime.parse(json['scanned_at']),
    );
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get routeText => '$origin → $destination';
}

class TicketStats {
  final String date;
  final int totalTicketsScanned;
  final double totalRevenue;
  final List<HourlyBreakdown> hourlyBreakdown;
  final List<TopRoute> topRoutes;
  final String scannerName;

  TicketStats({
    required this.date,
    required this.totalTicketsScanned,
    required this.totalRevenue,
    required this.hourlyBreakdown,
    required this.topRoutes,
    required this.scannerName,
  });

  factory TicketStats.fromJson(Map<String, dynamic> json) {
    return TicketStats(
      date: json['date'],
      totalTicketsScanned: json['totalTicketsScanned'],
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      hourlyBreakdown: (json['hourlyBreakdown'] as List)
          .map((item) => HourlyBreakdown.fromJson(item))
          .toList(),
      topRoutes: (json['topRoutes'] as List)
          .map((item) => TopRoute.fromJson(item))
          .toList(),
      scannerName: json['scannerName'],
    );
  }

  String get formattedRevenue => 'KES ${totalRevenue.toStringAsFixed(2)}';
}

class HourlyBreakdown {
  final int hour;
  final int count;
  final double revenue;

  HourlyBreakdown({
    required this.hour,
    required this.count,
    required this.revenue,
  });

  factory HourlyBreakdown.fromJson(Map<String, dynamic> json) {
    return HourlyBreakdown(
      hour: json['hour'],
      count: json['count'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  String get formattedRevenue => 'KES ${revenue.toStringAsFixed(2)}';
  String get timeRange => '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00';
}

class TopRoute {
  final String route;
  final int ticketCount;
  final double revenue;

  TopRoute({
    required this.route,
    required this.ticketCount,
    required this.revenue,
  });

  factory TopRoute.fromJson(Map<String, dynamic> json) {
    return TopRoute(
      route: json['route'],
      ticketCount: json['ticket_count'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  String get formattedRevenue => 'KES ${revenue.toStringAsFixed(2)}';
}

class QRStatus {
  final int transactionId;
  final String qrCodeStatus;
  final bool isUsed;
  final DateTime? scannedAt;
  final String? scannedBy;
  final DateTime? qrCreatedAt;
  final String transactionStatus;

  QRStatus({
    required this.transactionId,
    required this.qrCodeStatus,
    required this.isUsed,
    this.scannedAt,
    this.scannedBy,
    this.qrCreatedAt,
    required this.transactionStatus,
  });

  factory QRStatus.fromJson(Map<String, dynamic> json) {
    return QRStatus(
      transactionId: json['transactionId'],
      qrCodeStatus: json['qrCodeStatus'],
      isUsed: json['isUsed'],
      scannedAt: json['scannedAt'] != null 
          ? DateTime.parse(json['scannedAt'])
          : null,
      scannedBy: json['scannedBy'],
      qrCreatedAt: json['qrCreatedAt'] != null 
          ? DateTime.parse(json['qrCreatedAt'])
          : null,
      transactionStatus: json['transactionStatus'],
    );
  }

  bool get isAvailable => qrCodeStatus == 'qr_available';
  bool get isPaymentNotCompleted => qrCodeStatus == 'payment_not_completed';
  bool get isQrNotGenerated => qrCodeStatus == 'qr_not_generated';
  bool get isQrUsed => qrCodeStatus == 'qr_used';
}