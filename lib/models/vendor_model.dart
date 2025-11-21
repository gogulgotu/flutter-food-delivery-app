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
    return VendorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      rating: _parseDouble(json['rating']),
      deliveryTime: _parseInt(json['delivery_time']),
      deliveryFee: _parseDouble(json['delivery_fee']),
      minimumOrder: _parseDouble(json['minimum_order']),
      isActive: json['is_active'] as bool? ?? true,
      image: json['image'] as String?,
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

