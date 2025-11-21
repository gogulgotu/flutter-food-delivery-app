import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';
import '../models/product_model.dart';
import '../models/vendor_category_model.dart';
import '../services/api_service.dart';

/// Catalog Provider
/// 
/// Manages state for vendors and products catalog
class CatalogProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

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
    await Future.wait([
      loadCategories(),
      loadVendorCategories(),
      loadVendors(reset: true),
      loadProducts(reset: true),
    ]);
  }

  /// Load vendors
  Future<void> loadVendors({bool reset = false}) async {
    if (reset) {
      _vendorsPage = 1;
      _vendors = [];
      _hasMoreVendors = true;
    }

    if (!_hasMoreVendors || _isLoadingVendors) return;

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

      final results = (data['results'] as List)
          .map((json) => VendorModel.fromJson(json))
          .toList();

      if (reset) {
        _vendors = results;
      } else {
        _vendors.addAll(results);
      }

      _hasMoreVendors = data['next'] != null;
      _vendorsPage++;
      _vendorsError = null;
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Connection timeout') || 
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

      final results = (data['results'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      if (reset) {
        _products = results;
      } else {
        _products.addAll(results);
      }

      _hasMoreProducts = data['next'] != null;
      _productsPage++;
      _productsError = null;
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Connection timeout') || 
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
    loadVendors(reset: true);
    loadProducts(reset: true);
  }

  /// Set search query
  void setSearchQuery(String? query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadVendors(reset: true);
    loadProducts(reset: true);
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
    await loadCatalog();
  }
}

