import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cbazaar/features/home/presentation/home_screen.dart';
import 'package:cbazaar/features/user/presentation/user_profile_screen.dart';
import 'package:cbazaar/features/user/presentation/bid_management_screen.dart';
import 'package:cbazaar/features/user/presentation/chat_list_screen.dart';
import 'package:cbazaar/features/profile/presentation/add_car_screen.dart';
import 'package:cbazaar/features/user/controllers/chat_controller.dart';

class MainNavigationController extends GetxController {
  var selectedIndex = 0.obs;
  
  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavigationController());
    final chatController = Get.put(ChatController());
    
    final List<Widget> screens = [
      const HomeScreen(),
      const BidManagementScreen(),
      const ChatListScreen(),
      const UserProfileScreen(),
    ];

    return Obx(() => Scaffold(
      body: IndexedStack(
        index: controller.selectedIndex.value,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const AddCarScreen());
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 6.0,
            height: 60.0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home, 'Home', controller, chatController),
                  _buildNavItem(1, Icons.gavel, 'Bids', controller, chatController),
                  const SizedBox(width: 40), // Space for FAB
                  _buildNavItem(2, Icons.chat, 'Messages', controller, chatController, showBadge: true),
                  _buildNavItem(3, Icons.person, 'Profile', controller, chatController),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildNavItem(int index, IconData icon, String label, MainNavigationController controller, ChatController chatController, {bool showBadge = false}) {
    final isSelected = controller.selectedIndex.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(0, isSelected ? -1 : 0, 0),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.deepPurple : Colors.grey,
                      size: isSelected ? 24 : 22,
                    ),
                  ),
                  if (showBadge)
                    Obx(() => chatController.unreadChatsCount.value > 0
                        ? Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                chatController.unreadChatsCount.value > 99
                                    ? '99+'
                                    : chatController.unreadChatsCount.value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
