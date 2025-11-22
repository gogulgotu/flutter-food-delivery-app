/// User Model
/// 
/// Represents a user in the system with role information
class UserModel {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String userRoleName; // Customer, Vendor, Delivery Person
  final bool? isVerified;
  final double? latitude;
  final double? longitude;
  final String? address;

  UserModel({
    required this.id,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    required this.userRoleName,
    this.isVerified,
    this.latitude,
    this.longitude,
    this.address,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      userRoleName: json['user_role_name'] as String? ?? 'Customer',
      isVerified: json['is_verified'] as bool?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      address: json['address'] as String?,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'user_role_name': userRoleName,
      'is_verified': isVerified,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  /// Get user role enum
  UserRole get role {
    switch (userRoleName.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'vendor':
      case 'hotel_owner':
      case 'restaurant_owner':
        return UserRole.vendor;
      case 'delivery_person':
      case 'delivery':
        return UserRole.deliveryPerson;
      default:
        return UserRole.customer;
    }
  }

  /// Get display name
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (phoneNumber != null) {
      return phoneNumber!;
    }
    return 'User';
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? userRoleName,
    bool? isVerified,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userRoleName: userRoleName ?? this.userRoleName,
      isVerified: isVerified ?? this.isVerified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }
}

/// User Role Enum
enum UserRole {
  customer,
  vendor,
  deliveryPerson,
}

/// Extension to get role display name
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.deliveryPerson:
        return 'Delivery Person';
    }
  }
}

