class Transaction {
  final int id;
  final int userId;
  final int rideId;
  final String? mpesaCode;
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final double amount;
  final String phone;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? origin;
  final String? destination;

  Transaction({
    required this.id,
    required this.userId,
    required this.rideId,
    this.mpesaCode,
    this.checkoutRequestId,
    this.merchantRequestId,
    required this.amount,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.origin,
    this.destination,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      rideId: json['ride_id'],
      mpesaCode: json['mpesa_code'],
      checkoutRequestId: json['checkout_request_id'],
      merchantRequestId: json['merchant_request_id'],
      amount: (json['amount'] as num).toDouble(),
      phone: json['phone'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      origin: json['origin'],
      destination: json['destination'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ride_id': rideId,
      'mpesa_code': mpesaCode,
      'checkout_request_id': checkoutRequestId,
      'merchant_request_id': merchantRequestId,
      'amount': amount,
      'phone': phone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'origin': origin,
      'destination': destination,
    };
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

  String get routeText {
    if (origin != null && destination != null) {
      return '$origin → $destination';
    }
    return 'Unknown Route';
  }

  Transaction copyWith({
    int? id,
    int? userId,
    int? rideId,
    String? mpesaCode,
    String? checkoutRequestId,
    String? merchantRequestId,
    double? amount,
    String? phone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? origin,
    String? destination,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rideId: rideId ?? this.rideId,
      mpesaCode: mpesaCode ?? this.mpesaCode,
      checkoutRequestId: checkoutRequestId ?? this.checkoutRequestId,
      merchantRequestId: merchantRequestId ?? this.merchantRequestId,
      amount: amount ?? this.amount,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, status: $status, mpesaCode: $mpesaCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}