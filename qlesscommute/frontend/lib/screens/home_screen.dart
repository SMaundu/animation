import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/ride_service.dart';
import '../utils/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  LatLng? _originLocation;
  LatLng? _destinationLocation;
  String _originAddress = '';
  String _destinationAddress = '';
  bool _isLoading = false;
  bool _selectingDestination = false;
  FareEstimate? _fareEstimate;

  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-1.2921, 36.8219), // Nairobi, Kenya
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));

    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      if (_mapController != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get current location');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position, bool isOrigin) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}';

        setState(() {
          if (isOrigin) {
            _originAddress = address;
          } else {
            _destinationAddress = address;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get address');
    }
  }

  void _onMapTap(LatLng position) {
    if (_selectingDestination) {
      setState(() {
        _destinationLocation = position;
        _selectingDestination = false;
      });
      _updateMarkers();
      _getAddressFromLatLng(position, false);
      _estimateFare();
    } else {
      setState(() {
        _originLocation = position;
      });
      _updateMarkers();
      _getAddressFromLatLng(position, true);
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();

      if (_originLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: _originLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Origin',
              snippet: _originAddress,
            ),
          ),
        );
      }

      if (_destinationLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: _destinationAddress,
            ),
          ),
        );
      }
    });
  }

  Future<void> _estimateFare() async {
    if (_originLocation == null || _destinationLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    final response = await RideService.estimateFare(
      originLat: _originLocation!.latitude,
      originLng: _originLocation!.longitude,
      destinationLat: _destinationLocation!.latitude,
      destinationLng: _destinationLocation!.longitude,
      origin: _originAddress,
      destination: _destinationAddress,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.isSuccess) {
      setState(() {
        _fareEstimate = response.data;
      });
      _showFareEstimate();
    } else {
      _showErrorSnackBar(response.error);
    }
  }

  void _showFareEstimate() {
    if (_fareEstimate == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFareEstimateSheet(),
    );
  }

  Widget _buildFareEstimateSheet() {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calculate,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare Estimate',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Distance: ${_fareEstimate!.formattedDistance}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Route
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildRouteItem(
                  Icons.trip_origin,
                  'From',
                  _fareEstimate!.origin,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                _buildRouteItem(
                  Icons.location_on,
                  'To',
                  _fareEstimate!.destination,
                  Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fare breakdown
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
                _buildFareRow(
                  'Base Fare',
                  'KES ${_fareEstimate!.breakdown.baseFare.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildFareRow(
                  'Distance Fare',
                  'KES ${_fareEstimate!.breakdown.distanceFare.toStringAsFixed(2)}',
                ),
                const Divider(),
                _buildFareRow(
                  'Total',
                  _fareEstimate!.formattedFare,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Book ride button
          ElevatedButton(
            onPressed: _bookRide,
            child: const Text('Book This Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteItem(IconData icon, String label, String address, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                address,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareRow(String label, String amount, {bool isTotal = false}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _bookRide() async {
    Navigator.of(context).pop(); // Close bottom sheet

    if (_originLocation == null || _destinationLocation == null) return;

    Navigator.of(context).pushNamed(
      Routes.fareConfirmation,
      arguments: {
        'origin': _originAddress,
        'destination': _destinationAddress,
        'originLat': _originLocation!.latitude,
        'originLng': _originLocation!.longitude,
        'destinationLat': _destinationLocation!.latitude,
        'destinationLng': _destinationLocation!.longitude,
        'fareEstimate': _fareEstimate,
      },
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to show your current location and help you book rides.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QLessCommute'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed(Routes.rideHistory),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).pushNamed(Routes.profile),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  ),
                );
              }
            },
            initialCameraPosition: _initialPosition,
            onTap: _onMapTap,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // Top instruction panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectingDestination
                        ? 'Tap to select destination'
                        : 'Tap to select pickup location',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_originAddress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.trip_origin,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _originAddress,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_destinationAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _destinationAddress,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ScaleTransition(
              scale: _fabAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_originLocation != null && !_selectingDestination) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectingDestination = true;
                          });
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('Select Destination'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  Row(
                    children: [
                      // My location button
                      FloatingActionButton(
                        heroTag: "location",
                        onPressed: _getCurrentLocation,
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.primary,
                        mini: true,
                        child: const Icon(Icons.my_location),
                      ),
                      const Spacer(),
                      
                      // Clear markers button
                      if (_markers.isNotEmpty)
                        FloatingActionButton(
                          heroTag: "clear",
                          onPressed: () {
                            setState(() {
                              _markers.clear();
                              _originLocation = null;
                              _destinationLocation = null;
                              _originAddress = '';
                              _destinationAddress = '';
                              _selectingDestination = false;
                              _fareEstimate = null;
                            });
                          },
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          mini: true,
                          child: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}