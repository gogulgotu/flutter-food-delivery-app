import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Order Tracking Screen
/// 
/// Real-time order tracking with map view and status timeline
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _etaData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _loadETA();
  }

  Future<void> _loadOrderData() async {
    try {
      final data = await _apiService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _orderData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadETA() async {
    try {
      final data = await _apiService.getOrderETA(widget.orderId);
      if (mounted) {
        setState(() {
          _etaData = data;
        });
      }
    } catch (e) {
      // ETA might not be available, ignore error
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _orderData == null
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadOrderData();
                        await _loadETA();
                      },
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Status Card
                            _buildStatusCard(isDesktop, isTablet),
                            SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            
                            // ETA Card
                            if (_etaData != null) ...[
                              _buildETACard(isDesktop, isTablet),
                              SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            ],
                            
                            // Map View
                            _buildMapView(isDesktop, isTablet),
                            SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            
                            // Delivery Person Info
                            if (_hasDeliveryPerson()) _buildDeliveryPersonCard(isDesktop, isTablet),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading order',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrderData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Tracking unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDesktop, bool isTablet) {
    // Handle order_status as either int or string, prefer order_status_code
    String status = 'Unknown';
    if (_orderData!['order_status_code'] != null) {
      status = _orderData!['order_status_code'] as String;
    } else if (_orderData!['order_status'] != null) {
      final orderStatus = _orderData!['order_status'];
      if (orderStatus is String) {
        status = orderStatus;
      } else if (orderStatus is int) {
        // Use status_name if available, otherwise fallback
        status = _orderData!['order_status_name'] as String? ?? 'Unknown';
      }
    }
    final statusName = _orderData!['order_status_name'] as String? ?? status;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : isTablet ? 14 : 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_searching,
                color: AppTheme.primaryGreen,
                size: isDesktop ? 32 : isTablet ? 28 : 24,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : isTablet ? 14 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusName,
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildETACard(bool isDesktop, bool isTablet) {
    final etaMinutes = _etaData!['current_eta_minutes'] as int?;
    final estimatedTime = _etaData!['estimated_delivery_time'] as String?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Row(
          children: [
            Icon(Icons.timer, color: AppTheme.primaryGreen, size: isDesktop ? 32 : isTablet ? 28 : 24),
            SizedBox(width: isDesktop ? 16 : isTablet ? 14 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Delivery',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (etaMinutes != null)
                    Text(
                      'In $etaMinutes minutes',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  else if (estimatedTime != null)
                    Text(
                      _formatDateTime(estimatedTime),
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(bool isDesktop, bool isTablet) {
    final customerLat = _parseCoordinate(_orderData!['customer_latitude']);
    final customerLng = _parseCoordinate(_orderData!['customer_longitude']);
    final restaurantLat = _parseCoordinate(_orderData!['restaurant_latitude']);
    final restaurantLng = _parseCoordinate(_orderData!['restaurant_longitude']);
    
    // Delivery person location from ETA data
    LatLng? deliveryPersonLocation;
    if (_etaData != null) {
      final deliveryPersonLoc = _etaData!['delivery_person_location'] as Map<String, dynamic>?;
      if (deliveryPersonLoc != null) {
        final lat = _parseCoordinate(deliveryPersonLoc['latitude']);
        final lng = _parseCoordinate(deliveryPersonLoc['longitude']);
        if (lat != null && lng != null) {
          deliveryPersonLocation = LatLng(lat, lng);
        }
      }
    }

    // Determine center point
    LatLng? center;
    if (deliveryPersonLocation != null) {
      center = deliveryPersonLocation;
    } else if (customerLat != null && customerLng != null) {
      center = LatLng(customerLat, customerLng);
    } else if (restaurantLat != null && restaurantLng != null) {
      center = LatLng(restaurantLat, restaurantLng);
    }

    if (center == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: isTablet ? 300 : 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.bgGray,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 8),
                Text(
                  'Location data unavailable',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: isTablet ? 400 : isDesktop ? 450 : 300,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fooddelivery.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  // Customer location
                  if (customerLat != null && customerLng != null)
                    Marker(
                      point: LatLng(customerLat, customerLng),
                      width: 40,
                      height: 40,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.home, color: Colors.white, size: 20),
                      ),
                    ),
                  // Restaurant location
                  if (restaurantLat != null && restaurantLng != null)
                    Marker(
                      point: LatLng(restaurantLat, restaurantLng),
                      width: 40,
                      height: 40,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                      ),
                    ),
                  // Delivery person location
                  if (deliveryPersonLocation != null)
                    Marker(
                      point: deliveryPersonLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryPersonCard(bool isDesktop, bool isTablet) {
    final deliveryPersonName = _orderData!['delivery_person_name'] as String?;
    final deliveryPersonId = _orderData!['delivery_person'] as String?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : isTablet ? 14 : 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue,
                size: isDesktop ? 32 : isTablet ? 28 : 24,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : isTablet ? 14 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Partner',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deliveryPersonName ?? 'Assigned',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigation, color: AppTheme.primaryGreen),
              onPressed: () => _openGoogleMaps(),
              tooltip: 'Open in Google Maps',
            ),
          ],
        ),
      ),
    );
  }

  bool _hasDeliveryPerson() {
    return _orderData!['delivery_person'] != null;
  }

  Future<void> _openGoogleMaps() async {
    final customerLat = _parseCoordinate(_orderData!['customer_latitude']);
    final customerLng = _parseCoordinate(_orderData!['customer_longitude']);
    
    if (customerLat != null && customerLng != null) {
      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$customerLat,$customerLng');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return null;
      return double.tryParse(value);
    }
    return null;
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime.toLocal());
    } catch (e) {
      return dateTimeString;
    }
  }
}

