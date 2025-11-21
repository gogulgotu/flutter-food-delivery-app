import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_dashboard_provider.dart';
import '../../screens/auth/phone_number_screen.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../models/notification_model.dart';
import '../../models/wallet_model.dart';
import '../../widgets/oval_bottom_nav_bar.dart';
import 'customer_home_screen.dart';

/// Customer Dashboard Screen
/// 
/// Main dashboard for customers with overview of activity, orders, wallet, and notifications
class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerDashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Food Delivery'),
            if (user != null)
              Text(
                'Welcome, ${user.firstName ?? user.phoneNumber ?? "User"}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          Consumer<CustomerDashboardProvider>(
            builder: (context, provider, _) {
              final unreadCount = provider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3; // Navigate to notifications tab
                      });
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              } else if (value == 'profile') {
                setState(() {
                  _selectedIndex = 4; // Navigate to profile tab
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive layout based on screen size
          Widget content;
          if (isDesktop) {
            content = _buildDesktopLayout();
          } else if (isTablet) {
            content = _buildTabletLayout();
          } else {
            content = _buildMobileLayout();
          }
          
          // Add bottom padding for all screens to prevent overlap with oval nav bar
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: content,
          );
        },
      ),
      bottomNavigationBar: OvalBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          OvalNavBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          OvalNavBarItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: 'Orders',
          ),
          OvalNavBarItem(
            icon: Icons.wallet_outlined,
            activeIcon: Icons.wallet,
            label: 'Wallet',
          ),
          OvalNavBarItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            label: 'Notifications',
          ),
          OvalNavBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const CustomerHomeScreen(), // Catalog home screen
        _buildOrdersTab(),
        _buildWalletTab(),
        _buildNotificationsTab(),
        _buildProfileTab(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    // Use same layout as mobile but with adaptive spacing
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const CustomerHomeScreen(), // Catalog home screen
        _buildOrdersTab(),
        _buildWalletTab(),
        _buildNotificationsTab(),
        _buildProfileTab(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    // Use same layout as mobile/tablet but with adaptive spacing
    // The oval navbar will be at the bottom for all screen sizes
    return IndexedStack(
      index: _selectedIndex,
      children: [
        const CustomerHomeScreen(), // Catalog home screen
        _buildOrdersTab(),
        _buildWalletTab(),
        _buildNotificationsTab(),
        _buildProfileTab(),
      ],
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () => context.read<CustomerDashboardProvider>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Consumer<CustomerDashboardProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.wallet == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Balance Card
                _buildWalletBalanceCard(provider),
                const SizedBox(height: 16),
                
                // Quick Stats Row
                _buildQuickStatsRow(provider),
                const SizedBox(height: 24),
                
                // Recent Orders Section
                _buildRecentOrdersSection(provider),
                const SizedBox(height: 24),
                
                // Recent Notifications Section
                _buildRecentNotificationsSection(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard(CustomerDashboardProvider provider) {
    final wallet = provider.wallet;
    final isLoading = provider.isLoadingWallet;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen,
              AppTheme.primaryGreenDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: isLoading
                      ? null
                      : () => provider.loadWalletBalance(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (wallet != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${wallet.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallet.currency,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '₹0.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (provider.walletError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        provider.walletError!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 2; // Navigate to wallet tab
                });
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Transactions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(CustomerDashboardProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return isWide
            ? Row(
                children: [
                  Expanded(child: _buildStatCard('Active Orders', provider.recentOrders.where((o) => o.isActive).length.toString(), Icons.receipt_long, AppTheme.primaryGreen)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Unread Notifications', provider.unreadCount.toString(), Icons.notifications, AppTheme.accentYellow)),
                ],
              )
            : Column(
                children: [
                  _buildStatCard('Active Orders', provider.recentOrders.where((o) => o.isActive).length.toString(), Icons.receipt_long, AppTheme.primaryGreen),
                  const SizedBox(height: 16),
                  _buildStatCard('Unread Notifications', provider.unreadCount.toString(), Icons.notifications, AppTheme.accentYellow),
                ],
              );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(CustomerDashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1; // Navigate to orders tab
                });
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.isLoadingOrders)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (provider.recentOrders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your order history will appear here',
                    style: TextStyle(color: AppTheme.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...provider.recentOrders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to order details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (order.vendor != null)
                          Text(
                            order.vendor!.name,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.orderStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(order.orderStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(order.orderPlacedAt),
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotificationsSection(CustomerDashboardProvider provider) {
    final recentNotifications = provider.notifications.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 3; // Navigate to notifications tab
                });
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.isLoadingNotifications)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recentNotifications.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: AppTheme.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...recentNotifications.map((notification) =>
              _buildNotificationCard(notification)),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? null : AppTheme.bgSectionGreen.withOpacity(0.3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type)
              .withOpacity(0.1),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          // TODO: Handle notification tap
        },
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Consumer<CustomerDashboardProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.loadRecentOrders(),
          child: provider.isLoadingOrders
              ? const Center(child: CircularProgressIndicator())
              : provider.recentOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your order history will appear here',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.recentOrders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(provider.recentOrders[index]);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildWalletTab() {
    return Consumer<CustomerDashboardProvider>(
      builder: (context, provider, _) {
        // Load transactions when wallet tab is accessed
        if (provider.walletTransactions.isEmpty && !provider.isLoadingWallet) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadWalletTransactions();
          });
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadWalletBalance();
            await provider.loadWalletTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWalletBalanceCard(provider),
                const SizedBox(height: 24),
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (provider.walletTransactions.isEmpty && !provider.isLoadingWallet)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 64, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (provider.isLoadingWallet && provider.walletTransactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ...provider.walletTransactions.map((transaction) =>
                      _buildTransactionCard(transaction)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isCredit
              ? AppTheme.success.withOpacity(0.1)
              : AppTheme.error.withOpacity(0.1),
          child: Icon(
            transaction.isCredit ? Icons.add : Icons.remove,
            color: transaction.isCredit ? AppTheme.success : AppTheme.error,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdOn),
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
        ),
        trailing: Text(
          '${transaction.isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: transaction.isCredit ? AppTheme.success : AppTheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Consumer<CustomerDashboardProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            if (provider.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppTheme.bgSectionGreen,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.unreadCount} unread notification${provider.unreadCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.markAllNotificationsAsRead(),
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.loadNotifications(),
                child: provider.isLoadingNotifications
                    ? const Center(child: CircularProgressIndicator())
                    : provider.notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none,
                                    size: 64, color: AppTheme.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                  'No notifications',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You\'re all caught up!',
                                  style: TextStyle(color: AppTheme.textTertiary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.notifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationCard(
                                  provider.notifications[index]);
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.phoneNumber ?? '',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildProfileMenuItem(
            Icons.person_outline,
            'Edit Profile',
            () {
              // TODO: Navigate to edit profile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile feature coming soon')),
              );
            },
          ),
          _buildProfileMenuItem(
            Icons.location_on_outlined,
            'Addresses',
            () {
              // TODO: Navigate to addresses
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Addresses feature coming soon')),
              );
            },
          ),
          _buildProfileMenuItem(
            Icons.payment_outlined,
            'Payment Methods',
            () {
              // TODO: Navigate to payment methods
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment methods feature coming soon')),
              );
            },
          ),
          _buildProfileMenuItem(
            Icons.wallet_outlined,
            'Wallet',
            () {
              setState(() {
                _selectedIndex = 2; // Navigate to wallet tab
              });
            },
          ),
          _buildProfileMenuItem(
            Icons.help_outline,
            'Help & Support',
            () {
              // TODO: Navigate to help
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support feature coming soon')),
              );
            },
          ),
          _buildProfileMenuItem(
            Icons.logout,
            'Logout',
            () => _handleLogout(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.error : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? AppTheme.error : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warning;
      case 'confirmed':
      case 'preparing':
        return AppTheme.primaryGreen;
      case 'out_for_delivery':
        return AppTheme.accentYellow;
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return AppTheme.primaryGreen;
      case 'promotion':
        return AppTheme.accentYellow;
      case 'payment':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.receipt_long;
      case 'promotion':
        return Icons.local_offer;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dashboardProvider =
          Provider.of<CustomerDashboardProvider>(context, listen: false);
      dashboardProvider.clear();
      await authProvider.logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
        (route) => false,
      );
    }
  }
}
