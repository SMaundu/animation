import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/fare_confirmation_screen.dart';
import 'screens/qr_code_screen.dart';
import 'screens/ticket_scan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ride_history_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'utils/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request permissions
  await _requestPermissions();
  
  runApp(const QLessCommuteApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.location,
    Permission.camera,
    Permission.phone,
  ].request();
}

class QLessCommuteApp extends StatelessWidget {
  const QLessCommuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'QLessCommute',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: Routes.splash,
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case Routes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case Routes.fareConfirmation:
        final args = settings.arguments as FareConfirmationArgs?;
        return MaterialPageRoute(
          builder: (_) => FareConfirmationScreen(
            rideDetails: args?.rideDetails,
          ),
        );
      
      case Routes.qrCode:
        final args = settings.arguments as QRCodeArgs?;
        return MaterialPageRoute(
          builder: (_) => QRCodeScreen(
            transactionId: args?.transactionId ?? 0,
          ),
        );
      
      case Routes.ticketScan:
        return MaterialPageRoute(builder: (_) => const TicketScanScreen());
      
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case Routes.rideHistory:
        return MaterialPageRoute(builder: (_) => const RideHistoryScreen());
      
      case Routes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
}

// Providers
class AuthProvider extends ChangeNotifier {
  AuthStatus _authStatus = AuthStatus.loading;
  User? _currentUser;
  String? _error;

  AuthStatus get authStatus => _authStatus;
  User? get currentUser => _currentUser;
  String? get error => _error;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  bool get isLoading => _authStatus == AuthStatus.loading;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _authStatus = AuthStatus.loading;
    notifyListeners();

    try {
      final status = await AuthService.checkAuthStatus();
      _authStatus = status;
      
      if (status == AuthStatus.authenticated) {
        _currentUser = await AuthService.getCurrentUser();
      }
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _error = e.toString();
    }
    
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _error = null;
    notifyListeners();

    final response = await AuthService.login(
      phone: phone,
      password: password,
    );

    if (response.isSuccess && response.data != null) {
      _currentUser = response.data!.user;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String phone, String password, {String role = 'passenger'}) async {
    _error = null;
    notifyListeners();

    final response = await AuthService.register(
      name: name,
      phone: phone,
      password: password,
      role: role,
    );

    if (response.isSuccess && response.data != null) {
      _currentUser = response.data!.user;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _currentUser = null;
    _authStatus = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

class RideProvider extends ChangeNotifier {
  Ride? _currentRide;
  List<Ride> _rideHistory = [];
  bool _isLoading = false;
  String? _error;

  Ride? get currentRide => _currentRide;
  List<Ride> get rideHistory => _rideHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentRide(Ride? ride) {
    _currentRide = ride;
    notifyListeners();
  }

  void setRideHistory(List<Ride> rides) {
    _rideHistory = rides;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class PaymentProvider extends ChangeNotifier {
  bool _isProcessing = false;
  String? _error;
  String? _transactionId;

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get transactionId => _transactionId;

  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setTransactionId(String? id) {
    _transactionId = id;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Route arguments
class FareConfirmationArgs {
  final Map<String, dynamic>? rideDetails;
  
  FareConfirmationArgs(this.rideDetails);
}

class QRCodeArgs {
  final int transactionId;
  
  QRCodeArgs(this.transactionId);
}

// Import the models (these would be in separate files)
class User {
  final int id;
  final String name;
  final String phone;
  final String role;
  
  User({required this.id, required this.name, required this.phone, required this.role});
}

class Ride {
  final int id;
  final String origin;
  final String destination;
  final double amount;
  final String status;
  
  Ride({required this.id, required this.origin, required this.destination, required this.amount, required this.status});
}