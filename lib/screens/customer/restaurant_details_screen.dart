import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vendor_details_model.dart';
import '../../models/product_model.dart';
import '../../models/vendor_model.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/product_details_modal.dart';
import 'cart_screen.dart';

/// Restaurant Details Screen
/// 
/// Displays detailed information about a restaurant including menu items
class RestaurantDetailsScreen extends StatefulWidget {
  final VendorModel vendor;

  const RestaurantDetailsScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  final ApiService _apiService = ApiService();
  VendorDetailsModel? _vendorDetails;
  List<ProductModel> _menuItems = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;
  // Track quantity for each product
  final Map<String, int> _productQuantities = {};

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetails();
    // Load cart for this vendor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart(widget.vendor.id);
    });
  }

  Future<void> _loadRestaurantDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load vendor details
      final vendorData = await _apiService.getVendorDetails(widget.vendor.slug);
      _vendorDetails = VendorDetailsModel.fromJson(vendorData);

      // Load menu items for this vendor
      final productsData = await _apiService.getProducts(
        vendor: widget.vendor.id,
        pageSize: 100, // Load all menu items
      );

      final results = (productsData['results'] as List)
          .map((json) {
            try {
              return ProductModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing product: $e');
              return null;
            }
          })
          .whereType<ProductModel>()
          .toList();

      setState(() {
        _menuItems = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          _buildSliverAppBar(),
          
          // Content
          SliverToBoxAdapter(
            child: _isLoading
                ? const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? _buildErrorWidget()
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 32 : isTablet ? 24 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Restaurant Info Section
                            _buildRestaurantInfo(),
                            
                            const SizedBox(height: 24),
                            
                            // Menu Section
                            _buildMenuSection(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.vendor.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            ImageUtils.buildNetworkImage(
              imageUrl: _vendorDetails?.coverImage ?? 
                        _vendorDetails?.image ?? 
                        widget.vendor.image,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: AppTheme.primaryGreen,
                child: const Icon(
                  Icons.restaurant,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    if (_vendorDetails == null) return const SizedBox.shrink();

    final vendor = _vendorDetails!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and Reviews
        Row(
          children: [
            if (vendor.rating != null) ...[
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 20,
                    color: index < (vendor.rating ?? 0).floor()
                        ? AppTheme.accentYellow
                        : Colors.grey[300],
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${vendor.rating?.toStringAsFixed(1) ?? "0.0"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (vendor.totalReviews != null) ...[
                Text(
                  ' (${vendor.totalReviews} reviews)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Description
        if (vendor.description != null && vendor.description!.isNotEmpty) ...[
          Text(
            vendor.description!,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Cuisine Types
        if (vendor.cuisineTypes != null && vendor.cuisineTypes!.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vendor.cuisineTypes!.map((cuisine) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgSectionGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cuisine,
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Info Cards
        _buildInfoCards(vendor),
        
        const SizedBox(height: 16),
        
        // Contact Information
        if (vendor.address != null || vendor.phone != null) ...[
          _buildContactInfo(vendor),
          const SizedBox(height: 16),
        ],
        
        // Operating Hours
        if (vendor.operatingHours != null && vendor.operatingHours!.isNotEmpty) ...[
          _buildOperatingHours(vendor.operatingHours!),
        ],
      ],
    );
  }

  Widget _buildInfoCards(VendorDetailsModel vendor) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time,
            label: 'Delivery Time',
            value: '${vendor.deliveryTime ?? 30}-${(vendor.deliveryTime ?? 30) + 30} min',
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.local_shipping,
            label: 'Delivery Fee',
            value: '₹${(vendor.deliveryFee ?? 0.0).toStringAsFixed(2)}',
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.shopping_bag,
            label: 'Min. Order',
            value: '₹${(vendor.minimumOrder ?? 0.0).toStringAsFixed(2)}',
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSectionGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(VendorDetailsModel vendor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bgGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (vendor.address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 20, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vendor.address!,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (vendor.phone != null) ...[
            Row(
              children: [
                Icon(Icons.phone, size: 20, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  vendor.phone!,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOperatingHours(Map<String, OperatingHours> hours) {
    final dayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bgGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operating Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...hours.entries.map((entry) {
            final dayName = dayNames[entry.key.toLowerCase()] ?? 
                           entry.value.dayName ?? 
                           entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    entry.value.displayTime,
                    style: TextStyle(
                      color: entry.value.isOpen == false 
                          ? AppTheme.error 
                          : AppTheme.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    if (_menuItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                'No menu items available',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get unique categories
    final categories = _menuItems
        .where((item) => item.category != null)
        .map((item) => item.category!)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Category Filter
        if (categories.isNotEmpty) ...[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', null),
                const SizedBox(width: 8),
                ...categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(category, category),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Menu Items Grid
        _buildMenuItemsGrid(),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      selectedColor: AppTheme.primaryGreen,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMenuItemsGrid() {
    final filteredItems = _selectedCategory == null
        ? _menuItems
        : _menuItems.where((item) => item.category == _selectedCategory).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    // Responsive grid columns
    int crossAxisCount = 1; // Mobile: 1 column
    
    if (isDesktop) {
      crossAxisCount = 3;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    // Use GridView with mainAxisExtent instead of aspectRatio to prevent overflow
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: isDesktop ? 340 : isTablet ? 320 : 300, // Compact height fitting content exactly
        crossAxisSpacing: isDesktop ? 16 : isTablet ? 14 : 12,
        mainAxisSpacing: isDesktop ? 16 : isTablet ? 14 : 12,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _buildMenuItemCard(filteredItems[index]);
      },
    );
  }

  Widget _buildMenuItemCard(ProductModel product) {
    final isAvailable = product.isAvailable;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;
    final quantity = _productQuantities[product.id] ?? 0;
    
    // Unified card design matching product detail page format
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? Colors.transparent : AppTheme.bgGray.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Ensures content doesn't overflow rounded corners
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Minimize height to content
          children: [
            // Product Image with Badges (matching detail page)
            _buildProductImage(product, isAvailable, isDesktop, isTablet),
            
            // Product Details - Compact with no empty space
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 12 : isTablet ? 10 : 8,  // left
                isDesktop ? 10 : isTablet ? 8 : 6,   // top
                isDesktop ? 12 : isTablet ? 10 : 8,  // right
                isDesktop ? 10 : isTablet ? 8 : 6,   // bottom - reduced to eliminate empty space
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? AppTheme.textPrimary : AppTheme.textMuted,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isDesktop ? 4 : 3),
                  
                  // Description (truncated) - only show if exists
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: isDesktop ? 11 : 10,
                        color: AppTheme.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isDesktop ? 5 : 4),
                  ] else
                    SizedBox(height: isDesktop ? 2 : 1),
                  
                  // Price and Quantity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price Section
                      _buildPriceSection(product, isAvailable, isDesktop, isTablet),
                      
                      SizedBox(width: isDesktop ? 10 : 8),
                      
                      // Compact Quantity Selector
                      if (isAvailable)
                        _buildCompactQuantitySelector(product, quantity, isDesktop, isTablet),
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

  Widget _buildProductImage(ProductModel product, bool isAvailable, bool isDesktop, bool isTablet) {
    final imageHeight = isDesktop ? 200.0 : isTablet ? 180.0 : 160.0; // Larger full-size image
    final imagePadding = isDesktop ? 12.0 : isTablet ? 10.0 : 8.0;
    
    return Container(
      height: imageHeight,
      padding: EdgeInsets.all(imagePadding),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          // Main Image with padding - matches product detail modal
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: isAvailable ? 1.0 : 0.6,
              child: ImageUtils.buildNetworkImage(
                imageUrl: product.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: AppTheme.bgGray,
                  child: Icon(
                    Icons.fastfood,
                    size: isDesktop ? 56 : 40,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),
        
          // Discount Badge (top-left) - positioned inside padded image
          if (product.hasDiscount)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 8 : 7,
                  vertical: isDesktop ? 5 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${((1 - product.effectivePrice / product.price) * 100).toStringAsFixed(0)}% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 11 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Availability Badge (top-right) - positioned inside padded image
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 10 : 8,
                vertical: isDesktop ? 5 : 4,
              ),
              decoration: BoxDecoration(
                color: isAvailable ? AppTheme.primaryGreen : AppTheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 11 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(ProductModel product, bool isAvailable, bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Strikethrough original price if discounted
        if (product.hasDiscount)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isDesktop ? 12 : 11,
                color: AppTheme.textMuted,
                decoration: TextDecoration.lineThrough,
                height: 1.0,
              ),
            ),
          ),
        
        // Effective Price (prominent)
        Text(
          '₹${product.effectivePrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: isAvailable ? AppTheme.primaryGreen : AppTheme.textMuted,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactQuantitySelector(ProductModel product, int quantity, bool isDesktop, bool isTablet) {
    void updateQuantity(int newQuantity) {
      setState(() {
        if (newQuantity == 0) {
          _productQuantities.remove(product.id);
        } else {
          _productQuantities[product.id] = newQuantity;
        }
      });
      
      // Show bottom sheet when quantity > 0
      if (newQuantity > 0) {
        _showAddToCartBottomSheet(product);
      }
    }
    
    if (quantity == 0) {
      // Show compact Add button
      return InkWell(
        onTap: () => updateQuantity(1),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 16 : isTablet ? 14 : 12,
            vertical: isDesktop ? 10 : isTablet ? 9 : 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'ADD',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 13 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Show compact quantity selector
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          InkWell(
            onTap: () => updateQuantity(quantity - 1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 10 : 8,
                vertical: isDesktop ? 10 : isTablet ? 9 : 8,
              ),
              child: Icon(
                Icons.remove,
                color: Colors.white,
                size: isDesktop ? 18 : 16,
              ),
            ),
          ),
          // Quantity display
          Container(
            constraints: BoxConstraints(minWidth: isDesktop ? 32 : 28),
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 6),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 14 : 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Increase button
          InkWell(
            onTap: () => updateQuantity(quantity + 1),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 10 : 8,
                vertical: isDesktop ? 10 : isTablet ? 9 : 8,
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: isDesktop ? 18 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartBottomSheet(ProductModel product) {
    final quantity = _productQuantities[product.id] ?? 0;
    if (quantity == 0) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Product info
              Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ImageUtils.buildNetworkImage(
                      imageUrl: product.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.bgGray,
                        child: const Icon(Icons.fastfood, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$quantity × ₹${product.effectivePrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Total price
                  Text(
                    '₹${(product.effectivePrice * quantity).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Add to Cart button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    _addSingleItemToCart(product, quantity);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add $quantity ${quantity == 1 ? "Item" : "Items"} to Cart',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSingleItemToCart(ProductModel product, int quantity) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final success = await cartProvider.addToCart(
      productId: product.id,
      quantity: quantity,
      vendorId: widget.vendor.id,
    );
    
    if (success && mounted) {
      setState(() {
        _productQuantities.remove(product.id); // Reset quantity after adding
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} ($quantity ${quantity == 1 ? "item" : "items"}) added to cart'
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ),
      );
    } else if (!success && mounted) {
      final errorMsg = cartProvider.error ?? 'Failed to add to cart';
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: errorMsg.contains('log in')
              ? SnackBarAction(
                  label: 'LOGIN',
                  textColor: Colors.white,
                  onPressed: () {
                    scaffoldMessenger.hideCurrentSnackBar();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _addAllSelectedToCart() async {
    if (_productQuantities.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    int successCount = 0;
    int failCount = 0;
    
    try {
      // Add all selected items to cart
      for (var entry in _productQuantities.entries) {
        final success = await cartProvider.addToCart(
          productId: entry.key,
          quantity: entry.value,
          vendorId: widget.vendor.id,
        );
        
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (mounted) {
        setState(() {
          _productQuantities.clear(); // Reset all quantities after adding
        });

        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount ${successCount == 1 ? "item" : "items"} added to cart'),
              backgroundColor: AppTheme.primaryGreen,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'VIEW CART',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (failCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add $failCount ${failCount == 1 ? "item" : "items"}'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showProductDetails(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsModal(
        product: product,
        vendorId: widget.vendor.id,
      ),
    ).then((addedToCart) {
      // Refresh cart when item was added from modal
      if (addedToCart == true) {
        context.read<CartProvider>().refreshCart();
      }
    });
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load restaurant details',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRestaurantDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

