import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/address_model.dart';
import '../../models/cart_model.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checkout Step 2: Payment Method
/// 
/// Handles:
/// 1. Payment method selection (COD, Paytm)
/// 2. Meat order scheduling (Saturday/Sunday, 6-8 AM)
/// 3. Order creation
/// 4. Payment processing
class CheckoutStep2Payment extends StatefulWidget {
  final CartModel cart;
  final AddressModel address;
  final double latitude;
  final double longitude;
  final Function(Map<String, dynamic> orderData) onOrderCreated;
  final VoidCallback onBack;
  final bool isTablet;
  final bool isDesktop;

  const CheckoutStep2Payment({
    super.key,
    required this.cart,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.onOrderCreated,
    required this.onBack,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  State<CheckoutStep2Payment> createState() => _CheckoutStep2PaymentState();
}

class _CheckoutStep2PaymentState extends State<CheckoutStep2Payment> {
  final ApiService _apiService = ApiService();
  
  String _selectedPaymentMethod = 'cod'; // 'cod' or 'paytm'
  bool _isScheduling = false;
  DateTime? _scheduledDeliveryTime;
  bool _isCreatingOrder = false;
  bool _hasMeatProducts = false;

  @override
  void initState() {
    super.initState();
    _checkForMeatProducts();
  }

  void _checkForMeatProducts() {
    // Check if cart has meat products
    // In a real app, this would check product categories or tags
    final hasMeat = widget.cart.items.any((item) {
      final productName = item.product.name.toLowerCase();
      return productName.contains('chicken') || 
             productName.contains('meat') || 
             productName.contains('mutton') ||
             productName.contains('fish');
    });

    setState(() {
      _hasMeatProducts = hasMeat;
    });

    // If meat products found, show scheduling requirement
    if (hasMeat) {
      _showMeatSchedulingDialog();
    }
  }

  Future<void> _showMeatSchedulingDialog() async {
    final result = await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MeatSchedulingDialog(),
    );

    if (result != null) {
      setState(() {
        _scheduledDeliveryTime = result;
        _isScheduling = true;
      });
    }
  }

  /// Format coordinate to meet backend's constraint (max 7 decimal places)
  /// Backend requires max 7 decimal places for latitude/longitude
  /// Examples:
  /// - 11.100734709999996 → "11.1007347" (7 decimal places)
  /// - 77.34803770999997 → "77.3480377" (7 decimal places)
  String _formatCoordinate(double value) {
    // Format to exactly 7 decimal places as required by backend
    return value.toStringAsFixed(7);
  }

  Future<void> _placeOrder() async {
    if (_hasMeatProducts && _scheduledDeliveryTime == null) {
      await _showMeatSchedulingDialog();
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      // Build order payload according to API documentation
      // All prices sent as strings to avoid floating point issues
      final orderData = <String, dynamic>{
        // Required fields (per API documentation)
        'vendor': widget.cart.vendor.id.toString(),
        'delivery_address': widget.address.id,
        'items': widget.cart.items.map((item) {
          // Ensure unitPrice is a valid double and format to 2 decimal places
          // Handle case where unitPrice might be different types
          double priceValue;
          if (item.unitPrice is double) {
            priceValue = item.unitPrice as double;
          } else if (item.unitPrice is num) {
            priceValue = (item.unitPrice as num).toDouble();
          } else {
            // Fallback: try to parse as string
            priceValue = double.tryParse(item.unitPrice.toString()) ?? 0.0;
          }
          
          final priceString = priceValue.toStringAsFixed(2);
          
          debugPrint('📦 Item price: ${item.unitPrice} (${item.unitPrice.runtimeType}) → $priceString');
          
          return <String, dynamic>{
            'product': item.product.id.toString(),
            'quantity': item.quantity,
            'price': priceString, // Price as string with 2 decimal places
            if (item.variantId != null && item.variantId!.isNotEmpty) 
              'variant': item.variantId.toString(),
          };
        }).toList(),
        'subtotal': widget.cart.subtotal.toStringAsFixed(2),
        'delivery_fee': widget.cart.deliveryFee.toStringAsFixed(2),
        'total_amount': widget.cart.total.toStringAsFixed(2),
        
        // Optional fields
        'payment_method': _selectedPaymentMethod, // 'cod' or 'paytm' (default: 'pending' if not set)
        'payment_status': 'pending',
        'service_fee': '0.00',
        'tax_amount': widget.cart.tax.toStringAsFixed(2),
        'discount_amount': '0.00',
        
        // Location coordinates (as strings per API docs)
        // Format to meet backend's max_digits constraint (10 digits total)
        'customer_latitude': _formatCoordinate(widget.latitude),
        'customer_longitude': _formatCoordinate(widget.longitude),
        
        // Scheduled delivery time (required for meat orders)
        if (_scheduledDeliveryTime != null)
          'scheduled_delivery_time': _scheduledDeliveryTime!.toIso8601String(),
      };

      debugPrint('📦 Creating order with data: $orderData');

      // Create order
      final orderResponse = await _apiService.createOrder(orderData);
      
      if (!mounted) return;

      debugPrint('✅ Order created: ${orderResponse['order_number'] ?? orderResponse['id']}');

      // Handle payment based on method
      if (_selectedPaymentMethod == 'paytm') {
        await _processPaytmPayment(orderResponse['id'] as String);
      } else {
        // COD - Order created successfully
        await _handleOrderSuccess(orderResponse);
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isCreatingOrder = false;
      });
      
      // Check if error requires location
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      final requiresLocation = (e is Exception && 
          (e.toString().contains('requires_location') || 
           e.toString().contains('Location required') ||
           e.toString().contains('GPS')));
      
      debugPrint('❌ Order creation error: $errorMessage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requiresLocation
                ? 'Location required. Please enable GPS and try again.'
                : 'Error creating order: $errorMessage',
          ),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
          action: requiresLocation
              ? SnackBarAction(
                  label: 'COLLECT LOCATION',
                  textColor: Colors.white,
                  onPressed: () {
                    // Navigate back to step 1 to collect location
                    widget.onBack();
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _processPaytmPayment(String orderId) async {
    try {
      debugPrint('💳 Creating Paytm payment order for: $orderId');
      
      // Create Paytm order
      final paytmResponse = await _apiService.createPaytmOrder(orderId);
      
      if (!mounted) return;

      debugPrint('✅ Paytm order created: ${paytmResponse['paytm_order_id']}');

      // Extract Paytm parameters
      final paytmParams = paytmResponse['paytm_params'] as Map<String, dynamic>;
      final paytmUrl = paytmResponse['paytm_url'] as String;

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to Paytm payment gateway...'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Open Paytm payment page
      await _openPaytmPaymentPage(paytmUrl, paytmParams);
      
      // Clear cart after successful order creation (payment will be verified later)
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.clearCart();
      
      // Navigate to home after showing payment page
      // Note: Payment verification should happen in callback URL
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
        });
        
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        debugPrint('❌ Error initiating Paytm payment: $errorMessage');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating payment: $errorMessage'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openPaytmPaymentPage(String url, Map<String, dynamic> params) async {
    try {
      if (kIsWeb) {
        // For web, create a form and submit it via POST
        // Use JavaScript interop to create and submit form
        _submitPaytmFormWeb(url, params);
      } else {
        // For mobile, we'll need to create a webview or redirect
        // For now, open URL with parameters (Note: Paytm requires POST, so this may not work perfectly)
        // TODO: Implement proper webview for Paytm payment on mobile
        final uri = Uri.parse(url).replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open payment page');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open payment page: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Web-specific: Submit form to Paytm
  void _submitPaytmFormWeb(String url, Map<String, dynamic> params) {
    // For web, we'll use a simple approach: redirect with form data
    // Since we can't use dart:html directly in Flutter web easily,
    // we'll create a hidden form and submit it via JavaScript
    // Note: This requires web platform
    debugPrint('💳 Opening Paytm payment page for web');
    debugPrint('💳 URL: $url');
    debugPrint('💳 Params: $params');
    
    // For Flutter web, we can use url_launcher or implement a webview
    // For now, show a message that Paytm payment is being processed
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to Paytm payment gateway...'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Note: Paytm requires POST form submission
      // In a production app, you would implement a webview or use a plugin
      // that handles form POST submission properly
    }
  }

  Future<void> _handleOrderSuccess(Map<String, dynamic> orderData) async {
    // Clear cart
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();

    // Notify parent
    widget.onOrderCreated(orderData);

    if (mounted) {
      final orderNumber = orderData['order_number'] ?? orderData['id'] ?? 'Order';
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedPaymentMethod == 'cod'
                ? 'Order #$orderNumber placed successfully!'
                : 'Order #$orderNumber created. Redirecting to payment...',
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to home after successful order
      // TODO: Navigate to order detail screen when implemented
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
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

          // Payment Method Section
          _buildPaymentMethodSection(),
          const SizedBox(height: 24),

          // Scheduling Section (if applicable)
          if (_isScheduling || _hasMeatProducts) _buildSchedulingSection(),
          if (_isScheduling || _hasMeatProducts) const SizedBox(height: 24),

          // Order Summary
          _buildOrderSummary(),
          const SizedBox(height: 32),

          // Place Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreatingOrder || (_hasMeatProducts && _scheduledDeliveryTime == null)
                  ? null
                  : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: widget.isDesktop ? 18 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isCreatingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _selectedPaymentMethod == 'paytm' ? 'Pay with Paytm' : 'Place Order',
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
            child: Icon(Icons.check, color: Colors.white, size: 20),
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: AppTheme.primaryGreen,
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '2',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
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
                const Icon(
                  Icons.payment,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: widget.isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // COD Option
            RadioListTile<String>(
              value: 'cod',
              groupValue: _selectedPaymentMethod,
              onChanged: _isCreatingOrder ? null : (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: const Text('Cash on Delivery (COD)'),
              subtitle: const Text('Pay when order is delivered'),
              activeColor: AppTheme.primaryGreen,
            ),
            // Paytm Option
            RadioListTile<String>(
              value: 'paytm',
              groupValue: _selectedPaymentMethod,
              onChanged: _isCreatingOrder ? null : (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              title: const Text('Pay Online (Paytm)'),
              subtitle: const Text('Pay via Paytm payment gateway'),
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _hasMeatProducts ? AppTheme.error : AppTheme.bgGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: _hasMeatProducts ? AppTheme.error : AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _hasMeatProducts ? 'Delivery Schedule (Required)' : 'Schedule Delivery',
                  style: TextStyle(
                    fontSize: widget.isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_hasMeatProducts) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.error, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Meat orders must be scheduled for Saturday or Sunday, 6 AM - 8 AM',
                        style: TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_scheduledDeliveryTime != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled for:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatScheduledTime(_scheduledDeliveryTime!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _isCreatingOrder ? null : () {
                        _showMeatSchedulingDialog();
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _isCreatingOrder ? null : () {
                  _showMeatSchedulingDialog();
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(_hasMeatProducts ? 'Select Delivery Date (Required)' : 'Schedule Delivery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasMeatProducts ? AppTheme.error : AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
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
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: widget.isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', widget.cart.subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('Delivery Fee', widget.cart.deliveryFee),
            const SizedBox(height: 8),
            _buildSummaryRow('Tax', widget.cart.tax),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: widget.isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${widget.cart.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: widget.isDesktop ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: widget.isDesktop ? 16 : 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: widget.isDesktop ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatScheduledTime(DateTime dateTime) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[dateTime.weekday - 1];
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dayName, $date at $time';
  }
}

/// Meat Scheduling Dialog
class _MeatSchedulingDialog extends StatefulWidget {
  @override
  State<_MeatSchedulingDialog> createState() => _MeatSchedulingDialogState();
}

class _MeatSchedulingDialogState extends State<_MeatSchedulingDialog> {
  DateTime? _selectedDate;
  int? _selectedHour; // 6 or 7 (6 AM or 7 AM)

  @override
  void initState() {
    super.initState();
    _selectNextWeekend();
  }

  void _selectNextWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday) % 7;
    final nextSaturday = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
    
    setState(() {
      _selectedDate = nextSaturday;
      _selectedHour = 6; // Default to 6 AM
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Meat Order Delivery'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Meat orders must be scheduled for Saturday or Sunday, between 6 AM - 8 AM',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Date Selection
            const Text(
              'Select Date:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final daysUntilSaturday = (6 - now.weekday) % 7;
                      final nextSaturday = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
                      setState(() {
                        _selectedDate = nextSaturday;
                      });
                    },
                    child: const Text('Next Saturday'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final daysUntilSunday = (7 - now.weekday) % 7;
                      final nextSunday = now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
                      setState(() {
                        _selectedDate = nextSunday;
                      });
                    },
                    child: const Text('Next Sunday'),
                  ),
                ),
              ],
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedDate!.day.toString().padLeft(2, '0') +
                      '/' +
                      _selectedDate!.month.toString().padLeft(2, '0') +
                      '/' +
                      _selectedDate!.year.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Time Selection
            const Text(
              'Select Time:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    value: 6,
                    groupValue: _selectedHour,
                    onChanged: (value) {
                      setState(() {
                        _selectedHour = value;
                      });
                    },
                    title: const Text('6:00 AM'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    value: 7,
                    groupValue: _selectedHour,
                    onChanged: (value) {
                      setState(() {
                        _selectedHour = value;
                      });
                    },
                    title: const Text('7:00 AM'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedDate != null && _selectedHour != null
              ? () {
                  final scheduledTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedHour!,
                  );
                  Navigator.of(context).pop(scheduledTime);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

