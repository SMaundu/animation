import '../models/ride.dart';
import '../models/transaction.dart';
import 'api_service.dart';

class RideService {
  // Estimate fare for a ride
  static Future<ApiResponse<FareEstimate>> estimateFare({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    required String origin,
    required String destination,
  }) async {
    return await ApiService.post<FareEstimate>(
      '/rides/estimate-fare',
      {
        'originLat': originLat,
        'originLng': originLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'origin': origin,
        'destination': destination,
      },
      FareEstimate.fromJson,
    );
  }

  // Book a ride
  static Future<ApiResponse<Ride>> bookRide({
    required String origin,
    required String destination,
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    return await ApiService.post<Ride>(
      '/rides/book-ride',
      {
        'origin': origin,
        'destination': destination,
        'originLat': originLat,
        'originLng': originLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
      },
      (data) => Ride.fromJson(data['ride']),
    );
  }

  // Get ride details
  static Future<ApiResponse<Ride>> getRideDetails(int rideId) async {
    return await ApiService.get<Ride>(
      '/rides/$rideId',
      (data) => Ride.fromJson(data['ride']),
    );
  }

  // Get user's ride history
  static Future<ApiResponse<List<Ride>>> getRideHistory(
    int userId, {
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

    return await ApiService.getList<Ride>(
      '/rides/user-rides/$userId',
      Ride.fromJson,
      'rides',
      queryParams: queryParams,
    );
  }

  // Cancel a ride
  static Future<ApiResponse<Map<String, dynamic>>> cancelRide(int rideId) async {
    return await ApiService.patch<Map<String, dynamic>>(
      '/rides/$rideId/cancel',
      {},
      (data) => data,
    );
  }

  // Get active ride for user
  static Future<ApiResponse<Ride?>> getActiveRide(int userId) async {
    final response = await getRideHistory(
      userId,
      limit: 1,
      status: 'pending',
    );

    if (response.isSuccess && response.data!.isNotEmpty) {
      return ApiResponse.success(response.data!.first);
    }

    return ApiResponse.success(null);
  }
}

class FareEstimate {
  final double distance;
  final double estimatedFare;
  final String origin;
  final String destination;
  final FareBreakdown breakdown;

  FareEstimate({
    required this.distance,
    required this.estimatedFare,
    required this.origin,
    required this.destination,
    required this.breakdown,
  });

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      distance: (json['distance'] as num).toDouble(),
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      origin: json['origin'],
      destination: json['destination'],
      breakdown: FareBreakdown.fromJson(json['breakdown']),
    );
  }

  String get formattedFare => 'KES ${estimatedFare.toStringAsFixed(2)}';
  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
}

class FareBreakdown {
  final double baseFare;
  final double distanceFare;
  final double totalFare;

  FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.totalFare,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    return FareBreakdown(
      baseFare: (json['baseFare'] as num).toDouble(),
      distanceFare: (json['distanceFare'] as num).toDouble(),
      totalFare: (json['totalFare'] as num).toDouble(),
    );
  }
}