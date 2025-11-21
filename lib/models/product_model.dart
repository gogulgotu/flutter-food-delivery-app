import 'package:flutter/foundation.dart';
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
    // Extract image from images array or direct image field
    String? imageUrl;
    
    // Try to get from images array first (preferred)
    if (json['images'] != null && json['images'] is List) {
      final images = json['images'] as List;
      if (images.isNotEmpty) {
        final firstImage = images[0];
        if (firstImage is Map<String, dynamic>) {
          // Prefer image_url, fallback to image
          imageUrl = firstImage['image_url'] as String? ?? 
                     firstImage['image'] as String?;
        }
      }
    }
    
    // Fallback to direct image field
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = json['image'] as String?;
    }
    
    // Clean the URL - remove any newlines, carriage returns, or extra whitespace
    if (imageUrl != null) {
      imageUrl = imageUrl.replaceAll(RegExp(r'[\n\r\t\s]+'), '').trim();
    }
    
    // Debug: Log image URL for troubleshooting
    if (imageUrl != null) {
      debugPrint('ProductModel: Image URL from API: $imageUrl');
    }
    
    // Handle vendor - can be a String (UUID) or Map (object)
    VendorInfo? vendor;
    final vendorData = json['vendor'];
    if (vendorData != null) {
      if (vendorData is Map<String, dynamic>) {
        // Vendor is an object
        vendor = VendorInfo.fromJson(vendorData);
      } else if (vendorData is String) {
        // Vendor is just an ID/UUID - try to get name from vendor_name or vendor_details
        final vendorName = json['vendor_name'] as String?;
        final vendorDetails = json['vendor_details'];
        if (vendorDetails is Map<String, dynamic>) {
          vendor = VendorInfo.fromJson(vendorDetails);
        } else {
          vendor = VendorInfo(
            id: vendorData,
            name: vendorName ?? '',
          );
        }
      }
    }
    
    // Handle category - can be int or String
    String? category;
    final categoryData = json['category'];
    if (categoryData != null) {
      if (categoryData is String) {
        category = categoryData;
      } else if (categoryData is int) {
        category = categoryData.toString();
      } else if (categoryData is num) {
        category = categoryData.toString();
      }
    }
    // Fallback to category_name if available
    if ((category == null || category.isEmpty) && json['category_name'] != null) {
      category = json['category_name'] as String?;
    }
    
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: _parseDouble(json['price']) ?? 0.0,
      discountedPrice: _parseDouble(json['discounted_price']),
      vendor: vendor,
      category: category,
      isAvailable: json['is_available'] as bool? ?? true,
      image: imageUrl,
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

