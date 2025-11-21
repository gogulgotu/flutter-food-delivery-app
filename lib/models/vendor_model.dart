import 'package:flutter/foundation.dart';

/// Vendor Model
/// 
/// Represents a vendor (restaurant/hotel) in the system
class VendorModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double? rating;
  final int? deliveryTime;
  final double? deliveryFee;
  final double? minimumOrder;
  final bool isActive;
  final String? image;
  final List<String>? cuisineTypes;

  VendorModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.rating,
    this.deliveryTime,
    this.deliveryFee,
    this.minimumOrder,
    required this.isActive,
    this.image,
    this.cuisineTypes,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    // Extract image - try multiple possible fields
    String? imageUrl;
    
    // Try cover_image_url first (most common for vendor cards)
    imageUrl = json['cover_image_url'] as String?;
    
    // Fallback to cover_image
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = json['cover_image'] as String?;
    }
    
    // Fallback to logo_url
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = json['logo_url'] as String?;
    }
    
    // Fallback to logo
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = json['logo'] as String?;
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
      debugPrint('VendorModel: Image URL from API: $imageUrl');
    } else {
      debugPrint('VendorModel: No image URL found in: ${json.keys.toList()}');
    }
    
    return VendorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      rating: _parseDouble(json['rating']),
      deliveryTime: _parseInt(json['delivery_time']) ?? 
                    _parseInt(json['delivery_time_min']),
      deliveryFee: _parseDouble(json['delivery_fee']) ?? 
                   _parseDouble(json['delivery_fee_amount']),
      minimumOrder: _parseDouble(json['minimum_order']) ?? 
                    _parseDouble(json['minimum_order_amount']),
      isActive: json['is_active'] as bool? ?? true,
      image: imageUrl,
      cuisineTypes: json['cuisine_types'] != null
          ? List<String>.from(json['cuisine_types'] as List)
          : null,
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

  /// Helper method to safely parse int values that might be strings or numbers
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
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
      if (rating != null) 'rating': rating,
      if (deliveryTime != null) 'delivery_time': deliveryTime,
      if (deliveryFee != null) 'delivery_fee': deliveryFee,
      if (minimumOrder != null) 'minimum_order': minimumOrder,
      'is_active': isActive,
      if (image != null) 'image': image,
      if (cuisineTypes != null) 'cuisine_types': cuisineTypes,
    };
  }
}

