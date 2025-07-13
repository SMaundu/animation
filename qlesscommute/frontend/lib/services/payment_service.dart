import '../models/transaction.dart';
import 'api_service.dart';

class PaymentService {
  // Initiate M-Pesa payment
  static Future<ApiResponse<PaymentInitiation>> initiatePayment({
    required int rideId,
    required String phoneNumber,
  }) async {
    return await ApiService.post<PaymentInitiation>(
      '/payments/initiate-payment',
      {
        'rideId': rideId,
        'phoneNumber': phoneNumber,
      },
      PaymentInitiation.fromJson,
    );
  }

  // Check payment status
  static Future<ApiResponse<PaymentStatus>> getPaymentStatus(int transactionId) async {
    return await ApiService.get<PaymentStatus>(
      '/payments/payment-status/$transactionId',
      PaymentStatus.fromJson,
    );
  }

  // Get user's transaction history
  static Future<ApiResponse<List<Transaction>>> getTransactionHistory({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) {
      queryParams['status'] = status;
    }

    return await ApiService.getList<Transaction>(
      '/payments/transactions',
      Transaction.fromJson,
      'transactions',
      queryParams: queryParams,
    );
  }

  // Retry failed payment
  static Future<ApiResponse<PaymentInitiation>> retryPayment({
    required int transactionId,
    required String phoneNumber,
  }) async {
    return await ApiService.post<PaymentInitiation>(
      '/payments/retry-payment/$transactionId',
      {
        'phoneNumber': phoneNumber,
      },
      PaymentInitiation.fromJson,
    );
  }

  // Poll payment status until completion or timeout
  static Future<ApiResponse<PaymentStatus>> pollPaymentStatus(
    int transactionId, {
    Duration timeout = const Duration(minutes: 5),
    Duration interval = const Duration(seconds: 3),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      final response = await getPaymentStatus(transactionId);

      if (response.isError) {
        return response;
      }

      final status = response.data!;
      if (status.status == 'completed' || status.status == 'failed' || status.status == 'cancelled') {
        return response;
      }

      await Future.delayed(interval);
    }

    return ApiResponse.error('Payment verification timeout', 408);
  }

  // Format phone number for M-Pesa
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Convert to international format
    if (phone.startsWith('0')) {
      return '254${phone.substring(1)}';
    } else if (phone.startsWith('254')) {
      return phone;
    } else if (phone.length == 9) {
      return '254$phone';
    }
    
    return phone;
  }

  // Validate phone number
  static bool isValidPhoneNumber(String phone) {
    final formatted = formatPhoneNumber(phone);
    final phoneRegex = RegExp(r'^254[7-9]\d{8}$');
    return phoneRegex.hasMatch(formatted);
  }
}

class PaymentInitiation {
  final int transactionId;
  final String checkoutRequestId;
  final String merchantRequestId;
  final double amount;
  final String phoneNumber;
  final String instructions;

  PaymentInitiation({
    required this.transactionId,
    required this.checkoutRequestId,
    required this.merchantRequestId,
    required this.amount,
    required this.phoneNumber,
    required this.instructions,
  });

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) {
    return PaymentInitiation(
      transactionId: json['transactionId'],
      checkoutRequestId: json['checkoutRequestId'],
      merchantRequestId: json['merchantRequestId'],
      amount: (json['amount'] as num).toDouble(),
      phoneNumber: json['phoneNumber'],
      instructions: json['instructions'],
    );
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
}

class PaymentStatus {
  final int transactionId;
  final int rideId;
  final double amount;
  final String status;
  final String? mpesaCode;
  final String phoneNumber;
  final String origin;
  final String destination;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentStatus({
    required this.transactionId,
    required this.rideId,
    required this.amount,
    required this.status,
    this.mpesaCode,
    required this.phoneNumber,
    required this.origin,
    required this.destination,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      transactionId: json['transactionId'],
      rideId: json['rideId'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      mpesaCode: json['mpesaCode'],
      phoneNumber: json['phoneNumber'],
      origin: json['origin'],
      destination: json['destination'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Processing Payment';
      case 'completed':
        return 'Payment Successful';
      case 'failed':
        return 'Payment Failed';
      case 'cancelled':
        return 'Payment Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get routeText => '$origin → $destination';
}