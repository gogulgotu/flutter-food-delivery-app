import 'package:flutter/foundation.dart';
import '../models/wallet_model.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

/// Customer Dashboard Provider
/// 
/// Manages state for customer dashboard including wallet, orders, and notifications
class CustomerDashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Wallet
  WalletModel? _wallet;
  List<WalletTransactionModel> _walletTransactions = [];
  bool _isLoadingWallet = false;
  String? _walletError;

  // Notifications
  List<NotificationModel> _notifications = [];
  bool _isLoadingNotifications = false;
  String? _notificationsError;
  int _unreadCount = 0;

  // Orders
  List<OrderModel> _recentOrders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  // Getters
  WalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get walletTransactions => _walletTransactions;
  bool get isLoadingWallet => _isLoadingWallet;
  String? get walletError => _walletError;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoadingNotifications => _isLoadingNotifications;
  String? get notificationsError => _notificationsError;
  int get unreadCount => _unreadCount;

  List<OrderModel> get recentOrders => _recentOrders;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;

  bool get isLoading =>
      _isLoadingWallet || _isLoadingNotifications || _isLoadingOrders;

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    // Wallet feature is disabled - coming soon
    await Future.wait([
      // loadWalletBalance(), // Disabled - coming soon
      loadRecentOrders(),
      loadNotifications(),
    ]);
  }

  /// Load wallet balance
  /// ⚠️ DISABLED: Wallet feature coming soon
  @Deprecated('Wallet feature is coming soon')
  Future<void> loadWalletBalance() async {
    // Wallet feature is disabled - coming soon
    // Do nothing to prevent API calls
    _isLoadingWallet = false;
    _walletError = null;
    _wallet = null;
  }

  /// Load wallet transactions
  /// ⚠️ DISABLED: Wallet feature coming soon
  @Deprecated('Wallet feature is coming soon')
  Future<void> loadWalletTransactions({int page = 1, int pageSize = 10}) async {
    // Wallet feature is disabled - coming soon
    // Do nothing to prevent API calls
    _walletTransactions = [];
    _walletError = null;
  }

  /// Load recent orders (limit to 5 most recent)
  Future<void> loadRecentOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      final data = await _apiService.getOrders(page: 1, pageSize: 5);
      final results = (data['results'] as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
      _recentOrders = results;
      _ordersError = null;
    } catch (e) {
      _ordersError = e.toString();
      _recentOrders = [];
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  /// Load notifications
  Future<void> loadNotifications({int page = 1, bool? isRead}) async {
    _isLoadingNotifications = true;
    _notificationsError = null;
    notifyListeners();

    try {
      final data = await _apiService.getNotifications(page: page, isRead: isRead);
      final results = (data['results'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      if (page == 1) {
        _notifications = results;
      } else {
        _notifications.addAll(results);
      }
      
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      _notificationsError = null;
    } catch (e) {
      _notificationsError = e.toString();
      if (page == 1) {
        _notifications = [];
      }
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Clear all data
  void clear() {
    _wallet = null;
    _walletTransactions = [];
    _notifications = [];
    _recentOrders = [];
    _unreadCount = 0;
    _walletError = null;
    _notificationsError = null;
    _ordersError = null;
    notifyListeners();
  }
}

