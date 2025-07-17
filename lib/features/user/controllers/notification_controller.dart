import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();

  // Observable variables
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    loadUnreadCount();
  }

  // Load user notifications
  void loadNotifications() {
    try {
      _notificationService.getUserNotifications().listen((notificationList) {
        notifications.assignAll(notificationList);
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load notifications: ${e.toString()}');
    }
  }

  // Load unread count
  void loadUnreadCount() {
    try {
      _notificationService.getUnreadCount().listen((count) {
        unreadCount.value = count;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load unread count: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      _showErrorSnackbar('Failed to mark as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      isLoading.value = true;
      await _notificationService.markAllAsRead();
      _showSuccessSnackbar('All notifications marked as read');
    } catch (e) {
      _showErrorSnackbar('Failed to mark all as read: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _showSuccessSnackbar('Notification deleted');
    } catch (e) {
      _showErrorSnackbar('Failed to delete notification: ${e.toString()}');
    }
  }

  // Show notification details
  void showNotificationDetails(NotificationModel notification) {
    // Mark as read when opened
    if (!notification.read) {
      markAsRead(notification.id);
    }

    Get.dialog(
      AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              Text(
                'Received: ${_formatDate(notification.createdAt.toDate())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (notification.bidAmount != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Amount: \$${notification.bidAmount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          if (notification.carId != null)
            TextButton(
              onPressed: () {
                Get.back();
                // Navigate to car details or bid management
                if (notification.type == 'new_bid') {
                  Get.toNamed('/user/bids');
                } else {
                  Get.toNamed('/user/bids');
                }
              },
              child: const Text('View'),
            ),
        ],
      ),
    );
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return notifications.where((n) => n.type == type.toString()).toList();
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper methods
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}
