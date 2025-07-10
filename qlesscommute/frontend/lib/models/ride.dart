class Ride {
  final int id;
  final int userId;
  final String origin;
  final String destination;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final double distance;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? passengerName;
  final String? passengerPhone;
  final String? mpesaCode;
  final String? paymentStatus;

  Ride({
    required this.id,
    required this.userId,
    required this.origin,
    required this.destination,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.distance,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.passengerName,
    this.passengerPhone,
    this.mpesaCode,
    this.paymentStatus,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      userId: json['user_id'],
      origin: json['origin'],
      destination: json['destination'],
      originLat: (json['origin_lat'] as num).toDouble(),
      originLng: (json['origin_lng'] as num).toDouble(),
      destinationLat: (json['destination_lat'] as num).toDouble(),
      destinationLng: (json['destination_lng'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      passengerName: json['passenger_name'],
      passengerPhone: json['passenger_phone'],
      mpesaCode: json['mpesa_code'],
      paymentStatus: json['payment_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'origin': origin,
      'destination': destination,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'distance': distance,
      'amount': amount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'mpesa_code': mpesaCode,
      'payment_status': paymentStatus,
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isPaymentCompleted => paymentStatus == 'completed';
  bool get isPaymentPending => paymentStatus == 'pending';
  bool get isPaymentFailed => paymentStatus == 'failed';

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending Payment';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get formattedDistance => '${distance.toStringAsFixed(1)} km';

  Ride copyWith({
    int? id,
    int? userId,
    String? origin,
    String? destination,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    double? distance,
    double? amount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? passengerName,
    String? passengerPhone,
    String? mpesaCode,
    String? paymentStatus,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      distance: distance ?? this.distance,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      mpesaCode: mpesaCode ?? this.mpesaCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  @override
  String toString() {
    return 'Ride(id: $id, origin: $origin, destination: $destination, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ride && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}