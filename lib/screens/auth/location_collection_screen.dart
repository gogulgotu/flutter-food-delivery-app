import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../customer/customer_dashboard_screen.dart';
import '../vendor/vendor_dashboard_screen.dart';
import '../delivery/delivery_dashboard_screen.dart';
import 'dart:async';

/// Location Collection Screen
/// 
/// Required screen after login to collect user's location
/// This screen cannot be dismissed until location is collected
/// Can also be used for editing existing location
class LocationCollectionScreen extends StatefulWidget {
  final UserModel user;
  final bool isEditing; // If true, allows back navigation

  const LocationCollectionScreen({
    super.key,
    required this.user,
    this.isEditing = false,
  });

  @override
  State<LocationCollectionScreen> createState() => _LocationCollectionScreenState();
}

class _LocationCollectionScreenState extends State<LocationCollectionScreen> {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  bool _locationCollected = false;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  String? _address;

  @override
  void initState() {
    super.initState();
    // Auto-request location on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocation();
    });
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        // Get address from coordinates (reverse geocoding)
        final address = await _locationService.getAddressFromCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // If address is null, try to get it again or use a formatted fallback
        String? displayAddress = address;
        if (displayAddress == null || displayAddress.isEmpty) {
          // Retry reverse geocoding once
          displayAddress = await _locationService.getAddressFromCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          
          // If still null, create a descriptive fallback
          if (displayAddress == null || displayAddress.isEmpty) {
            displayAddress = 'Near ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          }
        }

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _address = displayAddress;
          _locationCollected = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to get your location. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLocationAndContinue() async {
    if (!_locationCollected || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please collect your location first'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update user model with location
      final updatedUser = widget.user.copyWith(
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
      );

      // Save to storage
      await StorageService().saveUserData(updatedUser);

      // Update auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateUser(updatedUser);

      if (!mounted) return;

      if (widget.isEditing) {
        // If editing, just go back
        Navigator.of(context).pop(updatedUser);
      } else {
        // Navigate to dashboard based on role
        _navigateToDashboard(updatedUser.role);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error saving location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToDashboard(UserRole role) {
    // Import dashboards here to avoid circular dependencies
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return PopScope(
      canPop: widget.isEditing, // Allow back if editing
      child: Scaffold(
        backgroundColor: AppTheme.bgWhite,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 40 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 60,
                    color: AppTheme.primaryGreen,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Location Required',
                  style: TextStyle(
                    fontSize: isTablet ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'We need your location to deliver orders and show nearby restaurants. Your location will be used only for delivery purposes.',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Location Info Card
                if (_locationCollected && _address != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLightGray,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Location Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _address!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Loading Indicator
                if (_isLoading && !_locationCollected)
                  Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Getting your location...',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error Message
                if (_errorMessage != null && !_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Action Buttons
                if (!_isLoading) ...[
                  // Retry Button (if error or not collected)
                  if (!_locationCollected)
                    ElevatedButton(
                      onPressed: _requestLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get My Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Continue Button (when location collected)
                  if (_locationCollected)
                    ElevatedButton(
                      onPressed: _saveLocationAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

