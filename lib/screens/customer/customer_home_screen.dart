import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/vendor_model.dart';
import '../../models/product_model.dart';
import '../../models/vendor_category_model.dart';
import '../../utils/image_utils.dart';
import '../../utils/error_utils.dart';
import 'restaurant_details_screen.dart';

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
  String? _selectedFilter;

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
                
                // Filter Section
                _buildFilterSection(),
                
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
    return Consumer<CatalogProvider>(
      builder: (context, provider, _) {
        // Use vendor categories if available, otherwise use product categories
        final vendorCategories = provider.vendorCategories;
        final productCategories = provider.productCategories;
        final hasCategories = vendorCategories.isNotEmpty || productCategories.isNotEmpty;
        
        if (provider.isLoadingCategories && !hasCategories) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!hasCategories) {
          return const SizedBox.shrink();
        }

        // Combine categories - prefer vendor categories
        final categories = vendorCategories.isNotEmpty 
            ? vendorCategories 
            : productCategories;
        final categoryCount = categories.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse by Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryCount,
                  itemBuilder: (context, index) {
                    if (vendorCategories.isNotEmpty) {
                      final category = vendorCategories[index];
                      final isSelected = provider.selectedCategory == category.id;
                      
                      return _buildCategoryItem(
                        category.name,
                        category.icon,
                        isSelected,
                        () {
                          if (isSelected) {
                            provider.setCategory(null);
                          } else {
                            provider.setCategory(category.id);
                          }
                        },
                      );
                    } else {
                      final category = productCategories[index];
                      final isSelected = provider.selectedCategory == category.id;
                      
                      return _buildCategoryItem(
                        category.name,
                        category.icon,
                        isSelected,
                        () {
                          if (isSelected) {
                            provider.setCategory(null);
                          } else {
                            provider.setCategory(category.id);
                          }
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    String name,
    String? iconUrl,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryGreenLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child:                   iconUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ImageUtils.buildNetworkImage(
                        imageUrl: iconUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: 60,
                          height: 60,
                          color: isSelected
                              ? AppTheme.primaryGreen.withOpacity(0.3)
                              : AppTheme.primaryGreenLight.withOpacity(0.1),
                          child: Icon(
                            Icons.category,
                            color: isSelected ? Colors.white : AppTheme.primaryGreen,
                            size: 30,
                          ),
                        ),
                        errorWidget: Icon(
                          Icons.category,
                          color: isSelected ? Colors.white : AppTheme.primaryGreen,
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: isSelected ? Colors.white : AppTheme.primaryGreen,
                      size: 30,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryGreen
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              'Filters',
              Icons.filter_list,
              _selectedFilter == 'filters',
              () {
                setState(() {
                  _selectedFilter = _selectedFilter == 'filters' ? null : 'filters';
                });
                // TODO: Show filter dialog
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Under ₹150',
              null,
              _selectedFilter == 'price',
              () {
                setState(() {
                  _selectedFilter = _selectedFilter == 'price' ? null : 'price';
                });
                // TODO: Apply price filter
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Under 30 mins',
              null,
              _selectedFilter == 'time',
              () {
                setState(() {
                  _selectedFilter = _selectedFilter == 'time' ? null : 'time';
                });
                // TODO: Apply time filter
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Great offer',
              null,
              _selectedFilter == 'offer',
              () {
                setState(() {
                  _selectedFilter = _selectedFilter == 'offer' ? null : 'offer';
                });
                // TODO: Apply offer filter
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData? icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : AppTheme.bgLightGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : AppTheme.textSecondary,
              ),
            ),
            if (icon == Icons.filter_list) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
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
