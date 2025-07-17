import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cbazaar/features/profile/presentation/your_cars_screen.dart';
import '../controllers/user_profile_controller.dart';
import '../models/user_model.dart';

class UserProfileScreen extends StatelessWidget {
  final String? userId;
  
  const UserProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserProfileController());
    
    // Load user profile on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadCurrentUserProfile();
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: Text(userId != null ? 'User Profile' : 'My Profile'),
        automaticallyImplyLeading: false,
        actions: [
          if (userId == null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProfileDialog(context, controller),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.currentUser.value;
        if (user == null) {
          return const Center(
            child: Text('User not found'),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewPadding.bottom + 70,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24.0),
              _buildStatsSection(user),
              const SizedBox(height: 24.0),
              _buildMenuOptions(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user.profileImageUrl != null
                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber[600],
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active User',
                        style: const TextStyle(fontSize: 14),
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

  Widget _buildStatsSection(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Ads',
                    user.totalAds.toString(),
                    Icons.car_rental,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Ads',
                    user.activeAds.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Bids',
                    user.totalBids.toString(),
                    Icons.gavel,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Bids',
                    user.activeBids.toString(),
                    Icons.pending,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Member Since',
                    _formatDate(user.createdAt.toDate()),
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: Container(), // Empty space for symmetry
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuOption(
              'Your Cars',
              'Manage your car listings',
              Icons.car_rental,
              Colors.blue,
              () => Get.to(() => const YourCarsScreen()),
            ),
            const Divider(),
            _buildMenuOption(
              'Events',
              'View upcoming car events',
              Icons.event,
              Colors.purple,
              () => Get.toNamed('/user/events'),
            ),
            const Divider(),
            _buildMenuOption(
              'Logout',
              'Sign out of your account',
              Icons.logout,
              Colors.red,
              () => _showLogoutConfirmation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Import FirebaseAuth and perform logout
              FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfileController controller) {
    final user = controller.currentUser.value;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final usernameController = TextEditingController(text: user.username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.fullNameController.text = nameController.text.trim();
              controller.usernameController.text = usernameController.text.trim();
              controller.updateProfile();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 30) {
      return '${difference} days ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '${months} month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference / 365).floor();
      return '${years} year${years > 1 ? 's' : ''} ago';
    }
  }
}
