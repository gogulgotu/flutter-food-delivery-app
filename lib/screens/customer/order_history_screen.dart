import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Order History Screen
/// 
/// Displays order status history and tracking timeline
class OrderHistoryScreen extends StatefulWidget {
  final String orderId;

  const OrderHistoryScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getOrderHistory(widget.orderId);
      if (mounted) {
        setState(() {
          _history = (data['history'] as List? ?? [])
              .map((item) => item as Map<String, dynamic>)
              .toList();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _history.isEmpty
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView.builder(
                        padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final isLast = index == _history.length - 1;
                          return _buildHistoryItem(item, isLast, isDesktop, isTablet);
                        },
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
              'Error loading history',
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
              onPressed: _loadHistory,
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
            Icon(Icons.history, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No history available',
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

  Widget _buildHistoryItem(Map<String, dynamic> item, bool isLast, bool isDesktop, bool isTablet) {
    final status = item['status'] as String? ?? '';
    final statusName = item['status_name'] as String? ?? status;
    final description = item['description'] as String? ?? '';
    final createdAt = item['created_at'] as String?;
    final updatedBy = item['updated_by'] as String?;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          Column(
            children: [
              Container(
                width: isDesktop ? 40 : isTablet ? 36 : 32,
                height: isDesktop ? 40 : isTablet ? 36 : 32,
                decoration: BoxDecoration(
                  color: isLast ? AppTheme.primaryGreen : AppTheme.primaryGreen.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLast ? AppTheme.primaryGreen : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: isLast ? Colors.white : AppTheme.primaryGreen,
                  size: isDesktop ? 20 : isTablet ? 18 : 16,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          SizedBox(width: isDesktop ? 16 : isTablet ? 14 : 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? 24 : isTablet ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusName,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : isTablet ? 16 : 15,
                      fontWeight: FontWeight.bold,
                      color: isLast ? AppTheme.primaryGreen : AppTheme.textPrimary,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: isDesktop ? 4 : isTablet ? 3 : 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (createdAt != null) ...[
                    SizedBox(height: isDesktop ? 8 : isTablet ? 6 : 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: isDesktop ? 14 : isTablet ? 13 : 12, color: AppTheme.textMuted),
                        SizedBox(width: isDesktop ? 4 : isTablet ? 3 : 2),
                        Text(
                          _formatDateTime(createdAt),
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : isTablet ? 11 : 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (updatedBy != null && updatedBy.isNotEmpty) ...[
                    SizedBox(height: isDesktop ? 4 : isTablet ? 3 : 2),
                    Row(
                      children: [
                        Icon(Icons.person, size: isDesktop ? 14 : isTablet ? 13 : 12, color: AppTheme.textMuted),
                        SizedBox(width: isDesktop ? 4 : isTablet ? 3 : 2),
                        Text(
                          updatedBy,
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : isTablet ? 11 : 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'order_placed':
        return Icons.shopping_cart;
      case 'order_confirmed':
      case 'restaurant_confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.restaurant_menu;
      case 'order_picked_up':
        return Icons.local_shipping;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
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

