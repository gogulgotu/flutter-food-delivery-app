import 'package:flutter/material.dart';
import '../../models/vendor_details_model.dart';
import '../../models/product_model.dart';
import '../../models/vendor_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetails();
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _buildMenuItemCard(filteredItems[index]);
      },
    );
  }

  Widget _buildMenuItemCard(ProductModel product) {
    final isAvailable = product.isAvailable;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.transparent : AppTheme.bgGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Opacity(
                  opacity: isAvailable ? 1.0 : 0.5,
                  child: ImageUtils.buildNetworkImage(
                    imageUrl: product.image,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 120,
                      color: AppTheme.bgGray,
                      child: const Icon(
                        Icons.fastfood,
                        size: 32,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              // Availability Badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppTheme.primaryGreen : AppTheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Discount Badge
              if (product.hasDiscount)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            ],
          ),
          
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.black : AppTheme.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isAvailable 
                            ? AppTheme.textSecondary 
                            : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.hasDiscount) ...[
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          Text(
                            '₹${product.effectivePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isAvailable 
                                  ? AppTheme.primaryGreen 
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (isAvailable)
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              // TODO: Add to cart
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

