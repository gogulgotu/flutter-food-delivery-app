import 'order_model.dart';

/// Product Model
/// 
/// Represents a product (food item) in the system
class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? discountedPrice;
  final VendorInfo? vendor;
  final String? category;
  final bool isAvailable;
  final String? image;
  final bool? isFeatured;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.discountedPrice,
    this.vendor,
    this.category,
    required this.isAvailable,
    this.image,
    this.isFeatured,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: _parseDouble(json['price']) ?? 0.0,
      discountedPrice: _parseDouble(json['discounted_price']),
      vendor: json['vendor'] != null
          ? VendorInfo.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      image: json['image'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  /// Helper method to safely parse double values that might be strings or numbers
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
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      'price': price,
      if (discountedPrice != null) 'discounted_price': discountedPrice,
      if (vendor != null) 'vendor': vendor!.toJson(),
      if (category != null) 'category': category,
      'is_available': isAvailable,
      if (image != null) 'image': image,
      if (isFeatured != null) 'is_featured': isFeatured,
    };
  }

  double get effectivePrice => discountedPrice ?? price;
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
}

/// Product Category Model
class ProductCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? image;

  ProductCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.image,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (icon != null) 'icon': icon,
      if (image != null) 'image': image,
    };
  }
}

