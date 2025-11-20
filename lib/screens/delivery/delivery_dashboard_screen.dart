import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/phone_number_screen.dart';
import '../../services/api_service.dart';

/// Delivery Person Dashboard Screen
/// 
/// Main dashboard for delivery persons to view assignments, manage status, etc.
class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  bool _isOnline = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.getDeliveryDashboard();
      setState(() {
        _dashboardData = data;
        _isOnline = data['is_online'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      // TODO: Implement API call to toggle online status
      // Use: POST /api/delivery/toggle-online/
      setState(() {
        _isOnline = !_isOnline;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline ? 'You are now online' : 'You are now offline'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        actions: [
          // Online/Offline Toggle
          Switch(
            value: _isOnline,
            onChanged: (value) => _toggleOnlineStatus(),
            activeTrackColor: Colors.green,
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (context) => [
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(),
                _buildActiveDeliveriesTab(),
                _buildHistoryTab(),
                _buildProfileTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_dashboardData == null) {
      return const Center(child: Text('No data available'));
    }

    final deliveryPerson = _dashboardData!['delivery_person'] as Map<String, dynamic>?;
    final todayStats = _dashboardData!['today_stats'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _isOnline ? Colors.green[50] : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.check_circle : Icons.cancel,
                      color: _isOnline ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'You are Online' : 'You are Offline',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isOnline
                                ? 'Ready to accept deliveries'
                                : 'Turn on to start receiving orders',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOnline,
                      onChanged: (value) => _toggleOnlineStatus(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Profile Summary
            if (deliveryPerson != null) ...[
              Text(
                'Your Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(deliveryPerson['user_name'] ?? 'Delivery Person'),
                  subtitle: Text('Rating: ${deliveryPerson['rating'] ?? '0.0'} ⭐'),
                  trailing: Text(
                    '${deliveryPerson['total_deliveries'] ?? 0} deliveries',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Today's Stats
            if (todayStats != null) ...[
              Text(
                'Today\'s Performance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Earnings',
                      '₹${todayStats['earnings']?.toStringAsFixed(0) ?? '0'}',
                      Icons.currency_rupee,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Deliveries',
                      '${todayStats['deliveries'] ?? 0}',
                      Icons.local_shipping,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Distance',
                '${todayStats['distance_km']?.toStringAsFixed(1) ?? '0.0'} km',
                Icons.straighten,
                Colors.orange,
                fullWidth: true,
              ),
            ],
            const SizedBox(height: 24),
            // Active Assignments
            if (_dashboardData!['active_assignments'] != null &&
                (_dashboardData!['active_assignments'] as List).isNotEmpty) ...[
              Text(
                'Active Deliveries',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // TODO: Build active assignments list
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text('Active Deliveries'),
                  subtitle: Text(
                    '${(_dashboardData!['active_assignments'] as List).length} active',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1; // Navigate to active deliveries tab
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: fullWidth
            ? Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                        Text(
                          title,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveDeliveriesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Active Deliveries',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Active deliveries feature coming soon',
            style: TextStyle(color: Colors.grey[500]),
          ),
          // TODO: Implement active deliveries list
          // Use: GET /api/delivery/dashboard/ and parse active_assignments
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Delivery History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Delivery history feature coming soon',
            style: TextStyle(color: Colors.grey[500]),
          ),
          // TODO: Implement delivery history
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Profile Header
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user?.firstName?.substring(0, 1).toUpperCase() ?? 'D',
              style: const TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Delivery Person',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.phoneNumber ?? '',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          // Menu Items
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
            Icons.wallet_outlined,
            'Earnings',
            () {
              // TODO: Navigate to earnings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Earnings feature coming soon')),
              );
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
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
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
      await authProvider.logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
        (route) => false,
      );
    }
  }
}

