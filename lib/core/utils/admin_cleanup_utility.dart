import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Utility class for cleaning up old admin accounts and roles
/// This removes super_admin and moderator accounts, keeping only 'admin' role
class AdminCleanupUtility {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clean up old admin accounts and roles
  static Future<List<String>> cleanupOldAdminAccounts() async {
    List<String> results = [];
    
    try {
      results.add('🧹 Starting admin cleanup process...');
      
      // Get all existing admin records
      final adminSnapshot = await _firestore
          .collection('admins')
          .get();
      
      results.add('📊 Found ${adminSnapshot.docs.length} admin records');
      
      for (var doc in adminSnapshot.docs) {
        final data = doc.data();
        final email = data['email'] as String;
        final role = data['role'] as String;
        
        // Keep only admin@cbazaar.com with 'admin' role
        if (email == 'admin@cbazaar.com') {
          if (role != 'admin') {
            // Update role to 'admin' and permissions
            await _firestore
                .collection('admins')
                .doc(doc.id)
                .update({
              'role': 'admin',
              'permissions': [
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
            });
            results.add('✅ Updated $email role to admin with full permissions');
          } else {
            results.add('✅ $email already has correct admin role');
          }
        } else {
          // Remove other admin accounts from Firestore
          await _firestore
              .collection('admins')
              .doc(doc.id)
              .delete();
          results.add('🗑️ Removed admin record for $email');
          
          // Note: We cannot delete Firebase Auth users from client-side
          // This would need to be done from Firebase Console or Admin SDK
          results.add('⚠️ Firebase Auth account for $email needs manual removal from console');
        }
      }
      
      results.add('');
      results.add('✨ Admin cleanup completed!');
      results.add('');
      results.add('📧 Remaining Admin:');
      results.add('• admin@cbazaar.com (Full Access)');
      results.add('');
      results.add('⚠️ Manual Steps Required:');
      results.add('1. Remove superadmin@cbazaar.com from Firebase Auth Console');
      results.add('2. Remove moderator@cbazaar.com from Firebase Auth Console');
      results.add('3. Go to Firebase Console > Authentication > Users');
      results.add('4. Delete the unwanted user accounts manually');
      
    } catch (e) {
      results.add('❌ Cleanup failed: $e');
      if (kDebugMode) {
        print('Admin cleanup error: $e');
      }
    }
    
    return results;
  }

  /// Check current admin configuration
  static Future<List<String>> checkAdminConfiguration() async {
    List<String> results = [];
    
    try {
      results.add('🔍 Checking current admin configuration...');
      results.add('');
      
      final adminSnapshot = await _firestore
          .collection('admins')
          .get();
      
      if (adminSnapshot.docs.isEmpty) {
        results.add('❌ No admin accounts found');
        results.add('💡 Run admin setup to create the admin account');
      } else {
        results.add('📊 Current admin accounts:');
        results.add('');
        
        for (var doc in adminSnapshot.docs) {
          final data = doc.data();
          final email = data['email'] as String;
          final role = data['role'] as String;
          final isActive = data['is_active'] as bool? ?? true;
          final permissions = List<String>.from(data['permissions'] ?? []);
          
          results.add('👤 $email');
          results.add('   Role: $role');
          results.add('   Active: $isActive');
          results.add('   Permissions: ${permissions.length}');
          results.add('');
        }
      }
      
    } catch (e) {
      results.add('❌ Check failed: $e');
    }
    
    return results;
  }
}
