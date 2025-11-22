import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import 'order_tracking_screen.dart';
import 'order_history_screen.dart';

/// Order Detail Screen
/// 
/// Comprehensive order information display following ORDER_PROCESS_FLOW_DOCUMENTATION.md
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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

  Future<void> _cancelOrder() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelOrderDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await _apiService.cancelOrder(widget.orderId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 3),
          ),
        );
        await _loadOrderDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling order: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  bool _canCancelOrder() {
    if (_orderData == null) return false;
    // Handle order_status as either int or string, prefer order_status_code
    String status = '';
    if (_orderData!['order_status_code'] != null) {
      status = (_orderData!['order_status_code'] as String).toLowerCase();
    } else if (_orderData!['order_status'] != null) {
      final orderStatus = _orderData!['order_status'];
      if (orderStatus is String) {
        status = orderStatus.toLowerCase();
      } else if (orderStatus is int) {
        // Map int status to string codes (1 = pending, etc.)
        status = orderStatus == 1 ? 'pending' : '';
      }
    }
    return status == 'order_placed' || 
           status == 'pending' || 
           status == 'order_confirmed' ||
           status == 'restaurant_confirmed';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadOrderDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _orderData == null
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetails,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 32 : isTablet ? 24 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Order Status Card
                            _buildOrderStatusCard(isDesktop, isTablet),
                            SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            
                            // Order Info Card
                            _buildOrderInfoCard(isDesktop, isTablet),
                            SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            
                            // Items Card
                            _buildItemsCard(isDesktop, isTablet),
                            SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            
                            // Delivery Address Card
                            _buildDeliveryAddressCard(isDesktop, isTablet),
                            SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            
                            // Payment Summary Card
                            _buildPaymentSummaryCard(isDesktop, isTablet),
                            SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                            
                            // Action Buttons
                            _buildActionButtons(isDesktop, isTablet),
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
              onPressed: _loadOrderDetails,
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
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Order not found',
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

  Widget _buildOrderStatusCard(bool isDesktop, bool isTablet) {
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
    final orderNumber = _orderData!['order_number'] as String? ?? 'N/A';

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'order_placed':
      case 'order_confirmed':
      case 'restaurant_confirmed':
        statusColor = AppTheme.primaryGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'preparing':
      case 'food_being_prepared':
        statusColor = AppTheme.accentYellow;
        statusIcon = Icons.restaurant;
        break;
      case 'ready_for_pickup':
        statusColor = AppTheme.accentLeafGreen;
        statusIcon = Icons.restaurant_menu;
        break;
      case 'out_for_delivery':
        statusColor = AppTheme.accentLeafGreen;
        statusIcon = Icons.delivery_dining;
        break;
      case 'delivered':
        statusColor = AppTheme.primaryGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusIcon = Icons.info_outline;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : isTablet ? 14 : 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: isDesktop ? 32 : isTablet ? 28 : 24),
            ),
            SizedBox(width: isDesktop ? 20 : isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusName,
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #$orderNumber',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_canCancelOrder() && !_isCancelling)
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                onPressed: _cancelOrder,
                tooltip: 'Cancel Order',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(bool isDesktop, bool isTablet) {
    final orderPlacedAt = _orderData!['order_placed_at'] as String?;
    final estimatedDeliveryTime = _orderData!['estimated_delivery_time'] as String?;
    final vendorName = _orderData!['vendor_name'] as String? ?? 'Unknown Restaurant';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: AppTheme.primaryGreen, size: isDesktop ? 24 : isTablet ? 22 : 20),
                SizedBox(width: isDesktop ? 12 : isTablet ? 10 : 8),
                Expanded(
                  child: Text(
                    vendorName,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 16 : isTablet ? 14 : 12),
            if (orderPlacedAt != null)
              _buildInfoRow(
                Icons.access_time,
                'Order Placed',
                _formatDateTime(orderPlacedAt),
                isDesktop,
                isTablet,
              ),
            if (estimatedDeliveryTime != null) ...[
              SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
              _buildInfoRow(
                Icons.schedule,
                'Estimated Delivery',
                _formatDateTime(estimatedDeliveryTime),
                isDesktop,
                isTablet,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(bool isDesktop, bool isTablet) {
    final items = _orderData!['items'] as List? ?? [];
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: TextStyle(
                fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : isTablet ? 14 : 12),
            ...items.map((item) => _buildOrderItem(item, isDesktop, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, bool isDesktop, bool isTablet) {
    // Handle product - can be a full object or just an ID string
    String productName;
    String? image;
    
    final productData = item['product'];
    if (productData is Map<String, dynamic>) {
      // Full product object
      productName = productData['name'] as String? ?? 'Unknown Product';
      image = productData['image'] as String?;
    } else if (productData is String) {
      // Just product ID - use product_name from item
      productName = item['product_name'] as String? ?? 'Unknown Product';
      image = item['product_image'] as String?;
    } else {
      // Fallback
      productName = item['product_name'] as String? ?? 'Unknown Product';
      image = item['product_image'] as String?;
    }
    
    final quantity = item['quantity'] as int? ?? 1;
    final unitPrice = _parseDouble(item['unit_price']) ?? 0.0;
    final totalPrice = _parseDouble(item['total_price']) ?? unitPrice * quantity;

    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 16 : isTablet ? 14 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: isDesktop ? 80 : isTablet ? 70 : 60,
              height: isDesktop ? 80 : isTablet ? 70 : 60,
              child: image != null && image.isNotEmpty
                  ? ImageUtils.buildNetworkImage(
                      imageUrl: image,
                      width: isDesktop ? 80 : isTablet ? 70 : 60,
                      height: isDesktop ? 80 : isTablet ? 70 : 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.bgGray,
                      child: Icon(Icons.fastfood, color: AppTheme.textMuted, size: isDesktop ? 32 : isTablet ? 28 : 24),
                    ),
            ),
          ),
          SizedBox(width: isDesktop ? 16 : isTablet ? 14 : 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isDesktop ? 4 : isTablet ? 3 : 2),
                Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : isTablet ? 3 : 2),
                Text(
                  '₹${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard(bool isDesktop, bool isTablet) {
    final deliveryAddress = _orderData!['delivery_address_details'] as Map<String, dynamic>? ?? {};
    final addressLine1 = deliveryAddress['address_line_1'] as String? ?? '';
    final addressLine2 = deliveryAddress['address_line_2'] as String? ?? '';
    final city = deliveryAddress['city'] as String? ?? '';
    final state = deliveryAddress['state'] as String? ?? '';
    final postalCode = deliveryAddress['postal_code'] as String? ?? '';
    final fullAddress = _orderData!['delivery_address_full'] as String? ?? 
                       '$addressLine1${addressLine2.isNotEmpty ? ", $addressLine2" : ""}, $city, $state $postalCode';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryGreen, size: isDesktop ? 24 : isTablet ? 22 : 20),
                SizedBox(width: isDesktop ? 12 : isTablet ? 10 : 8),
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
            Text(
              fullAddress.trim(),
              style: TextStyle(
                fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard(bool isDesktop, bool isTablet) {
    final subtotal = _parseDouble(_orderData!['subtotal']) ?? 0.0;
    final deliveryFee = _parseDouble(_orderData!['delivery_fee']) ?? 0.0;
    final taxAmount = _parseDouble(_orderData!['tax_amount']) ?? 0.0;
    final totalAmount = _parseDouble(_orderData!['total_amount']) ?? 0.0;
    final paymentMethod = _orderData!['payment_method'] as String? ?? 'cod';
    final paymentStatus = _orderData!['payment_status'] as String? ?? 'pending';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : isTablet ? 14 : 12),
            _buildSummaryRow('Subtotal', subtotal, isDesktop, isTablet),
            SizedBox(height: isDesktop ? 8 : isTablet ? 7 : 6),
            _buildSummaryRow('Delivery Fee', deliveryFee, isDesktop, isTablet),
            SizedBox(height: isDesktop ? 8 : isTablet ? 7 : 6),
            _buildSummaryRow('Tax', taxAmount, isDesktop, isTablet),
            Divider(height: isDesktop ? 24 : isTablet ? 20 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isDesktop ? 22 : isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
            Row(
              children: [
                Icon(Icons.payment, size: isDesktop ? 20 : isTablet ? 18 : 16, color: AppTheme.textSecondary),
                SizedBox(width: isDesktop ? 8 : isTablet ? 6 : 4),
                Text(
                  'Payment Method: ${paymentMethod.toUpperCase()}',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : isTablet ? 10 : 8,
                    vertical: isDesktop ? 4 : isTablet ? 3 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'completed' || paymentStatus == 'success'
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : AppTheme.accentYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: isDesktop ? 12 : isTablet ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: paymentStatus == 'completed' || paymentStatus == 'success'
                          ? AppTheme.primaryGreen
                          : AppTheme.accentYellow,
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

  Widget _buildActionButtons(bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Track Order Button
        SizedBox(
          height: isDesktop ? 52 : isTablet ? 48 : 44,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderTrackingScreen(orderId: widget.orderId),
                ),
              );
            },
            icon: const Icon(Icons.location_searching),
            label: const Text('Track Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
        // View History Button
        SizedBox(
          height: isDesktop ? 52 : isTablet ? 48 : 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderHistoryScreen(orderId: widget.orderId),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View Order History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_canCancelOrder()) ...[
          SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
          SizedBox(
            height: isDesktop ? 52 : isTablet ? 48 : 44,
            child: OutlinedButton.icon(
              onPressed: _isCancelling ? null : _cancelOrder,
              icon: _isCancelling
                  ? SizedBox(
                      width: isDesktop ? 20 : isTablet ? 18 : 16,
                      height: isDesktop ? 20 : isTablet ? 18 : 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(_isCancelling ? 'Cancelling...' : 'Cancel Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDesktop, bool isTablet) {
    return Row(
      children: [
        Icon(icon, size: isDesktop ? 20 : isTablet ? 18 : 16, color: AppTheme.textSecondary),
        SizedBox(width: isDesktop ? 8 : isTablet ? 6 : 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isDesktop, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime.toLocal());
    } catch (e) {
      return dateTimeString;
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

/// Cancel Order Dialog
class _CancelOrderDialog extends StatefulWidget {
  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  final _reasonController = TextEditingController();
  final List<String> _commonReasons = [
    'Changed my mind',
    'Wrong order',
    'Found better option',
    'Delivery time too long',
    'Other',
  ];
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            ..._commonReasons.map((reason) => RadioListTile<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                      if (value != 'Other') {
                        _reasonController.text = value!;
                      } else {
                        _reasonController.clear();
                      }
                    });
                  },
                  title: Text(reason),
                  dense: true,
                )),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _reasonController.text.isEmpty
              ? null
              : () => Navigator.of(context).pop(_reasonController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Cancellation'),
        ),
      ],
    );
  }
}

