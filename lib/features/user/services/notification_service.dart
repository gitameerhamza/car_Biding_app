import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications() {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => NotificationModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Create a general notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'read': false,
        'createdAt': Timestamp.now(),
        ...?additionalData,
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }
}
