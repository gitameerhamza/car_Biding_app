import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_dashboard_controller.dart';

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onIndexChanged;

  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: currentIndex == 0,
                onTap: () {
                  onIndexChanged?.call(0);
                  if (Get.currentRoute != '/admin/dashboard') {
                    Get.offAllNamed('/admin/dashboard');
                  }
                },
              ),
              _buildBottomNavItem(
                icon: Icons.people,
                label: 'Users',
                isSelected: currentIndex == 1,
                onTap: () {
                  onIndexChanged?.call(1);
                  if (Get.currentRoute != '/admin/users') {
                    Get.offAllNamed('/admin/users');
                  }
                },
              ),
              _buildBottomNavItem(
                icon: Icons.car_rental,
                label: 'Ads',
                isSelected: currentIndex == 2,
                onTap: () {
                  onIndexChanged?.call(2);
                  if (Get.currentRoute != '/admin/ads') {
                    Get.offAllNamed('/admin/ads');
                  }
                },
              ),
              _buildBottomNavItem(
                icon: Icons.event,
                label: 'Events',
                isSelected: currentIndex == 3,
                onTap: () {
                  onIndexChanged?.call(3);
                  if (Get.currentRoute != '/admin/events') {
                    Get.offAllNamed('/admin/events');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
