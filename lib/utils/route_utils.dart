import '../models/user_model.dart';

/// Route Utilities
/// 
/// Helper functions for role-based routing
class RouteUtils {
  /// Get the appropriate dashboard route based on user role
  static String getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '/customer-dashboard';
      case UserRole.vendor:
        return '/vendor-dashboard';
      case UserRole.deliveryPerson:
        return '/delivery-dashboard';
    }
  }

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    const protectedRoutes = [
      '/customer-dashboard',
      '/vendor-dashboard',
      '/delivery-dashboard',
      '/profile',
      '/orders',
      '/settings',
    ];
    return protectedRoutes.contains(route);
  }

  /// Check if route is accessible by role
  static bool isRouteAccessible(String route, UserRole role) {
    switch (route) {
      case '/customer-dashboard':
        return role == UserRole.customer;
      case '/vendor-dashboard':
        return role == UserRole.vendor;
      case '/delivery-dashboard':
        return role == UserRole.deliveryPerson;
      default:
        return true;
    }
  }
}

