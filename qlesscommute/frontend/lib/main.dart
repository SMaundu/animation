import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'models/user.dart';
import 'utils/theme.dart';
import 'utils/routes.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/fare_confirmation_screen.dart';
import 'screens/payment_status_screen.dart';
import 'screens/qr_code_screen.dart';
import 'screens/ticket_scan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ride_history_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/scan_history_screen.dart';

void main() {
  runApp(const QLessCommuteApp());
}

class QLessCommuteApp extends StatelessWidget {
  const QLessCommuteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'QLessCommute',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: Routes.splash,
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case Routes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case Routes.fareConfirmation:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _errorRoute('Fare confirmation data not provided');
        }
        return MaterialPageRoute(
          builder: (_) => FareConfirmationScreen(rideData: args),
        );

      case Routes.paymentStatus:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _errorRoute('Payment data not provided');
        }
        return MaterialPageRoute(
          builder: (_) => PaymentStatusScreen(paymentData: args),
        );

      case Routes.qrCode:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _errorRoute('QR code data not provided');
        }
        return MaterialPageRoute(
          builder: (_) => QRCodeScreen(ticketData: args),
        );

      case Routes.ticketScan:
        return MaterialPageRoute(
          builder: (_) => const TicketScanScreen(),
        );

      case Routes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case Routes.rideHistory:
        return MaterialPageRoute(
          builder: (_) => const RideHistoryScreen(),
        );

      case Routes.adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
        );

      case Routes.scanHistory:
        return MaterialPageRoute(
          builder: (_) => const ScanHistoryScreen(),
        );

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Navigation Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.splash,
                    (route) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Authentication Provider
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String phoneNumber, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await AuthService.login(phoneNumber, password);

      if (response.isSuccess) {
        _currentUser = response.data;
        notifyListeners();
        return true;
      } else {
        _setError(response.error);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String name,
    String phoneNumber,
    String password, {
    String role = 'passenger',
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await AuthService.register(
        name,
        phoneNumber,
        password,
        role: role,
      );

      if (response.isSuccess) {
        _currentUser = response.data;
        notifyListeners();
        return true;
      } else {
        _setError(response.error);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await AuthService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAuthStatus() async {
    _setLoading(true);

    try {
      final user = await AuthService.getCurrentUser();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Placeholder screens for routes that need basic implementation
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.splash,
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              user?.name ?? 'Unknown User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.phoneNumber ?? 'No phone number',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(user?.role.toUpperCase() ?? 'UNKNOWN'),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Ride History'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.of(context).pushNamed(Routes.rideHistory),
                    ),
                    if (user?.isConductor == true)
                      ListTile(
                        leading: const Icon(Icons.scanner),
                        title: const Text('Scan History'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => Navigator.of(context).pushNamed(Routes.scanHistory),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(Routes.profile),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Dashboard functionality coming soon...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Scan History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Scan history functionality coming soon...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}