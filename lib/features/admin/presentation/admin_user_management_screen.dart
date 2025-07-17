import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../models/user_management_model.dart' as admin_models;
import '../widgets/admin_bottom_navigation.dart';
import '../../user/models/user_model.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadUsers(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(controller),
          
          // Filter Chips
          _buildFilterChips(controller),
          
          // User List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingUsers && controller.users.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter users based on current filter type
              List<admin_models.AdminUserModel> filteredUsers = [];
              
              if (controller.searchResults.isNotEmpty) {
                // Use search results if available
                filteredUsers = controller.searchResults
                    .whereType<admin_models.AdminUserModel>()
                    .toList();
              } else {
                // Apply filter to all users
                filteredUsers = _getFilteredUsers(controller.users, controller.userFilterType);
              }

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users found for "${controller.userFilterType}" filter',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          controller.setUserFilterType('all');
                        },
                        child: const Text('Show All Users'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadUsers(refresh: true),
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildEnhancedUserCard(user, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1),
    );
  }
  
  Widget _buildSearchAndFilterBar(AdminDashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                controller.changeSearchType('users');
                controller.search(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter users',
            onSelected: (value) {
              controller.setUserFilterType(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Users')),
              const PopupMenuItem(value: 'active', child: Text('Active Users')),
              const PopupMenuItem(value: 'restricted', child: Text('Restricted Users')),
              const PopupMenuItem(value: 'suspended', child: Text('Suspended Users')),
              const PopupMenuItem(value: 'banned', child: Text('Banned Users')),
              const PopupMenuItem(value: 'suspicious', child: Text('Suspicious Users')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips(AdminDashboardController controller) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final currentFilter = controller.userFilterType;
        
        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip('All', 'all', currentFilter, controller),
            _buildFilterChip('Active', 'active', currentFilter, controller),
            _buildFilterChip('Restricted', 'restricted', currentFilter, controller),
            _buildFilterChip('Suspicious', 'suspicious', currentFilter, controller),
            _buildFilterChip('Suspended', 'suspended', currentFilter, controller),
            _buildFilterChip('Banned', 'banned', currentFilter, controller),
          ],
        );
      }),
    );
  }
  
  Widget _buildFilterChip(String label, String value, String currentFilter, AdminDashboardController controller) {
    final isSelected = currentFilter == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => controller.setUserFilterType(value),
        backgroundColor: Colors.grey.shade200,
        selectedColor: const Color(0xFF1565C0).withOpacity(0.2),
        checkmarkColor: const Color(0xFF1565C0),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Helper method to filter users based on filter type
  List<admin_models.AdminUserModel> _getFilteredUsers(List<admin_models.AdminUserModel> users, String filterType) {
    switch (filterType) {
      case 'active':
        return users.where((user) => user.userStatus == 'active' && !user.isRestricted).toList();
      case 'restricted':
        return users.where((user) => user.isRestricted || user.userStatus == 'restricted').toList();
      case 'suspended':
        return users.where((user) => user.userStatus == 'suspended').toList();
      case 'banned':
        return users.where((user) => user.userStatus == 'banned').toList();
      case 'suspicious':
        return users.where((user) => user.isSuspicious).toList();
      default:
        return users;
    }
  }

  Widget _buildEnhancedUserCard(admin_models.AdminUserModel user, AdminDashboardController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getUserStatusColor(user),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: _buildUserAvatar(user, controller),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildUserStatusChip(user),
                if (user.isSuspicious) ...[
                  _buildStatusChip('Suspicious', Colors.orange),
                ],
                if (user.flags.isNotEmpty) ...[
                  _buildStatusChip('${user.flags.length} Flag${user.flags.length > 1 ? 's' : ''}', Colors.purple),
                ],
              ],
            ),
          ],
        ),
        trailing: _buildUserScoreBadge(user),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Stats
                _buildUserStatsSection(user),
                
                const Divider(height: 24),
                
                // User Info
                _buildUserInfoSection(user),
                
                if (user.flags.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildUserFlagsSection(user, controller),
                ],
                
                if (user.restrictions.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildUserRestrictionsSection(user),
                ],
                
                const Divider(height: 24),
                
                // Action Buttons
                _buildActionButtons(user, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(admin_models.AdminUserModel user, AdminDashboardController controller) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user.profileImageUrl!),
        backgroundColor: Colors.grey.shade200,
      );
    } else {
      return CircleAvatar(
        radius: 24,
        backgroundColor: controller.getPriorityColor(user),
        child: Text(
          (user.fullName.isNotEmpty ? user.fullName.substring(0, 1) : user.email.substring(0, 1)).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }
  }
  
  Widget _buildUserScoreBadge(admin_models.AdminUserModel user) {
    final score = user.userScore;
    Color color;
    
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.lightGreen;
    } else if (score >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          score.toInt().toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserStatsSection(admin_models.AdminUserModel user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Total Ads', user.totalAds.toString()),
        ),
        Expanded(
          child: _buildStatItem('Active Ads', user.activeAds.toString()),
        ),
        Expanded(
          child: _buildStatItem('Total Bids', user.totalBids.toString()),
        ),
        Expanded(
          child: _buildStatItem('Active Bids', user.activeBids.toString()),
        ),
      ],
    );
  }
  
  Widget _buildUserInfoSection(admin_models.AdminUserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Username', user.username),
        _buildInfoRow(
          'Joined',
          _formatDate(user.createdAt.toDate()),
        ),
        _buildInfoRow(
          'Last Updated',
          _formatDate(user.updatedAt.toDate()),
        ),
        if (user.lastLoginAt != null) 
          _buildInfoRow(
            'Last Login',
            _formatDate(user.lastLoginAt!.toDate()),
          ),
        _buildInfoRow('Status', user.userStatus),
        _buildInfoRow('Total Sales', '${user.totalSales}'),
        _buildInfoRow('Total Purchases', '${user.totalPurchases}'),
      ],
    );
  }
  
  Widget _buildUserFlagsSection(admin_models.AdminUserModel user, AdminDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Flags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: user.flags.map((flag) {
            return Chip(
              label: Text(flag),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _showRemoveFlagConfirmation(user, flag, controller),
              backgroundColor: Colors.amber.withOpacity(0.2),
              deleteIconColor: Colors.amber.shade700,
              labelStyle: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildUserRestrictionsSection(admin_models.AdminUserModel user) {
    // Separate active and past restrictions with better logic
    final activeRestrictions = user.restrictions
        .where((r) => r.isActive && !r.isExpired)
        .toList();
    final pastRestrictions = user.restrictions
        .where((r) => !r.isActive || r.isExpired)
        .toList();
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'User Restrictions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (activeRestrictions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  '${activeRestrictions.length} Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (activeRestrictions.isEmpty && pastRestrictions.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'No restrictions on this user',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (activeRestrictions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Active Restrictions:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...activeRestrictions.map((r) => _buildRestrictionItem(r, isActive: true)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        if (pastRestrictions.isNotEmpty) ...[
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Icon(Icons.history, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Past Restrictions (${pastRestrictions.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: pastRestrictions.take(5).map((r) => _buildRestrictionItem(r, isActive: false)).toList(),
                ),
              ),
              if (pastRestrictions.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${pastRestrictions.length - 5} more past restrictions',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildRestrictionItem(admin_models.UserRestrictionModel restriction, {required bool isActive}) {
    final typeText = restriction.restrictionType.replaceAll('_', ' ');
    final formattedType = typeText.split(' ').map((word) => 
      word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
    
    Color statusColor = isActive ? Colors.red : Colors.grey;
    IconData statusIcon = isActive ? Icons.warning : Icons.history;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.red.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      formattedType,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (isActive && restriction.expiresAt != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Until ${_formatDate(restriction.expiresAt!.toDate())}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ] else if (isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Permanent',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (restriction.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    restriction.reason,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Applied: ${_formatDate(restriction.createdAt.toDate())}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(admin_models.AdminUserModel user, AdminDashboardController controller) {
    final activeRestrictions = user.restrictions
        .where((r) => r.isActive && !r.isExpired)
        .toList();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Status-based action buttons
        if (user.userStatus == 'active' && !user.isRestricted) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.block, size: 16),
            label: const Text('Suspend'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showRestrictionDialog(
              user,
              controller,
              'suspended',
            ),
          ),
          if (user.flags.isEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.warning, size: 16),
              label: const Text('Flag'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showFlagDialog(user, controller),
            ),
        ],
        
        if (user.isRestricted && activeRestrictions.isNotEmpty) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 16),
            label: Text('Remove ${activeRestrictions.length > 1 ? 'Restrictions' : 'Restriction'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showRemoveRestrictionDialog(user, controller),
          ),
        ],
        
        if (user.userStatus == 'suspended') ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle, size: 16),
            label: const Text('Reactivate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showRemoveRestrictionDialog(user, controller),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.block, size: 16),
            label: const Text('Ban'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showRestrictionDialog(
              user,
              controller,
              'banned',
            ),
          ),
        ],
        
        if (user.flags.isNotEmpty) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.flag_outlined, size: 16),
            label: Text('Manage Flags (${user.flags.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showManageFlagsDialog(user, controller),
          ),
        ],
        
        // Admin notes
        ElevatedButton.icon(
          icon: const Icon(Icons.note_add, size: 16),
          label: const Text('Add Note'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _showAddNoteDialog(user, controller),
        ),
        
        // View details
        OutlinedButton.icon(
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View Details'),
          onPressed: () => _showUserDetailsDialog(user),
        ),
        
        // Delete button (always available but with confirmation)
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever, size: 16),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _showDeleteDialog(user, controller),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  Color _getUserStatusColor(admin_models.AdminUserModel user) {
    switch (user.userStatus) {
      case 'banned':
        return Colors.red.shade800;
      case 'suspended':
        return Colors.red.shade400;
      case 'restricted':
        return Colors.orange;
      case 'deactivated':
        return Colors.grey;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Dialog methods
  void _showRestrictionDialog(
    admin_models.AdminUserModel user,
    AdminDashboardController controller,
    String initialRestrictionType,
  ) {
    final reasonController = TextEditingController();
    final restrictionTypeValue = initialRestrictionType.obs;
    final expiryDate = Rxn<DateTime>();
    final showExpiryDate = false.obs;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restrict User: ${user.fullName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Restriction Type:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              
              Obx(() => Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Suspend Account'),
                    subtitle: const Text('Temporarily disable the account'),
                    value: 'suspended',
                    groupValue: restrictionTypeValue.value,
                    onChanged: (value) {
                      restrictionTypeValue.value = value!;
                      showExpiryDate.value = true;
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Ban Account'),
                    subtitle: const Text('Permanently ban this user'),
                    value: 'banned',
                    groupValue: restrictionTypeValue.value,
                    onChanged: (value) {
                      restrictionTypeValue.value = value!;
                      showExpiryDate.value = false;
                      expiryDate.value = null;
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Restrict Posting'),
                    subtitle: const Text('Limit ability to post new ads'),
                    value: 'restricted_posting',
                    groupValue: restrictionTypeValue.value,
                    onChanged: (value) {
                      restrictionTypeValue.value = value!;
                      showExpiryDate.value = true;
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Restrict Bidding'),
                    subtitle: const Text('Limit ability to place bids'),
                    value: 'restricted_bidding',
                    groupValue: restrictionTypeValue.value,
                    onChanged: (value) {
                      restrictionTypeValue.value = value!;
                      showExpiryDate.value = true;
                    },
                  ),
                ],
              )),
              
              const SizedBox(height: 16),
              
              Obx(() => showExpiryDate.value ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expiry Date:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final selected = await showDatePicker(
                        context: Get.context!,
                        initialDate: now.add(const Duration(days: 30)),
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (selected != null) {
                        expiryDate.value = selected;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              expiryDate.value != null
                                  ? _formatDate(expiryDate.value!)
                                  : 'Select expiry date',
                              style: TextStyle(
                                color: expiryDate.value != null ? Colors.black87 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ) : const SizedBox.shrink()),
              
              const Text(
                'Reason:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason for restriction',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (reasonController.text.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please enter a reason',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      
                      Get.back();
                      controller.handleRestrictUser(
                        user.id,
                        restrictionTypeValue.value,
                        reasonController.text,
                        expiresAt: expiryDate.value,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Restrict User'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFlagDialog(admin_models.AdminUserModel user, AdminDashboardController controller) {
    final reasonController = TextEditingController();
    final selectedFlags = <String>[].obs;
    
    final availableFlags = [
      'spam',
      'suspicious_behavior',
      'fraudulent_activity',
      'policy_violation',
      'multiple_accounts',
      'fake_ads',
      'price_manipulation',
      'identity_concerns',
    ];
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flag User: ${user.fullName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Select flags to apply:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              
              Obx(() => Wrap(
                spacing: 8,
                children: availableFlags.map((flag) {
                  final isSelected = selectedFlags.contains(flag);
                  return FilterChip(
                    label: Text(_formatFlagLabel(flag)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        selectedFlags.add(flag);
                      } else {
                        selectedFlags.remove(flag);
                      }
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.amber.withOpacity(0.2),
                    checkmarkColor: Colors.amber.shade700,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.amber.shade900 : Colors.black87,
                    ),
                  );
                }).toList(),
              )),
              
              const SizedBox(height: 16),
              
              const Text(
                'Reason:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason for flagging',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedFlags.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please select at least one flag',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      
                      if (reasonController.text.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please enter a reason',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      
                      Get.back();
                      controller.handleFlagUser(
                        user.id,
                        selectedFlags,
                        reasonController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Flag User'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveFlagConfirmation(admin_models.AdminUserModel user, String flag, AdminDashboardController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Flag'),
        content: Text('Are you sure you want to remove the "$flag" flag from this user?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.handleRemoveFlag(user.id, flag);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Remove Flag'),
          ),
        ],
      ),
    );
  }

  void _showRemoveRestrictionDialog(admin_models.AdminUserModel user, AdminDashboardController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Restriction'),
        content: Text('Are you sure you want to remove all restrictions from ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.handleRemoveRestriction(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove Restrictions'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(admin_models.AdminUserModel user, AdminDashboardController controller) {
    final noteController = TextEditingController();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Note for ${user.fullName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter admin note',
                ),
                maxLines: 5,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (noteController.text.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please enter a note',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      
                      Get.back();
                      controller.handleAddAdminNotes(
                        user.id,
                        noteController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(dynamic user, AdminDashboardController controller) {
    final reasonController = TextEditingController();
    final userId = user is admin_models.AdminUserModel ? user.id : user.id;
    final userName = user is admin_models.AdminUserModel 
        ? (user.fullName.isNotEmpty ? user.fullName : user.username) 
        : (user.fullName.isNotEmpty ? user.fullName : user.username);
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete User: $userName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Warning: This action cannot be undone. The user account and all associated data will be permanently deleted.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Reason:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason for deletion',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (reasonController.text.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Please enter a reason',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      
                      Get.back();
                      controller.handleDeleteUser(
                        userId,
                        reasonController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete User'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(admin_models.AdminUserModel user) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildUserAvatar(user, Get.find<AdminDashboardController>()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName.isNotEmpty ? user.fullName : user.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(
                              user.userStatus,
                              _getUserStatusColor(user),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildUserScoreBadge(user),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              // Add detailed user information here
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildUserInfoSection(user),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Activity Statistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildUserStatsSection(user),
                    
                    if (user.flags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildUserFlagsSection(user, Get.find<AdminDashboardController>()),
                    ],
                    
                    if (user.restrictions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildUserRestrictionsSection(user),
                    ],
                    
                    // Admin Notes
                    if (user.adminNotes != null && user.adminNotes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Admin Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...user.adminNotes!.entries.map((entry) {
                        final note = entry.value as Map<String, dynamic>;
                        final content = note['content'] as String;
                        final timestamp = note['timestamp'] as Timestamp;
                        final adminId = note['admin_id'] as String;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'By Admin $adminId - ${_formatDate(timestamp.toDate())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatFlagLabel(String flag) {
    return flag.split('_').map((word) => 
      word.substring(0, 1).toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Widget _buildUserStatusChip(admin_models.AdminUserModel user) {
    Color color = _getUserStatusColor(user);
    IconData icon;
    String status = user.userStatus.toUpperCase();
    
    switch (user.userStatus) {
      case 'banned':
        icon = Icons.block;
        break;
      case 'suspended':
        icon = Icons.pause_circle;
        break;
      case 'restricted':
        icon = Icons.warning;
        break;
      case 'active':
        icon = Icons.person;
        break;
      default:
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showManageFlagsDialog(admin_models.AdminUserModel user, AdminDashboardController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Flags for ${user.fullName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Current Flags:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              
              if (user.flags.isEmpty) ...[
                Text(
                  'No flags on this user',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                Wrap(
                  spacing: 8,
                  children: user.flags.map((flag) {
                    return Chip(
                      label: Text(_formatFlagLabel(flag)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        Get.back();
                        _showRemoveFlagConfirmation(user, flag, controller);
                      },
                      backgroundColor: Colors.amber.withOpacity(0.2),
                      deleteIconColor: Colors.amber.shade700,
                      labelStyle: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _showFlagDialog(user, controller);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add New Flag'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
