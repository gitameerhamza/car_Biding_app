import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/user_search_controller.dart';
import '../services/search_history_service.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';
import 'widgets/advanced_search_dialog.dart';

class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserSearchController());
    // Initialize search history service if not already done
    Get.put(SearchHistoryService());

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search Users',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: () {
              Get.dialog(const AdvancedSearchDialog());
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Advanced Search',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          _buildFilterChips(controller),
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.searchController.text.trim().isEmpty) {
                return _buildInitialState();
              }

              if (controller.searchResults.isEmpty) {
                return _buildEmptyState(controller.searchController.text);
              }

              return _buildSearchResults(controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(UserSearchController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or username...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: Obx(() => controller.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.clearSearch();
                      },
                    )
                  : const SizedBox.shrink()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              controller.searchUsers(value);
            },
          ),
          // Search suggestions and history
          Obx(() {
            final suggestions = controller.getSearchSuggestions();
            final historyService = Get.find<SearchHistoryService>();
            final history = historyService.searchHistory;
            
            if (controller.searchController.text.trim().isEmpty && history.isNotEmpty) {
              // Show search history when input is empty
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Text(
                            'Recent Searches',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => historyService.clearHistory(),
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...history.take(5).map((searchTerm) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.history,
                        size: 20,
                        color: Colors.grey,
                      ),
                      title: Text(
                        searchTerm,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => historyService.removeFromHistory(searchTerm),
                      ),
                      onTap: () {
                        controller.searchController.text = searchTerm;
                        controller.searchUsers(searchTerm);
                      },
                    )).toList(),
                  ],
                ),
              );
            } else if (suggestions.isNotEmpty && controller.searchController.text.trim().isNotEmpty) {
              // Show suggestions when typing
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: suggestions.map((suggestion) => ListTile(
                    dense: true,
                    leading: Icon(
                      suggestion.startsWith('@') ? Icons.alternate_email : Icons.person,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    title: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      controller.searchController.text = suggestion.startsWith('@') 
                          ? suggestion.substring(1) 
                          : suggestion;
                      controller.searchUsers(controller.searchController.text);
                    },
                  )).toList(),
                ),
              );
            }
            
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChips(UserSearchController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Obx(() {
        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip('All', 'all', controller),
            _buildFilterChip('Active', 'active', controller),
            _buildFilterChip('Recently Joined', 'recent', controller),
            _buildFilterChip('Top Sellers', 'sellers', controller),
            _buildFilterChip('Top Bidders', 'bidders', controller),
          ],
        );
      }),
    );
  }

  Widget _buildFilterChip(String label, String value, UserSearchController controller) {
    final isSelected = controller.selectedFilter.value == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => controller.setFilter(value),
        backgroundColor: Colors.grey.shade200,
        selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.2),
        checkmarkColor: const Color(0xFF1565C0),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return RefreshIndicator(
      onRefresh: () => Get.find<UserSearchController>().loadPopularUsers(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for Users',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find other users by their name or username',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Quick action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  icon: Icons.trending_up,
                  label: 'Popular',
                  onTap: () => Get.find<UserSearchController>().loadPopularUsers(),
                ),
                _buildQuickActionButton(
                  icon: Icons.access_time,
                  label: 'Recent',
                  onTap: () => Get.find<UserSearchController>().loadRecentUsers(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No users match "$query"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(UserSearchController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshSearch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredResults.length,
        itemBuilder: (context, index) {
          final user = controller.filteredResults[index];
          return _buildUserCard(user, controller);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user, UserSearchController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.to(() => UserProfileScreen(userId: user.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),                      Row(
                        children: [
                          _buildStatChip(Icons.directions_car, '${user.totalAds} cars'),
                          const SizedBox(width: 8),
                          _buildStatChip(Icons.gavel, '${user.totalBids} bids'),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.snackbar(
                        'Info',
                        'Chat feature coming soon!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.blue.shade100,
                        colorText: Colors.blue.shade800,
                      );
                    },
                    icon: const Icon(Icons.message),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF1565C0),
                    ),
                  ),
                  _buildStatusIndicator(user.isActive),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isActive) {
    Color statusColor;
    String statusText;
    
    if (isActive) {
      statusColor = Colors.green;
      statusText = 'Active';
    } else {
      statusColor = Colors.grey;
      statusText = 'Inactive';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
