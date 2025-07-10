class Routes {
  // Authentication routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main app routes
  static const String home = '/home';
  static const String fareConfirmation = '/fare-confirmation';
  static const String qrCode = '/qr-code';
  static const String ticketScan = '/ticket-scan';
  static const String profile = '/profile';
  static const String rideHistory = '/ride-history';

  // Admin routes
  static const String adminDashboard = '/admin-dashboard';

  // Settings routes
  static const String settings = '/settings';
  static const String about = '/about';
  static const String help = '/help';

  // Utility methods
  static bool isAuthRoute(String route) {
    return [splash, login, register].contains(route);
  }

  static bool isMainAppRoute(String route) {
    return [
      home,
      fareConfirmation,
      qrCode,
      ticketScan,
      profile,
      rideHistory,
    ].contains(route);
  }

  static bool isAdminRoute(String route) {
    return route == adminDashboard;
  }

  static String getInitialRoute({required bool isLoggedIn, String? userRole}) {
    if (!isLoggedIn) {
      return splash;
    }

    if (userRole == 'admin') {
      return adminDashboard;
    } else if (userRole == 'conductor') {
      return ticketScan;
    } else {
      return home;
    }
  }
}