import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../models/address_model.dart';
import '../../models/cart_model.dart';
import '../../theme/app_theme.dart';
import 'checkout_address_form.dart';

/// Checkout Step 1: Delivery Address & Location
/// 
/// Handles:
/// 1. Location collection (mandatory)
/// 2. Address selection/creation
/// 3. Address management (CRUD)
class CheckoutStep1AddressLocation extends StatefulWidget {
  final CartModel cart;
  final AddressModel? selectedAddress;
  final double? latitude;
  final double? longitude;
  final String? addressString;
  final Function({
    required AddressModel address,
    required double latitude,
    required double longitude,
    String? addressString,
  }) onComplete;
  final VoidCallback onBack;
  final bool isTablet;
  final bool isDesktop;

  const CheckoutStep1AddressLocation({
    super.key,
    required this.cart,
    this.selectedAddress,
    this.latitude,
    this.longitude,
    this.addressString,
    required this.onComplete,
    required this.onBack,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  State<CheckoutStep1AddressLocation> createState() => _CheckoutStep1AddressLocationState();
}

class _CheckoutStep1AddressLocationState extends State<CheckoutStep1AddressLocation> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  int _visibleAddressCount = 3; // Show 3 addresses initially, increment by 3 each time
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  bool _locationCollected = false;
  double? _latitude;
  double? _longitude;
  String? _addressString;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.selectedAddress;
    _latitude = widget.latitude;
    _longitude = widget.longitude;
    _addressString = widget.addressString;
    _locationCollected = _latitude != null && _longitude != null;
    
    // If we have coordinates but no address string, reverse geocode them
    if (_latitude != null && _longitude != null && _addressString == null) {
      _reverseGeocodeCoordinates(_latitude!, _longitude!);
    }
    
    _loadAddresses();
    _checkLocation();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getAddresses();
      final addresses = response
          .map((json) => AddressModel.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _addresses = addresses;
        
        // Auto-select default address or first address
        if (_selectedAddress == null) {
          _selectedAddress = addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => addresses.isNotEmpty ? addresses.first : AddressModel(
              id: 0,
              title: 'New Address',
              addressLine1: '',
              city: '',
              state: '',
              country: 'India',
              postalCode: '',
              isDefault: false,
            ),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('DioException [DioExceptionType.unknown]: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _checkLocation() async {
    // If location already collected, skip
    if (_locationCollected) return;

    // Wait 2 seconds before showing location modal (as per documentation)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted || _locationCollected) return;

    // Show location collection modal
    _showLocationCollectionDialog();
  }

  Future<void> _reverseGeocodeCoordinates(double latitude, double longitude) async {
    try {
      final address = await _locationService.getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      
      if (address != null && mounted) {
        setState(() {
          _addressString = address;
        });
      }
    } catch (e) {
      // Silent fail - we'll try again when displaying
      debugPrint('Error reverse geocoding: $e');
    }
  }

  Future<void> _showLocationCollectionDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LocationCollectionDialog(
        locationService: _locationService,
        apiService: _apiService,
        onLocationCollected: (latitude, longitude, address) {
          setState(() {
            _latitude = latitude;
            _longitude = longitude;
            _addressString = address;
            _locationCollected = true;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _collectLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      // Request permission and get location
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permission denied. Please enable location access in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage = 'Unable to get your location. Please try again.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get address from coordinates (reverse geocoding)
      String? address;
      try {
        address = await _locationService.getAddressFromCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (e) {
        debugPrint('⚠️ Reverse geocoding failed: $e');
        // Continue with null address - we'll show a fallback
      }

      // Save location to backend (even if address is null)
      try {
        await _apiService.saveLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
          accuracy: position.accuracy,
        );
      } catch (e) {
        debugPrint('⚠️ Error saving location: $e');
        // Continue anyway - location is still collected
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressString = address ?? 'Near ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _locationCollected = true;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error collecting location: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(
        builder: (context) => CheckoutAddressForm(
          isEditing: false,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadAddresses();
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  Future<void> _editAddress(AddressModel address) async {
    final result = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(
        builder: (context) => CheckoutAddressForm(
          address: address,
          isEditing: true,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadAddresses();
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    if (_addresses.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete. You must have at least one address.'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _apiService.deleteAddress(address.id);
        await _loadAddresses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: AppTheme.primaryGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting address: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _setDefaultAddress(AddressModel address) async {
    try {
      await _apiService.updateAddress(
        addressId: address.id,
        addressData: {'is_default': true},
      );
      await _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating address: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _proceedToPayment() {
    // Validate location
    if (!_locationCollected || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please collect your location first'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      _showLocationCollectionDialog();
      return;
    }

    // Validate address
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create an address'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Update address with coordinates if missing
    if (_selectedAddress!.latitude == null || _selectedAddress!.longitude == null) {
      _updateAddressWithCoordinates();
      return;
    }

    // Proceed to payment
    widget.onComplete(
      address: _selectedAddress!,
      latitude: _latitude!,
      longitude: _longitude!,
      addressString: _addressString,
    );
  }

  Future<void> _updateAddressWithCoordinates() async {
    try {
      final updatedAddress = await _apiService.updateAddress(
        addressId: _selectedAddress!.id,
        addressData: {
          'latitude': _latitude,
          'longitude': _longitude,
        },
      );

      final updated = AddressModel.fromJson(updatedAddress);
      setState(() {
        _selectedAddress = updated;
      });

      // Proceed to payment
      widget.onComplete(
        address: updated,
        latitude: _latitude!,
        longitude: _longitude!,
        addressString: _addressString,
      );
    } catch (e) {
      // Non-blocking: proceed anyway with coordinates in order payload
      widget.onComplete(
        address: _selectedAddress!,
        latitude: _latitude!,
        longitude: _longitude!,
        addressString: _addressString,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isDesktop ? 40 : widget.isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Indicator
          _buildStepIndicator(),
          const SizedBox(height: 32),

          // Location Section
          _buildLocationSection(),
          const SizedBox(height: 24),

          // Address Section
          _buildAddressSection(),
          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _locationCollected && _selectedAddress != null && !_isLoading
                  ? _proceedToPayment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: widget.isDesktop ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue to Payment',
                style: TextStyle(
                  fontSize: widget.isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: AppTheme.bgGray,
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.bgGray,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '2',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.bgGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Delivery Location',
                  style: TextStyle(
                    fontSize: widget.isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_locationCollected && _latitude != null && _longitude != null) ...[
              // Always try to show address format via reverse geocoding
              FutureBuilder<String?>(
                future: _addressString != null 
                    ? Future.value(_addressString)
                    : _locationService.getAddressFromCoordinates(
                        latitude: _latitude!,
                        longitude: _longitude!,
                      ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Loading address...',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    );
                  }

                  // Always prefer address format over coordinates
                  String displayAddress;
                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                    displayAddress = snapshot.data!;
                    // Update address string if we got it from reverse geocoding
                    if (_addressString != snapshot.data) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _addressString = snapshot.data;
                          });
                        }
                      });
                    }
                  } else if (_addressString != null && _addressString!.isNotEmpty) {
                    displayAddress = _addressString!;
                  } else {
                    // Fallback: show loading while we try to get address
                    displayAddress = 'Getting address...';
                    // Trigger another reverse geocoding attempt
                    _reverseGeocodeCoordinates(_latitude!, _longitude!);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Display
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // OpenStreetMap Map View
                      _buildMapView(),
                      
                      const SizedBox(height: 16),
                      
                      // Update Location Button
                      TextButton.icon(
                        onPressed: _collectLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Update Location'),
                      ),
                    ],
                  );
                },
              ),
            ] else ...[
              if (_isLoadingLocation)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text(
                  'Location is required for delivery. Please collect your location.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _collectLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Get My Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_latitude == null || _longitude == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final mapHeight = isTablet ? 300.0 : 250.0;

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bgGray),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(_latitude!, _longitude!),
            initialZoom: 15.0,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fooddelivery.app',
              maxZoom: 19,
            ),
            // Marker for delivery location
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(_latitude!, _longitude!),
                  width: 50,
                  height: 50,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.bgGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: widget.isDesktop ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _addNewAddress,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_addresses.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No addresses saved',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _addNewAddress,
                      child: const Text('Add Your First Address'),
                    ),
                  ],
                ),
              )
            else ...[
              // Show addresses up to _visibleAddressCount (starts at 3, increases by 3 each time)
              ..._addresses.take(_visibleAddressCount).map((address) => _buildAddressCard(address)),
              
              // Show More button if there are more addresses to display
              if (_visibleAddressCount < _addresses.length)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          // Show 3 more items (increment by 3)
                          _visibleAddressCount += 3;
                          // Don't exceed total count
                          if (_visibleAddressCount > _addresses.length) {
                            _visibleAddressCount = _addresses.length;
                          }
                        });
                      },
                      icon: const Icon(
                        Icons.expand_more,
                        color: AppTheme.primaryGreen,
                      ),
                      label: Text(
                        'Show More (${(_addresses.length - _visibleAddressCount).clamp(0, _addresses.length)} more)',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    final isSelected = _selectedAddress?.id == address.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.bgGray,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<AddressModel>(
        value: address,
        groupValue: _selectedAddress,
        onChanged: (value) {
          setState(() {
            _selectedAddress = value;
          });
        },
        title: Row(
          children: [
            Text(
              address.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.isDesktop ? 16 : 14,
              ),
            ),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.fullAddress,
                style: TextStyle(
                  fontSize: widget.isDesktop ? 14 : 12,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (address.latitude == null || address.longitude == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '⚠️ Location coordinates missing',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        secondary: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editAddress(address);
                break;
              case 'delete':
                _deleteAddress(address);
                break;
              case 'default':
                if (!address.isDefault) {
                  _setDefaultAddress(address);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!address.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Set as Default'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppTheme.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppTheme.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location Collection Dialog
class _LocationCollectionDialog extends StatefulWidget {
  final LocationService locationService;
  final ApiService apiService;
  final Function(double latitude, double longitude, String? address) onLocationCollected;

  const _LocationCollectionDialog({
    required this.locationService,
    required this.apiService,
    required this.onLocationCollected,
  });

  @override
  State<_LocationCollectionDialog> createState() => _LocationCollectionDialogState();
}

class _LocationCollectionDialogState extends State<_LocationCollectionDialog> {
  bool _isLoading = true;
  bool _locationCollected = false;
  double? _latitude;
  double? _longitude;
  String? _addressString;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _collectLocation();
  }

  Future<void> _collectLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request permission
      final hasPermission = await widget.locationService.requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permission denied. Please enable location access.';
          _isLoading = false;
        });
        return;
      }

      // Get location
      final position = await widget.locationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage = 'Unable to get your location. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Get address
      final address = await widget.locationService.getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Save to backend
      await widget.apiService.saveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressString = address;
        _locationCollected = true;
        _isLoading = false;
      });

      // Auto-close after 1 second
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _locationCollected) {
        widget.onLocationCollected(_latitude!, _longitude!, _addressString);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Collecting Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_locationCollected) ...[
            const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 48),
            const SizedBox(height: 16),
            Text(
              'Location collected successfully!',
              style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
            ),
            if (_addressString != null) ...[
              const SizedBox(height: 8),
              Text(_addressString!, style: const TextStyle(fontSize: 12)),
            ],
          ] else ...[
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to collect location',
              style: const TextStyle(color: AppTheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _collectLocation,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isLoading && !_locationCollected)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}

