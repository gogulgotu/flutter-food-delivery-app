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
    await Future.wait([
      loadWalletBalance(),
      loadRecentOrders(),
      loadNotifications(),
    ]);
  }

  /// Load wallet balance
  Future<void> loadWalletBalance() async {
    _isLoadingWallet = true;
    _walletError = null;
    notifyListeners();

    try {
      final data = await _apiService.getWalletBalance();
      _wallet = WalletModel.fromJson(data);
      _walletError = null;
    } catch (e) {
      _walletError = e.toString();
      _wallet = null;
    } finally {
      _isLoadingWallet = false;
      notifyListeners();
    }
  }

  /// Load wallet transactions
  Future<void> loadWalletTransactions({int page = 1, int pageSize = 10}) async {
    try {
      final data = await _apiService.getWalletTransactions(
        page: page,
        pageSize: pageSize,
      );
      final results = (data['results'] as List)
          .map((json) => WalletTransactionModel.fromJson(json))
          .toList();
      if (page == 1) {
        _walletTransactions = results;
      } else {
        _walletTransactions.addAll(results);
      }
      notifyListeners();
    } catch (e) {
      _walletError = e.toString();
      notifyListeners();
    }
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

