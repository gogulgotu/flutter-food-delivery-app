import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../config/app_config.dart';

/// Storage Service
/// 
/// Handles secure storage of tokens and user data
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: AppConfig.accessTokenKey,
      value: token,
    );
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConfig.accessTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(
      key: AppConfig.refreshTokenKey,
      value: token,
    );
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConfig.refreshTokenKey);
  }

  /// Save user data
  Future<void> saveUserData(UserModel user) async {
    await init();
    final userJson = jsonEncode(user.toJson());
    await _prefs?.setString(AppConfig.userDataKey, userJson);
    await _prefs?.setBool(AppConfig.isLoggedInKey, true);
  }

  /// Get user data
  Future<UserModel?> getUserData() async {
    await init();
    final userJson = _prefs?.getString(AppConfig.userDataKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    await init();
    return _prefs?.getBool(AppConfig.isLoggedInKey) ?? false;
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await init();
    await _secureStorage.delete(key: AppConfig.accessTokenKey);
    await _secureStorage.delete(key: AppConfig.refreshTokenKey);
    await _prefs?.remove(AppConfig.userDataKey);
    await _prefs?.setBool(AppConfig.isLoggedInKey, false);
  }

  /// Save tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }
}

