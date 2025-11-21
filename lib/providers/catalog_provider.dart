import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';
import '../models/product_model.dart';
import '../models/vendor_category_model.dart';
import '../services/api_service.dart';
import '../utils/error_utils.dart';

/// Catalog Provider
/// 
/// Manages state for vendors and products catalog
class CatalogProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Request management
  Timer? _debounceTimer;
  DateTime? _lastVendorsFetch;
  DateTime? _lastProductsFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _minRequestInterval = Duration(seconds: 2);
  bool _isRequestInProgress = false;

  // Vendors
  List<VendorModel> _vendors = [];
  bool _isLoadingVendors = false;
  String? _vendorsError;
  bool _hasMoreVendors = true;
  int _vendorsPage = 1;
  final int _vendorsPageSize = 20;

  // Products
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;
  bool _hasMoreProducts = true;
  int _productsPage = 1;
  final int _productsPageSize = 20;

  // Categories
  List<ProductCategoryModel> _productCategories = [];
  List<VendorCategoryModel> _vendorCategories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  // Filters
  String? _selectedCategory;
  String? _searchQuery;
  bool _showFeaturedOnly = false;

  // Getters
  List<VendorModel> get vendors => _vendors;
  bool get isLoadingVendors => _isLoadingVendors;
  String? get vendorsError => _vendorsError;
  bool get hasMoreVendors => _hasMoreVendors;

  List<ProductModel> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;
  bool get hasMoreProducts => _hasMoreProducts;

  List<ProductCategoryModel> get productCategories => _productCategories;
  List<VendorCategoryModel> get vendorCategories => _vendorCategories;
  List<ProductCategoryModel> get categories => _productCategories; // For backward compatibility
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;

  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  bool get showFeaturedOnly => _showFeaturedOnly;

  bool get isLoading => _isLoadingVendors || _isLoadingProducts || _isLoadingCategories;

  /// Load all catalog data
  Future<void> loadCatalog() async {
    // Prevent concurrent requests
    if (_isRequestInProgress) return;
    _isRequestInProgress = true;

    try {
      // Load categories first (usually faster)
      await loadCategories();
      await loadVendorCategories();
      
      // Add small delay between requests to avoid throttling
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load vendors and products with delay
      await loadVendors(reset: true);
      await Future.delayed(const Duration(milliseconds: 500));
      await loadProducts(reset: true);
    } finally {
      _isRequestInProgress = false;
    }
  }

  /// Load vendors
  Future<void> loadVendors({bool reset = false}) async {
    if (reset) {
      _vendorsPage = 1;
      _vendors = [];
      _hasMoreVendors = true;
    }

    if (!_hasMoreVendors || _isLoadingVendors) return;

    // Check cache - use cached data if available and recent
    if (!reset && _lastVendorsFetch != null && _vendors.isNotEmpty) {
      final timeSinceLastFetch = DateTime.now().difference(_lastVendorsFetch!);
      if (timeSinceLastFetch < _cacheDuration) {
        // Use cached data, no need to fetch
        return;
      }
    }

    // Prevent too frequent requests
    if (_lastVendorsFetch != null && !reset) {
      final timeSinceLastFetch = DateTime.now().difference(_lastVendorsFetch!);
      if (timeSinceLastFetch < _minRequestInterval) {
        // Wait before making request
        await Future.delayed(_minRequestInterval - timeSinceLastFetch);
      }
    }

    _isLoadingVendors = true;
    _vendorsError = null;
    notifyListeners();

    try {
      final data = await _apiService.getVendors(
        isFeatured: _showFeaturedOnly ? true : null,
        category: _selectedCategory,
        search: _searchQuery,
        page: _vendorsPage,
        pageSize: _vendorsPageSize,
      );

      final results = <VendorModel>[];
      for (var json in data['results'] as List) {
        try {
          results.add(VendorModel.fromJson(json as Map<String, dynamic>));
        } catch (e) {
          // Log parsing error but continue with other vendors
          debugPrint('Error parsing vendor: $e');
          debugPrint('Vendor JSON: $json');
          // Continue to next vendor instead of failing entire request
        }
      }

      if (reset) {
        _vendors = results;
      } else {
        _vendors.addAll(results);
      }

      _hasMoreVendors = data['next'] != null;
      _vendorsPage++;
      _vendorsError = null;
      _lastVendorsFetch = DateTime.now(); // Update cache timestamp
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = e.toString();
      
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      // Handle throttling/rate limiting errors
      if (ErrorUtils.isThrottlingError(errorMessage)) {
        errorMessage = ErrorUtils.formatThrottlingError(errorMessage);
      } else if (errorMessage.contains('Connection timeout') || 
          errorMessage.contains('connectionTimeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (errorMessage.contains('No internet') || 
                 errorMessage.contains('connectionError')) {
        errorMessage = 'No internet connection. Please check your network settings.';
      } else if (errorMessage.contains('Failed host lookup') ||
                 errorMessage.contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      }
      
      _vendorsError = errorMessage;
      if (reset) {
        _vendors = [];
      }
    } finally {
      _isLoadingVendors = false;
      notifyListeners();
    }
  }

  /// Load products
  Future<void> loadProducts({bool reset = false}) async {
    if (reset) {
      _productsPage = 1;
      _products = [];
      _hasMoreProducts = true;
    }

    if (!_hasMoreProducts || _isLoadingProducts) return;

    // Check cache - use cached data if available and recent
    if (!reset && _lastProductsFetch != null && _products.isNotEmpty) {
      final timeSinceLastFetch = DateTime.now().difference(_lastProductsFetch!);
      if (timeSinceLastFetch < _cacheDuration) {
        // Use cached data, no need to fetch
        return;
      }
    }

    // Prevent too frequent requests
    if (_lastProductsFetch != null && !reset) {
      final timeSinceLastFetch = DateTime.now().difference(_lastProductsFetch!);
      if (timeSinceLastFetch < _minRequestInterval) {
        // Wait before making request
        await Future.delayed(_minRequestInterval - timeSinceLastFetch);
      }
    }

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final data = await _apiService.getProducts(
        isFeatured: _showFeaturedOnly ? true : null,
        category: _selectedCategory,
        search: _searchQuery,
        page: _productsPage,
        pageSize: _productsPageSize,
      );

      final results = <ProductModel>[];
      for (var json in data['results'] as List) {
        try {
          results.add(ProductModel.fromJson(json as Map<String, dynamic>));
        } catch (e) {
          // Log parsing error but continue with other products
          debugPrint('Error parsing product: $e');
          debugPrint('Product JSON: $json');
          // Continue to next product instead of failing entire request
        }
      }

      if (reset) {
        _products = results;
      } else {
        _products.addAll(results);
      }

      _hasMoreProducts = data['next'] != null;
      _productsPage++;
      _productsError = null;
      _lastProductsFetch = DateTime.now(); // Update cache timestamp
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = e.toString();
      
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      // Handle throttling/rate limiting errors
      if (ErrorUtils.isThrottlingError(errorMessage)) {
        errorMessage = ErrorUtils.formatThrottlingError(errorMessage);
      } else if (errorMessage.contains('Connection timeout') || 
          errorMessage.contains('connectionTimeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (errorMessage.contains('No internet') || 
                 errorMessage.contains('connectionError')) {
        errorMessage = 'No internet connection. Please check your network settings.';
      } else if (errorMessage.contains('Failed host lookup') ||
                 errorMessage.contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      }
      
      _productsError = errorMessage;
      if (reset) {
        _products = [];
      }
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Load product categories
  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final data = await _apiService.getProductCategories();
      _productCategories = data
          .map((json) => ProductCategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _categoriesError = null;
    } catch (e) {
      _categoriesError = e.toString();
      _productCategories = [];
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Load vendor categories
  Future<void> loadVendorCategories() async {
    try {
      final data = await _apiService.getVendorCategories();
      _vendorCategories = data
          .map((json) => VendorCategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Silently fail for vendor categories
      _vendorCategories = [];
    }
  }

  /// Set category filter
  void setCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    
    // Add small delay to prevent rapid requests
    Future.delayed(const Duration(milliseconds: 300), () {
      loadVendors(reset: true);
      loadProducts(reset: true);
    });
  }

  /// Set search query with debouncing
  void setSearchQuery(String? query) {
    if (_searchQuery == query) return;
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    _searchQuery = query;
    
    // Debounce search - wait 800ms before making request
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      loadVendors(reset: true);
      loadProducts(reset: true);
    });
  }

  /// Toggle featured filter
  void toggleFeaturedOnly() {
    _showFeaturedOnly = !_showFeaturedOnly;
    loadVendors(reset: true);
    loadProducts(reset: true);
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = null;
    _showFeaturedOnly = false;
    loadVendors(reset: true);
    loadProducts(reset: true);
  }

  /// Refresh all data
  Future<void> refresh() async {
    // Clear cache timestamps to force refresh
    _lastVendorsFetch = null;
    _lastProductsFetch = null;
    await loadCatalog();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

