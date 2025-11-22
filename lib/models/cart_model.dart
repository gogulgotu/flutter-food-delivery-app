import 'product_model.dart';
import 'vendor_model.dart';

/// Cart Item Model
class CartItemModel {
  final int id;
  final ProductModel product;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? variantId;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.variantId,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Handle product - can be a full object or just an ID string
    ProductModel product;
    final productData = json['product'];
    
    if (productData is Map<String, dynamic>) {
      // Full product object
      product = ProductModel.fromJson(productData);
    } else if (productData is String) {
      // Just product ID - create minimal product model
      final unitPrice = _parseDouble(json['unit_price']) ?? 0.0;
      product = ProductModel(
        id: productData,
        name: json['product_name'] as String? ?? 'Product',
        slug: 'product-${productData}',
        price: unitPrice,
        isAvailable: true,
        image: json['product_image'] as String?,
        description: json['product_description'] as String?,
      );
    } else {
      // Fallback for unexpected format
      final unitPrice = _parseDouble(json['unit_price']) ?? 0.0;
      product = ProductModel(
        id: productData.toString(),
        name: json['product_name'] as String? ?? 'Product',
        slug: 'product-${productData}',
        price: unitPrice,
        isAvailable: true,
      );
    }

    return CartItemModel(
      id: json['id'] as int,
      product: product,
      quantity: json['quantity'] as int,
      unitPrice: _parseDouble(json['unit_price']) ?? 0.0,
      totalPrice: _parseDouble(json['total_price']) ?? 0.0,
      variantId: json['variant'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      if (variantId != null) 'variant': variantId,
    };
  }

  CartItemModel copyWith({
    int? id,
    ProductModel? product,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? variantId,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      variantId: variantId ?? this.variantId,
    );
  }
}

/// Cart Model
class CartModel {
  final String id;
  final VendorModel vendor;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;

  CartModel({
    required this.id,
    required this.vendor,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    // Handle vendor - can be object or just id/name
    VendorModel vendor;
    final vendorData = json['vendor'];
    if (vendorData is Map<String, dynamic>) {
      vendor = VendorModel.fromJson(vendorData);
    } else {
      // Create a minimal vendor model
      vendor = VendorModel(
        id: vendorData.toString(),
        name: json['vendor_name'] as String? ?? 'Restaurant',
        slug: 'restaurant',
        isActive: true,
      );
    }

    return CartModel(
      id: json['id'] as String,
      vendor: vendor,
      items: (json['items'] as List)
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: _parseDouble(json['subtotal']) ?? 0.0,
      deliveryFee: _parseDouble(json['delivery_fee']) ?? 0.0,
      tax: _parseDouble(json['tax']) ?? 0.0,
      total: _parseDouble(json['total']) ?? 0.0,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendor.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'total': total,
    };
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

