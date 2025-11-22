/// Order Model
/// 
/// Represents a customer order
class OrderModel {
  final String id;
  final String orderNumber;
  final VendorInfo? vendor;
  final double totalAmount;
  final String orderStatus;
  final String paymentStatus;
  final String? deliveryStatus;
  final DateTime orderPlacedAt;
  final DateTime? estimatedDeliveryTime;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.vendor,
    required this.totalAmount,
    required this.orderStatus,
    required this.paymentStatus,
    this.deliveryStatus,
    required this.orderPlacedAt,
    this.estimatedDeliveryTime,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Handle vendor - can be a full object or just an ID string
    VendorInfo? vendor;
    final vendorData = json['vendor'];
    if (vendorData != null) {
      if (vendorData is Map<String, dynamic>) {
        // Full vendor object
        vendor = VendorInfo.fromJson(vendorData);
      } else if (vendorData is String) {
        // Just vendor ID - create minimal vendor info
        // Try to get vendor name from other fields
        final vendorName = json['vendor_name'] as String? ?? 'Restaurant';
        vendor = VendorInfo(
          id: vendorData,
          name: vendorName,
          image: json['vendor_image'] as String?,
          phone: json['vendor_phone'] as String?,
          address: json['vendor_address'] as String?,
        );
      }
    }

    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      vendor: vendor,
      totalAmount: (json['total_amount'] as num).toDouble(),
      orderStatus: json['order_status'] as String,
      paymentStatus: json['payment_status'] as String,
      deliveryStatus: json['delivery_status'] as String?,
      orderPlacedAt: DateTime.parse(json['order_placed_at'] as String),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      if (vendor != null) 'vendor': vendor!.toJson(),
      'total_amount': totalAmount,
      'order_status': orderStatus,
      'payment_status': paymentStatus,
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
      'order_placed_at': orderPlacedAt.toIso8601String(),
      if (estimatedDeliveryTime != null)
        'estimated_delivery_time': estimatedDeliveryTime!.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return orderStatus;
    }
  }

  bool get isActive {
    final status = orderStatus.toLowerCase();
    return !['delivered', 'cancelled'].contains(status);
  }
}

/// Vendor Info Model (for orders)
class VendorInfo {
  final String id;
  final String name;
  final String? image;
  final String? phone;
  final String? address;

  VendorInfo({
    required this.id,
    required this.name,
    this.image,
    this.phone,
    this.address,
  });

  factory VendorInfo.fromJson(Map<String, dynamic> json) {
    return VendorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (image != null) 'image': image,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    };
  }
}

