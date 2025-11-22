import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'auth/phone_number_screen.dart';
import 'auth/location_collection_screen.dart';
import 'customer/customer_dashboard_screen.dart';
import 'vendor/vendor_dashboard_screen.dart';
import 'delivery/delivery_dashboard_screen.dart';

/// Splash Screen
/// 
/// Initial screen that checks authentication status and routes accordingly
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Initialize auth state from storage
      await authProvider.initialize();

      if (!mounted) return;

      // Wait a bit for splash screen visibility
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate based on authentication status
      if (authProvider.isAuthenticated && authProvider.user != null) {
        final user = authProvider.user!;
        
        // Check if user has location
        if (user.latitude == null || user.longitude == null) {
          // Navigate to location collection screen if location is missing
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LocationCollectionScreen(user: user),
            ),
          );
        } else {
          // User is logged in with location, navigate to appropriate dashboard
          _navigateToDashboard(user.role);
        }
      } else {
        // User is not logged in, navigate to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
        );
      }
    } catch (e, stackTrace) {
      // Log error and navigate to login screen as fallback
      debugPrint('Error initializing app: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      // Navigate to login screen on error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
      );
    }
  }

  void _navigateToDashboard(UserRole role) {
    Widget dashboard;
    switch (role) {
      case UserRole.customer:
        dashboard = const CustomerDashboardScreen();
        break;
      case UserRole.vendor:
        dashboard = const VendorDashboardScreen();
        break;
      case UserRole.deliveryPerson:
        dashboard = const DeliveryDashboardScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Icon(
              Icons.restaurant_menu,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'FRESH KART',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

