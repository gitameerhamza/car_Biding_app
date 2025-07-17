import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Utility class for setting up admin accounts in Firebase
/// This should only be used during initial setup or by super admins
class AdminSetupUtility {
  static const List<Map<String, String>> defaultAdmins = [
    {
      'email': 'admin@cbazaar.com',
      'password': 'Admin123!@#',
      'role': 'admin',
      'displayName': 'Administrator'
    },
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

  /// Initialize admin accounts in Firebase
  /// WARNING: Only run this once during initial setup!
  static Future<List<String>> initializeAdminAccounts() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final List<String> results = [];

    try {
      for (final adminData in defaultAdmins) {
        final email = adminData['email']!;
        final password = adminData['password']!;
        final role = adminData['role']!;
        final displayName = adminData['displayName']!;

        try {
          // Try to create the user directly - if it fails, user exists
          final userCredential = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user != null) {
            final user = userCredential.user!;
            
            // Update display name
            await user.updateDisplayName(displayName);
            
            // Create admin record in Firestore
            final permissions = rolePermissions[role] ?? [];
            await firestore.collection('admins').doc(user.uid).set({
              'email': email,
              'role': role,
              'permissions': permissions,
              'display_name': displayName,
              'created_at': Timestamp.now(),
              'last_login_at': Timestamp.now(),
              'is_active': true,
              'created_by_setup': true,
            });

            results.add('✅ Successfully created admin: $email ($role)');
            
            // Sign out immediately for security
            await auth.signOut();
          }
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            results.add('❌ Admin account $email already exists');
          } else {
            results.add('❌ Failed to create $email: ${e.toString()}');
          }
        }
      }
    } catch (e) {
      results.add('❌ Setup failed with error: ${e.toString()}');
    }

    return results;
  }

  /// Create a single admin account
  static Future<String> createSingleAdmin({
    required String email,
    required String password,
    required String role,
    String? displayName,
  }) async {
    if (!rolePermissions.containsKey(role)) {
      return '❌ Invalid role: $role';
    }

    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Try to create the user directly
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Update display name if provided
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        
        // Create admin record in Firestore
        final permissions = rolePermissions[role] ?? [];
        await firestore.collection('admins').doc(user.uid).set({
          'email': email,
          'role': role,
          'permissions': permissions,
          'display_name': displayName ?? email.split('@')[0],
          'created_at': Timestamp.now(),
          'last_login_at': Timestamp.now(),
          'is_active': true,
          'created_by_admin': true,
        });

        // Sign out immediately for security
        await auth.signOut();
        
        return '✅ Successfully created admin: $email ($role)';
      }
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        return '❌ Admin account $email already exists';
      } else {
        return '❌ Failed to create $email: ${e.toString()}';
      }
    }

    return '❌ Unknown error occurred';
  }

  /// List all existing admin accounts
  static Future<List<Map<String, dynamic>>> listAdminAccounts() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    try {
      final snapshot = await firestore
          .collection('admins')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error listing admin accounts: $e');
      }
      return [];
    }
  }

  /// Check if any admin accounts exist
  static Future<bool> hasAdminAccounts() async {
    final admins = await listAdminAccounts();
    return admins.isNotEmpty;
  }

  /// Delete an admin account (super admin only action)
  static Future<String> deleteAdminAccount(String adminId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    try {
      // Delete from Firestore
      await firestore.collection('admins').doc(adminId).delete();
      
      // Note: We can't delete the Firebase Auth user from client side
      // That would need to be done from Firebase Console or using Admin SDK
      
      return '✅ Admin account removed from Firestore (Firebase Auth account still exists)';
    } catch (e) {
      return '❌ Failed to delete admin: ${e.toString()}';
    }
  }

  /// Update existing admin permissions to include new permissions
  static Future<List<String>> updateAdminPermissions() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<String> results = [];
    
    try {
      results.add('🔄 Updating admin permissions...');
      
      // Get all existing admin accounts
      final adminsSnapshot = await firestore.collection('admins').get();
      
      for (final doc in adminsSnapshot.docs) {
        final adminData = doc.data();
        final role = adminData['role'] as String? ?? 'admin';
        final currentPermissions = List<String>.from(adminData['permissions'] ?? []);
        final expectedPermissions = rolePermissions[role] ?? [];
        
        // Check if permissions need updating
        final missingPermissions = expectedPermissions.where((perm) => !currentPermissions.contains(perm)).toList();
        
        if (missingPermissions.isNotEmpty) {
          // Update with new permissions
          await doc.reference.update({
            'permissions': expectedPermissions,
            'updated_at': Timestamp.now(),
          });
          
          results.add('✅ Updated permissions for ${adminData['email']}: added ${missingPermissions.join(", ")}');
        } else {
          results.add('ℹ️ ${adminData['email']} already has all current permissions');
        }
      }
      
      results.add('🎉 Admin permission update completed!');
    } catch (e) {
      results.add('❌ Error updating admin permissions: ${e.toString()}');
    }
    
    return results;
  }

  /// Generate random secure password
  static String generateSecurePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return List.generate(12, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }
}
