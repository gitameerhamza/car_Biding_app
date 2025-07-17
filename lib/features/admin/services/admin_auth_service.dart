import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';

class AdminAuthService {
  static const List<String> adminEmails = [
    'admin@cbazaar.com',
    // Single admin email with full access
    // Use /admin/setup route to create this account initially
  ];

  static const Map<String, List<String>> rolePermissions = {
    'admin': [
      // Dashboard & Overview
      'view_dashboard',
      'view_stats',
      
      // User Management
      'manage_admins',
      'manage_users',
      'view_users',
      'edit_users',
      'delete_users',
      'suspend_users',
      
      // Content Management
      'manage_ads',
      'manage_events',
      'manage_bids',
      'manage_cars',
      'view_all_content',
      'edit_all_content',
      'delete_any_content',
      
      // System Administration
      'system_settings',
      'view_analytics',
      'manage_categories',
      'manage_reports',
      'access_logs',
      
      // Chat & Communication
      'manage_chats',
      'view_all_chats',
      'moderate_messages',
      
      // Financial & Billing
      'view_transactions',
      'manage_payments',
      'generate_reports',
      
      // Full administrative access
      'super_admin_access',
      'override_permissions',
      'emergency_access',
    ],
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if email is eligible for admin access
  bool isAdminEmail(String email) {
    return adminEmails.contains(email.toLowerCase());
  }

  /// Authenticate admin user
  Future<AdminModel?> authenticateAdmin(String email, String password) async {
    try {
      if (!isAdminEmail(email)) {
        throw Exception('Access denied: Not an admin email');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      return await getOrCreateAdminRecord(userCredential.user!);
    } catch (e) {
      rethrow;
    }
  }

  /// Get or create admin record in Firestore
  Future<AdminModel> getOrCreateAdminRecord(User user) async {
    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        // Update last login
        await _firestore
            .collection('admins')
            .doc(user.uid)
            .update({
          'last_login_at': Timestamp.now(),
        });

        return AdminModel.fromJson(adminDoc.id, adminDoc.data()!);
      } else {
        // Create new admin record
        final role = _determineRole(user.email!);
        final permissions = rolePermissions[role] ?? [];

        final adminModel = AdminModel(
          id: user.uid,
          email: user.email!,
          role: role,
          permissions: permissions,
          createdAt: Timestamp.now(),
          lastLoginAt: Timestamp.now(),
          isActive: true,
        );

        await _firestore
            .collection('admins')
            .doc(user.uid)
            .set(adminModel.toJson());

        return adminModel;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Determine admin role based on email
  String _determineRole(String email) {
    // Single admin role for all authorized emails
    return 'admin';
  }

  /// Get current admin
  Future<AdminModel?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) return null;

      return AdminModel.fromJson(adminDoc.id, adminDoc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Check if current user has specific permission
  Future<bool> hasPermission(String permission) async {
    final admin = await getCurrentAdmin();
    if (admin == null || !admin.isActive) return false;
    return admin.permissions.contains(permission);
  }

  /// Logout admin
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get all admins (super admin only)
  Future<List<AdminModel>> getAllAdmins() async {
    if (!await hasPermission('manage_admins')) {
      throw Exception('Insufficient permissions');
    }

    try {
      final snapshot = await _firestore
          .collection('admins')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminModel.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update admin status
  Future<void> updateAdminStatus(String adminId, bool isActive) async {
    if (!await hasPermission('manage_admins')) {
      throw Exception('Insufficient permissions');
    }

    await _firestore
        .collection('admins')
        .doc(adminId)
        .update({'is_active': isActive});
  }

  /// Update admin role and permissions
  Future<void> updateAdminRole(String adminId, String newRole) async {
    if (!await hasPermission('manage_admins')) {
      throw Exception('Insufficient permissions');
    }

    final permissions = rolePermissions[newRole] ?? [];
    await _firestore
        .collection('admins')
        .doc(adminId)
        .update({
      'role': newRole,
      'permissions': permissions,
    });
  }

  /// Ensure current admin has all required permissions
  Future<void> ensureAdminPermissions() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('ensureAdminPermissions: No user logged in');
      return;
    }

    try {
      print('ensureAdminPermissions: Checking permissions for user ${user.uid}');
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        final adminData = adminDoc.data()!;
        final currentRole = adminData['role'] as String? ?? 'admin';
        final currentPermissions = List<String>.from(adminData['permissions'] ?? []);
        final expectedPermissions = rolePermissions[currentRole] ?? [];

        print('ensureAdminPermissions: Current permissions count: ${currentPermissions.length}');
        print('ensureAdminPermissions: Expected permissions count: ${expectedPermissions.length}');
        print('ensureAdminPermissions: Current role: $currentRole');

        // Check if permissions need updating
        final missingPermissions = expectedPermissions
            .where((perm) => !currentPermissions.contains(perm))
            .toList();

        print('ensureAdminPermissions: Missing permissions: $missingPermissions');

        if (missingPermissions.isNotEmpty) {
          print('ensureAdminPermissions: Updating permissions...');
          // Update with complete permission set
          await _firestore
              .collection('admins')
              .doc(user.uid)
              .update({
            'permissions': expectedPermissions,
            'updated_at': Timestamp.now(),
          });
          print('ensureAdminPermissions: Permissions updated successfully');
        } else {
          print('ensureAdminPermissions: No permission update needed');
        }
      } else {
        print('ensureAdminPermissions: Admin document does not exist');
      }
    } catch (e) {
      print('Failed to ensure admin permissions: $e');
    }
  }

  /// Force update admin permissions (debug utility)
  Future<void> forceUpdateAdminPermissions() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('forceUpdateAdminPermissions: No user logged in');
      return;
    }

    try {
      print('forceUpdateAdminPermissions: Forcing permission update for user ${user.uid}');
      final expectedPermissions = rolePermissions['admin'] ?? [];
      
      await _firestore
          .collection('admins')
          .doc(user.uid)
          .update({
        'permissions': expectedPermissions,
        'updated_at': Timestamp.now(),
      });
      
      print('forceUpdateAdminPermissions: Updated to ${expectedPermissions.length} permissions');
      print('forceUpdateAdminPermissions: First few permissions: ${expectedPermissions.take(5).toList()}');
    } catch (e) {
      print('forceUpdateAdminPermissions failed: $e');
    }
  }
}
