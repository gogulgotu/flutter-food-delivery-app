import 'package:flutter/foundation.dart';

/// Vendor Details Model
/// 
/// Extended model for detailed vendor information including address, phone, hours, etc.
class VendorDetailsModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double? rating;
  final int? totalReviews;
  final int? deliveryTime;
  final double? deliveryFee;
  final double? minimumOrder;
  final bool isActive;
  final String? image;
  final String? coverImage;
  final String? logo;
  final List<String>? cuisineTypes;
  
  // Extended details
  final String? address;
  final String? phone;
  final String? email;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final Map<String, OperatingHours>? operatingHours;
  final bool? isVerified;
  final bool? isFeatured;

  VendorDetailsModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.rating,
    this.totalReviews,
    this.deliveryTime,
    this.deliveryFee,
    this.minimumOrder,
    required this.isActive,
    this.image,
    this.coverImage,
    this.logo,
    this.cuisineTypes,
    this.address,
    this.phone,
    this.email,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.operatingHours,
    this.isVerified,
    this.isFeatured,
  });

  factory VendorDetailsModel.fromJson(Map<String, dynamic> json) {
    // Extract images
    String? imageUrl = json['cover_image_url'] as String? ??
                       json['cover_image'] as String? ??
                       json['logo_url'] as String? ??
                       json['logo'] as String? ??
                       json['image'] as String?;
    
    if (imageUrl != null) {
      imageUrl = imageUrl.replaceAll(RegExp(r'[\n\r\t\s]+'), '').trim();
    }

    // Parse operating hours
    Map<String, OperatingHours>? hours;
    if (json['operating_hours'] != null && json['operating_hours'] is Map) {
      hours = {};
      final hoursMap = json['operating_hours'] as Map<String, dynamic>;
      hoursMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          hours![key] = OperatingHours.fromJson(value);
        }
      });
    } else if (json['operating_hours'] != null && json['operating_hours'] is List) {
      // Handle array format
      hours = {};
      final hoursList = json['operating_hours'] as List;
      for (var hourData in hoursList) {
        if (hourData is Map<String, dynamic>) {
          final dayName = hourData['day_name'] as String?;
          final dayCode = hourData['day_code'] as String?;
          if (dayName != null || dayCode != null) {
            final key = dayCode ?? dayName!.toLowerCase();
            hours![key] = OperatingHours.fromJson(hourData);
          }
        }
      }
    }

    return VendorDetailsModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      rating: _parseDouble(json['rating']),
      totalReviews: _parseInt(json['total_reviews']),
      deliveryTime: _parseInt(json['delivery_time']) ?? 
                    _parseInt(json['delivery_time_min']),
      deliveryFee: _parseDouble(json['delivery_fee']) ?? 
                   _parseDouble(json['delivery_fee_amount']),
      minimumOrder: _parseDouble(json['minimum_order']) ?? 
                    _parseDouble(json['minimum_order_amount']),
      isActive: json['is_active'] as bool? ?? true,
      image: imageUrl,
      coverImage: json['cover_image_url'] as String? ?? json['cover_image'] as String?,
      logo: json['logo_url'] as String? ?? json['logo'] as String?,
      cuisineTypes: json['cuisine_types'] != null
          ? List<String>.from(json['cuisine_types'] as List)
          : null,
      address: json['address'] as String?,
      phone: json['phone'] as String? ?? json['phone_number'] as String?,
      email: json['email'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      operatingHours: hours,
      isVerified: json['is_verified'] as bool?,
      isFeatured: json['is_featured'] as bool?,
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
}

/// Operating Hours Model
class OperatingHours {
  final String? dayName;
  final String? dayCode;
  final bool? isOpen;
  final String? openingTime;
  final String? closingTime;
  final String? breakStartTime;
  final String? breakEndTime;

  OperatingHours({
    this.dayName,
    this.dayCode,
    this.isOpen,
    this.openingTime,
    this.closingTime,
    this.breakStartTime,
    this.breakEndTime,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      dayName: json['day_name'] as String?,
      dayCode: json['day_code'] as String?,
      isOpen: json['is_open'] as bool?,
      openingTime: json['opening_time'] as String? ?? json['open'] as String?,
      closingTime: json['closing_time'] as String? ?? json['close'] as String?,
      breakStartTime: json['break_start_time'] as String?,
      breakEndTime: json['break_end_time'] as String?,
    );
  }

  String get displayTime {
    if (isOpen == false) return 'Closed';
    if (openingTime == null || closingTime == null) return 'Open';
    return '$openingTime - $closingTime';
  }
}

