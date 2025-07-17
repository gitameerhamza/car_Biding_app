import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../models/admin_data_models.dart';
import '../widgets/admin_bottom_navigation.dart';
import '../../../core/widgets/safe_layout_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AdminAuthController>();
    final dashboardController = Get.find<AdminDashboardController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dashboardController.refreshAll(),
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      authController.currentAdmin?.email.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                authController.logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: dashboardController.refreshAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(authController),
              
              const SizedBox(height: 24),
              
              // Stats Cards
              Obx(() {
                if (dashboardController.isLoadingStats) {
                  return _buildLoadingCard();
                }

                final stats = dashboardController.stats;
                if (stats == null) {
                  return _buildErrorCard(
                    'No statistics available',
                    'Unable to load dashboard statistics. Please try refreshing.',
                    () => dashboardController.loadStats(),
                  );
                }

                return _buildStatsCards(stats);
              }),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(dashboardController),
              
              // Add bottom padding to account for bottom navigation
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildWelcomeSection(AdminAuthController authController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0),
            const Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.dashboard,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back, ${authController.getRoleDisplayName(authController.currentAdmin?.role ?? '')}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor and manage your platform from here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AdminStatsModel stats) {
    return Column(
      children: [
        // Main stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8, // Increased aspect ratio to give more space
          children: [
            _buildStatCard(
              'Total Users',
              stats.totalUsers.toString(),
              Icons.people,
              Colors.blue,
              subtitle: stats.todayNewUsers > 0 ? '+${stats.todayNewUsers} today' : null,
            ),
            _buildStatCard(
              'Total Ads',
              stats.totalAds.toString(),
              Icons.car_rental,
              Colors.green,
              subtitle: stats.todayNewAds > 0 ? '+${stats.todayNewAds} today' : null,
            ),
            _buildStatCard(
              'Total Bids',
              stats.totalBids.toString(),
              Icons.gavel,
              Colors.orange,
            ),
            _buildStatCard(
              'Active Events',
              stats.totalEvents.toString(),
              Icons.event,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Secondary stats - Use LayoutBuilder to prevent overflow
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final cardWidth = (availableWidth - 16) / 2; // Account for spacing
            
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth,
                    minHeight: 80,
                    maxHeight: 100,
                  ),
                  child: _buildCompactStatCard(
                    'Active Ads',
                    stats.activeAds.toString(),
                    Icons.visibility,
                    Colors.teal,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: cardWidth,
                    minHeight: 80,
                    maxHeight: 100,
                  ),
                  child: _buildCompactStatCard(
                    'Pending Ads',
                    stats.pendingAds.toString(),
                    Icons.pending,
                    Colors.amber,
                  ),
                ),
                if (stats.restrictedUsers != null && stats.restrictedUsers! > 0)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: cardWidth,
                      minHeight: 80,
                      maxHeight: 100,
                    ),
                    child: _buildCompactStatCard(
                      'Restricted',
                      stats.restrictedUsers.toString(),
                      Icons.block,
                      Colors.red,
                    ),
                  ),
                if (stats.suspiciousUsers != null && stats.suspiciousUsers! > 0)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: cardWidth,
                      minHeight: 80,
                      maxHeight: 100,
                    ),
                    child: _buildCompactStatCard(
                      'Suspicious',
                      stats.suspiciousUsers.toString(),
                      Icons.warning,
                      Colors.redAccent,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AdminDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              'Manage Users',
              Icons.people,
              Colors.blue,
              () => Get.offAllNamed('/admin/users'),
            ),
            _buildActionCard(
              'Manage Ads',
              Icons.car_rental,
              Colors.green,
              () => Get.offAllNamed('/admin/ads'),
            ),
            _buildActionCard(
              'Manage Events',
              Icons.event,
              Colors.purple,
              () => Get.offAllNamed('/admin/events'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading dashboard statistics...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title, String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
