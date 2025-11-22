import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import 'order_detail_screen.dart';

/// Order Status Splash Screen
/// 
/// Shows animated splash screen after order placement with status indication
class OrderStatusSplashScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String status; // 'confirmed', 'cancelled', 'error'
  final String? errorMessage;

  const OrderStatusSplashScreen({
    super.key,
    required this.orderData,
    required this.status,
    this.errorMessage,
  });

  @override
  State<OrderStatusSplashScreen> createState() => _OrderStatusSplashScreenState();
}

class _OrderStatusSplashScreenState extends State<OrderStatusSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Rotation animation (for success checkmark)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward().then((_) {
      setState(() {
        _animationComplete = true;
      });

      // Navigate to order details after animation
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && (widget.status == 'confirmed' || widget.status == 'order_placed')) {
          // Get order ID - handle both string and int formats
          String? orderId;
          final idValue = widget.orderData['id'];
          if (idValue is String) {
            orderId = idValue;
          } else if (idValue is int) {
            orderId = idValue.toString();
          } else if (idValue != null) {
            orderId = idValue.toString();
          }
          
          // Also try order_number if id is not available
          if (orderId == null || orderId.isEmpty) {
            final orderNumber = widget.orderData['order_number'];
            if (orderNumber is String) {
              orderId = orderNumber;
            }
          }
          
          if (orderId != null && orderId.isNotEmpty) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(orderId: orderId!),
              ),
            );
          } else {
            // If we can't get order ID, navigate to home
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (mounted) {
          // For errors or cancelled, go back
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'confirmed':
      case 'order_placed':
        return AppTheme.primaryGreen;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.error;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status.toLowerCase()) {
      case 'confirmed':
      case 'order_placed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.error;
    }
  }

  String _getStatusTitle() {
    switch (widget.status.toLowerCase()) {
      case 'confirmed':
      case 'order_placed':
        return 'Order Placed!';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Failed';
    }
  }

  String _getStatusMessage() {
    switch (widget.status.toLowerCase()) {
      case 'confirmed':
      case 'order_placed':
        final orderNumber = widget.orderData['order_number'] ?? 
                           widget.orderData['id'] ?? 
                           'your order';
        return 'Your order $orderNumber has been placed successfully';
      case 'cancelled':
        return widget.errorMessage ?? 'Your order has been cancelled';
      default:
        return widget.errorMessage ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: _getStatusColor().withOpacity(0.1),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with animation
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          width: isDesktop ? 200 : isTablet ? 160 : 140,
                          height: isDesktop ? 200 : isTablet ? 160 : 140,
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Icon
                        Icon(
                          _getStatusIcon(),
                          size: isDesktop ? 120 : isTablet ? 100 : 80,
                          color: _getStatusColor(),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 48 : isTablet ? 40 : 32),
                    // Title
                    Text(
                      _getStatusTitle(),
                      style: TextStyle(
                        fontSize: isDesktop ? 32 : isTablet ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isDesktop ? 16 : isTablet ? 14 : 12),
                    // Message
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : isTablet ? 40 : 32,
                      ),
                      child: Text(
                        _getStatusMessage(),
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_animationComplete && widget.status == 'confirmed') ...[
                      SizedBox(height: isDesktop ? 48 : isTablet ? 40 : 32),
                      // Loading indicator
                      SizedBox(
                        width: isDesktop ? 24 : isTablet ? 20 : 16,
                        height: isDesktop ? 24 : isTablet ? 20 : 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                        ),
                      ),
                      SizedBox(height: isDesktop ? 16 : isTablet ? 14 : 12),
                      Text(
                        'Loading order details...',
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

