/// Address Model
/// 
/// Represents a delivery address for orders
class AddressModel {
  final int id;
  final String title;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.title,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  /// Create AddressModel from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // Helper function to parse latitude/longitude (can be String or num)
    double? _parseCoordinate(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        if (value.isEmpty) return null;
        return double.tryParse(value);
      }
      return null;
    }

    return AddressModel(
      id: json['id'] as int,
      title: json['title'] as String,
      addressLine1: json['address_line_1'] as String,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String? ?? 'India',
      postalCode: json['postal_code'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
    );
  }

  /// Convert AddressModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'address_line_1': addressLine1,
      if (addressLine2 != null) 'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'is_default': isDefault,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Get full address string
  String get fullAddress {
    final parts = <String>[];
    parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.add(city);
    parts.add(state);
    parts.add('$postalCode');
    parts.add(country);
    return parts.join(', ');
  }

  /// Get short address (first line + city)
  String get shortAddress {
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      return '$addressLine1, $addressLine2, $city';
    }
    return '$addressLine1, $city';
  }

  AddressModel copyWith({
    int? id,
    String? title,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return AddressModel(
      id: id ?? this.id,
      title: title ?? this.title,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

