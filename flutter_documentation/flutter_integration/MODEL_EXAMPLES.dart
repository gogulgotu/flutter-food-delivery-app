// Flutter Model Examples
// These are example model classes that correspond to API response structures

import 'package:json_annotation/json_annotation.dart';

part 'model_examples.g.dart';

/// User Model
@JsonSerializable()
class User {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  @JsonKey(name: 'user_role_name')
  final String? userRoleName;
  final bool? isVerified;
  
  User({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.userRoleName,
    this.isVerified,
  });
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

/// Address Model
@JsonSerializable()
class Address {
  final int id;
  final String title;
  @JsonKey(name: 'address_line_1')
  final String addressLine1;
  @JsonKey(name: 'address_line_2')
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  @JsonKey(name: 'postal_code')
  final String postalCode;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  
  Address({
    required this.id,
    required this.title,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });
  
  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
  
  String get fullAddress {
    final parts = [addressLine1, addressLine2, city, state, postalCode, country]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

/// Vendor Model
@JsonSerializable()
class Vendor {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double? rating;
  @JsonKey(name: 'delivery_time')
  final int? deliveryTime;
  @JsonKey(name: 'delivery_fee')
  final double? deliveryFee;
  @JsonKey(name: 'minimum_order')
  final double? minimumOrder;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  final String? image;
  
  Vendor({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.rating,
    this.deliveryTime,
    this.deliveryFee,
    this.minimumOrder,
    this.isActive,
    this.image,
  });
  
  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);
  Map<String, dynamic> toJson() => _$VendorToJson(this);
}

/// Product Model
@JsonSerializable()
class Product {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  @JsonKey(name: 'discounted_price')
  final double? discountedPrice;
  final String? vendor;
  final String? category;
  @JsonKey(name: 'is_available')
  final bool? isAvailable;
  final String? image;
  final List<String>? images;
  
  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.discountedPrice,
    this.vendor,
    this.category,
    this.isAvailable,
    this.image,
    this.images,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
  
  double get finalPrice => discountedPrice ?? price;
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
}

/// Cart Item Model
@JsonSerializable()
class CartItem {
  final int id;
  final Product product;
  final int quantity;
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  
  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
  
  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);
}

/// Cart Model
@JsonSerializable()
class Cart {
  final String id;
  final Vendor vendor;
  final List<CartItem> items;
  final double subtotal;
  final double? deliveryFee;
  final double? tax;
  final double total;
  
  Cart({
    required this.id,
    required this.vendor,
    required this.items,
    required this.subtotal,
    this.deliveryFee,
    this.tax,
    required this.total,
  });
  
  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Order Item Model
@JsonSerializable()
class OrderItem {
  final String id;
  final Product product;
  final int quantity;
  final double price;
  @JsonKey(name: 'total_price')
  final double totalPrice;
  
  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });
  
  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

/// Order Model
@JsonSerializable()
class Order {
  final String id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  final Vendor vendor;
  final Address? deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  @JsonKey(name: 'delivery_fee')
  final double deliveryFee;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'order_status')
  final String orderStatus;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'delivery_status')
  final String? deliveryStatus;
  @JsonKey(name: 'order_placed_at')
  final DateTime orderPlacedAt;
  @JsonKey(name: 'estimated_delivery_time')
  final DateTime? estimatedDeliveryTime;
  @JsonKey(name: 'actual_delivery_time')
  final DateTime? actualDeliveryTime;
  
  Order({
    required this.id,
    required this.orderNumber,
    required this.vendor,
    this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.orderStatus,
    required this.paymentStatus,
    this.deliveryStatus,
    required this.orderPlacedAt,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
  });
  
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
  
  bool get isCompleted => paymentStatus == 'completed' && 
                          (deliveryStatus == 'delivered' || orderStatus == 'delivered');
}

/// Payment Model
@JsonSerializable()
class Payment {
  final String id;
  final String order;
  final double amount;
  final String currency;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'gateway_name')
  final String? gatewayName;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  @JsonKey(name: 'initiated_at')
  final DateTime initiatedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  
  Payment({
    required this.id,
    required this.order,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    this.gatewayName,
    this.transactionId,
    required this.initiatedAt,
    this.completedAt,
  });
  
  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
  
  bool get isCompleted => paymentStatus == 'completed';
}

/// Notification Model
@JsonSerializable()
class Notification {
  final String id;
  final String title;
  final String message;
  final String type;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_on')
  final DateTime createdOn;
  
  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdOn,
  });
  
  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationToJson(this);
}

/// Wallet Model
@JsonSerializable()
class Wallet {
  final String id;
  final double balance;
  final String currency;
  
  Wallet({
    required this.id,
    required this.balance,
    required this.currency,
  });
  
  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
  Map<String, dynamic> toJson() => _$WalletToJson(this);
}

/// Wallet Transaction Model
@JsonSerializable()
class WalletTransaction {
  final String id;
  final double amount;
  @JsonKey(name: 'transaction_type')
  final String transactionType;
  final String description;
  @JsonKey(name: 'created_on')
  final DateTime createdOn;
  
  WalletTransaction({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.createdOn,
  });
  
  factory WalletTransaction.fromJson(Map<String, dynamic> json) => 
      _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);
  
  bool get isCredit => transactionType == 'credit';
  bool get isDebit => transactionType == 'debit';
}

/// Usage:
/// 1. Add json_serializable to pubspec.yaml
/// 2. Run: flutter pub run build_runner build
/// 3. Import and use models:
/// 
/// ```dart
/// final user = User.fromJson(jsonData);
/// final json = user.toJson();
/// ```

