import 'user_model.dart';

/// Authentication Response Model
/// 
/// Represents the response from OTP verification endpoint
class AuthResponseModel {
  final bool success;
  final UserModel user;
  final TokenModel tokens;
  final String? userType; // 'existing' or 'new'

  AuthResponseModel({
    required this.success,
    required this.user,
    required this.tokens,
    this.userType,
  });

  /// Create AuthResponseModel from JSON
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] as bool? ?? true,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokenModel.fromJson(json['tokens'] as Map<String, dynamic>),
      userType: json['user_type'] as String?,
    );
  }

  /// Convert AuthResponseModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user': user.toJson(),
      'tokens': tokens.toJson(),
      'user_type': userType,
    };
  }
}

/// Token Model
/// 
/// Represents JWT tokens (access and refresh)
class TokenModel {
  final String access;
  final String refresh;

  TokenModel({
    required this.access,
    required this.refresh,
  });

  /// Create TokenModel from JSON
  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );
  }

  /// Convert TokenModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'access': access,
      'refresh': refresh,
    };
  }
}

/// OTP Send Response Model
class OtpSendResponseModel {
  final bool success;
  final String message;
  final String? otp; // Only in development
  final int? expiresIn;

  OtpSendResponseModel({
    required this.success,
    required this.message,
    this.otp,
    this.expiresIn,
  });

  factory OtpSendResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpSendResponseModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'OTP sent successfully',
      otp: json['otp'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }
}

