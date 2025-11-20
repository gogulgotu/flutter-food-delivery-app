import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/route_utils.dart';
import 'auth/phone_number_screen.dart';
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Initialize auth state from storage
    await authProvider.initialize();

    if (!mounted) return;

    // Wait a bit for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigate based on authentication status
    if (authProvider.isAuthenticated && authProvider.user != null) {
      // User is logged in, navigate to appropriate dashboard
      _navigateToDashboard(authProvider.user!.role);
    } else {
      // User is not logged in, navigate to login
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
              'Food Delivery',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

