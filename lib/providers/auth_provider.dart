import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Authentication Provider
/// 
/// Manages authentication state and operations
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _lastOtp; // Store OTP for development mode

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get lastOtp => _lastOtp; // Get OTP for development display

  /// Initialize auth state from storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _storageService.isLoggedIn();
      if (isLoggedIn) {
        _user = await _storageService.getUserData();
        _isAuthenticated = _user != null;
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send OTP to mobile number
  /// Returns the OTP if available (development mode)
  Future<bool> sendOtp(String mobileNumber) async {
    _isLoading = true;
    _errorMessage = null;
    _lastOtp = null; // Clear previous OTP
    notifyListeners();

    try {
      final response = await _apiService.sendOtp(mobileNumber);
      _lastOtp = response.otp; // Store OTP for development display
      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      _lastOtp = null;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and login
  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyOtp(mobileNumber, otp);
      _user = response.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.clearAll();
      _user = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user data
  void updateUser(UserModel user) {
    _user = user;
    _storageService.saveUserData(user);
    notifyListeners();
  }
}

