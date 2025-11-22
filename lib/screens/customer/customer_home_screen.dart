import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_dashboard_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/vendor_model.dart';
import '../../models/product_model.dart';
import '../../models/vendor_category_model.dart';
import '../../utils/image_utils.dart';
import '../../utils/error_utils.dart';
import 'restaurant_details_screen.dart';
import 'cart_screen.dart';

/// Customer Home Screen
/// 
/// Main catalog screen displaying categories, vendors, and products
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedLocation = 'Home';

  @override
  void initState() {
    super.initState();
    // Load catalog data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<CatalogProvider>().loadCatalog();
      } catch (e, stackTrace) {
        debugPrint('Error loading catalog: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      final isTablet = screenWidth >= 768;
      final isDesktop = screenWidth >= 1024;

      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () => context.read<CatalogProvider>().refresh(),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: 120, // Space for oval nav bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Header
                _buildLocationHeader(),
                
                // Search Bar with Profile and Wallet Icons
                _buildSearchBarWithIcons(isTablet, isDesktop),
                
                // Browse by Category Section
                _buildCategorySection(),
                
                const SizedBox(height: 24),
                
                // Restaurants Section
                _buildRestaurantsSection(isTablet, isDesktop),
                
                const SizedBox(height: 24),
                
                // Products Section
                _buildProductsSection(isTablet, isDesktop),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error building CustomerHomeScreen: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return a fallback UI
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Something went wrong'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Try to reload
                  setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: Show location picker
                    _showLocationPicker();
                  },
                  child: Row(
                    children: [
                      Text(
                        _selectedLocation ?? 'Home',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '21, Vittal Dass sait street, Kamatchi Amm...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarWithIcons(bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : isTablet ? 24 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Consumer<CatalogProvider>(
              builder: (context, provider, _) {
                return TextField(
                  decoration: InputDecoration(
                    hintText: 'Search "chicken"',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.error),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.mic, color: AppTheme.error),
                          onPressed: () {
                            // TODO: Voice search
                          },
                        ),
                        if (provider.searchQuery != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => provider.setSearchQuery(null),
                          ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.bgLightGray,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
            onChanged: (value) {
              // Debouncing is now handled in the provider
              provider.setSearchQuery(value.isEmpty ? null : value);
            },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Cart Icon with Badge
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final itemCount = cartProvider.itemCount;
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.bgLightGray,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 24,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      if (itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                itemCount > 99 ? '99+' : itemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Wallet Icon
          Consumer<CustomerDashboardProvider>(
            builder: (context, provider, _) {
              return GestureDetector(
                onTap: () {
                  // TODO: Navigate to wallet
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.bgLightGray,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Profile Icon
          Consumer<AuthProvider>(
            builder: (context, provider, _) {
              final user = provider.user;
              return GestureDetector(
                onTap: () {
                  // TODO: Navigate to profile
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.bgLightGray,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.firstName?.substring(0, 1).toUpperCase() ?? 'G',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    return Consumer<CatalogProvider>(
      builder: (context, provider, _) {
        // Use vendor categories if available, otherwise use product categories
        final vendorCategories = provider.vendorCategories;
        final productCategories = provider.productCategories;
        final hasCategories = vendorCategories.isNotEmpty || productCategories.isNotEmpty;

        // Debug logging
        debugPrint('📊 Category Section Build:');
        debugPrint('   Vendor categories: ${vendorCategories.length}');
        debugPrint('   Product categories: ${productCategories.length}');
        debugPrint('   Has categories: $hasCategories');
        debugPrint('   Is loading: ${provider.isLoadingCategories}');
        debugPrint('   Selected category: ${provider.selectedCategory}');

        // Combine categories - prefer vendor categories
        final categories = vendorCategories.isNotEmpty 
            ? vendorCategories 
            : productCategories;

        // Adaptive sizing based on screen size
        final itemWidth = isDesktop ? 90.0 : isTablet ? 85.0 : 80.0;
        final iconSize = isDesktop ? 65.0 : isTablet ? 60.0 : 55.0;
        final fontSize = isDesktop ? 13.0 : isTablet ? 12.5 : 12.0;

        // Always show the category section with at least "All" option
        // Show loading indicator if categories are loading and none exist yet
        final itemCount = hasCategories ? categories.length + 1 : 1; // +1 for "All" option
        
        debugPrint('   Item count: $itemCount (1 for "All" + ${categories.length} categories)');

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : isTablet ? 24 : 16,
            vertical: isDesktop ? 20 : isTablet ? 16 : 12,
          ),
          child: SizedBox(
            height: isDesktop ? 110 : isTablet ? 105 : 100,
            child: provider.isLoadingCategories && !hasCategories
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      // First item is always "All"
                      if (index == 0) {
                        final isSelected = provider.selectedCategory == null;
                        return _buildCategoryItem(
                          'All',
                          null,
                          isSelected,
                          itemWidth,
                          iconSize,
                          fontSize,
                          () {
                            provider.setCategory(null);
                          },
                        );
                      }
                      
                      // Other categories from API
                      if (!hasCategories || categories.isEmpty) {
                        debugPrint('⚠️ No categories available for index $index');
                        return const SizedBox.shrink();
                      }
                      
                      final categoryIndex = index - 1;
                      if (categoryIndex >= categories.length) {
                        debugPrint('⚠️ Category index $categoryIndex is out of bounds (length: ${categories.length})');
                        return const SizedBox.shrink();
                      }
                      
                      // Handle vendor categories
                      if (vendorCategories.isNotEmpty && categoryIndex < vendorCategories.length) {
                        final category = vendorCategories[categoryIndex];
                        final isSelected = provider.selectedCategory == category.id;
                        
                        debugPrint('✅ Building vendor category item: ${category.name} (index: $categoryIndex)');
                        
                        return _buildCategoryItem(
                          category.name,
                          category.icon ?? category.image,
                          isSelected,
                          itemWidth,
                          iconSize,
                          fontSize,
                          () {
                            if (isSelected) {
                              provider.setCategory(null);
                            } else {
                              provider.setCategory(category.id);
                            }
                          },
                        );
                      } 
                      // Handle product categories
                      else if (productCategories.isNotEmpty && categoryIndex < productCategories.length) {
                        final category = productCategories[categoryIndex];
                        final isSelected = provider.selectedCategory == category.id;
                        
                        debugPrint('✅ Building product category item: ${category.name} (index: $categoryIndex)');
                        
                        return _buildCategoryItem(
                          category.name,
                          category.icon ?? category.image,
                          isSelected,
                          itemWidth,
                          iconSize,
                          fontSize,
                          () {
                            if (isSelected) {
                              provider.setCategory(null);
                            } else {
                              provider.setCategory(category.id);
                            }
                          },
                        );
                      }
                      
                      debugPrint('❌ No category found for index $index (categoryIndex: $categoryIndex)');
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    String name,
    String? iconUrl,
    bool isSelected,
    double itemWidth,
    double iconSize,
    double fontSize,
    VoidCallback onTap,
  ) {
    // Use green for "All" category, red for others
    final isAllCategory = name.toLowerCase() == 'all';
    final selectedColor = isAllCategory ? AppTheme.primaryGreen : AppTheme.error;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: itemWidth,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular icon container
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor.withOpacity(0.1)
                    : AppTheme.bgLightGray,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? selectedColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: iconUrl != null && iconUrl.isNotEmpty
                  ? ClipOval(
                      child: ImageUtils.buildNetworkImage(
                        imageUrl: iconUrl,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: iconSize,
                          height: iconSize,
                          color: isSelected
                              ? selectedColor.withOpacity(0.2)
                              : AppTheme.bgGray,
                          child: Icon(
                            _getCategoryIcon(name),
                            color: isSelected ? selectedColor : AppTheme.textSecondary,
                            size: iconSize * 0.5,
                          ),
                        ),
                        errorWidget: Icon(
                          _getCategoryIcon(name),
                          color: isSelected ? selectedColor : AppTheme.textSecondary,
                          size: iconSize * 0.5,
                        ),
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(name),
                      color: isSelected ? selectedColor : AppTheme.textSecondary,
                      size: iconSize * 0.5,
                    ),
            ),
            const SizedBox(height: 8),
            // Category name
            Text(
              name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isAllCategory ? AppTheme.primaryGreen : AppTheme.textPrimary)
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Colored underline for selected category (green for "All", red for others)
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2.5,
                width: itemWidth * 0.5,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon for category based on name
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('all') || name == 'all') {
      return Icons.apps;
    } else if (name.contains('biryani') || name.contains('biriyani')) {
      return Icons.restaurant;
    } else if (name.contains('chicken')) {
      return Icons.fastfood;
    } else if (name.contains('parotta') || name.contains('porotta') || name.contains('paratha')) {
      return Icons.breakfast_dining;
    } else if (name.contains('rice') || name.contains('fried')) {
      return Icons.rice_bowl;
    } else if (name.contains('pizza')) {
      return Icons.local_pizza;
    } else if (name.contains('burger')) {
      return Icons.lunch_dining;
    } else if (name.contains('dessert') || name.contains('sweet')) {
      return Icons.cake;
    } else if (name.contains('drink') || name.contains('beverage')) {
      return Icons.local_drink;
    } else {
      return Icons.category;
    }
  }

  Widget _buildRestaurantsSection(bool isTablet, bool isDesktop) {
    return Consumer<CatalogProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Restaurants',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all restaurants screen
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.isLoadingVendors && provider.vendors.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.vendorsError != null && provider.vendors.isEmpty)
                _buildErrorWidget(
                  provider.vendorsError!,
                  () => provider.loadVendors(reset: true),
                  ErrorUtils.isThrottlingError(provider.vendorsError!),
                )
              else if (provider.vendors.isEmpty)
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_outlined,
                            size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No restaurants found',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.vendors.length,
                    itemBuilder: (context, index) {
                      return _buildRestaurantCard(provider.vendors[index]);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(VendorModel vendor) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsScreen(vendor: vendor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                width: 280,
                height: 140,
                child: ImageUtils.buildNetworkImage(
                  imageUrl: vendor.image,
                  width: 280,
                  height: 140,
                  fit: BoxFit.cover,
                placeholder: Container(
                  height: 140,
                  color: AppTheme.bgGray,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
                  errorWidget: Container(
                    height: 140,
                    color: AppTheme.bgGray,
                    child: const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vendor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (vendor.description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      vendor.description!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 12,
                            color: AppTheme.accentYellow,
                          );
                        }),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${vendor.rating?.toStringAsFixed(1) ?? "0.0"} (0 reviews)',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSectionGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${vendor.deliveryTime ?? 30}-${(vendor.deliveryTime ?? 30) + 30} min',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${(vendor.deliveryFee ?? 0.0).toStringAsFixed(2)} delivery',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(bool isTablet, bool isDesktop) {
    return Consumer<CatalogProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all products screen
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.isLoadingProducts && provider.products.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.productsError != null && provider.products.isEmpty)
                _buildErrorWidget(
                  provider.productsError!,
                  () => provider.loadProducts(reset: true),
                  ErrorUtils.isThrottlingError(provider.productsError!),
                )
              else if (provider.products.isEmpty)
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood_outlined,
                            size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No products found',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(provider.products[index]);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to product details
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 280,
                    height: 160,
                    child: ImageUtils.buildNetworkImage(
                      imageUrl: product.image,
                      width: 280,
                      height: 160,
                      fit: BoxFit.cover,
                    placeholder: Container(
                      height: 160,
                      color: AppTheme.bgGray,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                      errorWidget: Container(
                        height: 160,
                        color: AppTheme.bgGray,
                        child: const Icon(
                          Icons.fastfood,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OFFER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (!product.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.vendor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.vendor!.name,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.hasDiscount)
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textTertiary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '₹${product.effectivePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      if (product.isAvailable)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage, VoidCallback onRetry, bool isThrottling) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isThrottling ? Icons.timer_outlined : Icons.error_outline,
              size: 48,
              color: isThrottling ? AppTheme.warning : AppTheme.error,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isThrottling ? null : onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            if (isThrottling) ...[
              const SizedBox(height: 8),
              Text(
                'Please wait before retrying',
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  setState(() {
                    _selectedLocation = 'Home';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.work),
                title: const Text('Work'),
                onTap: () {
                  setState(() {
                    _selectedLocation = 'Work';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_location),
                title: const Text('Add New Address'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to add address screen
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
