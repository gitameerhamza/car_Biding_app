import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/admin_setup_utility.dart';
import '../../../core/utils/admin_cleanup_utility.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final List<String> _setupResults = [];
  bool _isLoading = false;
  bool _showManualCreate = false;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _selectedRole = 'admin';

  @override
  void initState() {
    super.initState();
    _checkExistingAdmins();
  }

  Future<void> _checkExistingAdmins() async {
    setState(() => _isLoading = true);
    
    try {
      final admins = await AdminSetupUtility.listAdminAccounts();
      if (admins.isNotEmpty) {
        setState(() {
          _setupResults.add('📋 Found ${admins.length} existing admin account(s):');
          for (final admin in admins) {
            _setupResults.add('  • ${admin['email']} (${admin['role']}) - ${admin['is_active'] ? 'Active' : 'Inactive'}');
          }
          _setupResults.add('');
        });
      } else {
        setState(() {
          _setupResults.add('⚠️  No admin accounts found. You can create them below.');
          _setupResults.add('');
        });
      }
    } catch (e) {
      setState(() {
        _setupResults.add('❌ Error checking existing admins: $e');
        _setupResults.add('');
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _initializeDefaultAdmins() async {
    setState(() {
      _isLoading = true;
      _setupResults.add('🚀 Starting admin account initialization...');
      _setupResults.add('');
    });

    try {
      final results = await AdminSetupUtility.initializeAdminAccounts();
      setState(() {
        _setupResults.addAll(results);
        _setupResults.add('');
        _setupResults.add('✨ Admin initialization completed!');
        _setupResults.add('');
        _setupResults.add('📧 Default Credentials:');
        _setupResults.add('• admin@cbazaar.com / Admin123!@#');
        _setupResults.add('');
        _setupResults.add('⚠️  IMPORTANT: Change this password after first login!');
      });
    } catch (e) {
      setState(() {
        _setupResults.add('❌ Setup failed: $e');
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createCustomAdmin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Email and password are required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AdminSetupUtility.createSingleAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        displayName: _displayNameController.text.trim().isEmpty 
            ? null 
            : _displayNameController.text.trim(),
      );

      setState(() {
        _setupResults.add(result);
        _setupResults.add('');
      });

      if (result.startsWith('✅')) {
        _emailController.clear();
        _passwordController.clear();
        _displayNameController.clear();
        setState(() => _showManualCreate = false);
      }
    } catch (e) {
      setState(() {
        _setupResults.add('❌ Failed to create admin: $e');
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _cleanupOldAdmins() async {
    setState(() {
      _isLoading = true;
      _setupResults.add('🧹 Starting admin account cleanup...');
      _setupResults.add('');
    });

    try {
      final results = await AdminCleanupUtility.cleanupOldAdminAccounts();
      setState(() {
        _setupResults.addAll(results);
        _setupResults.add('');
        _setupResults.add('🧼 Cleanup completed!');
      });
    } catch (e) {
      setState(() {
        _setupResults.add('❌ Cleanup failed: $e');
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkAdminConfig() async {
    setState(() {
      _isLoading = true;
      _setupResults.add('🔍 Checking admin configuration...');
      _setupResults.add('');
    });

    try {
      final results = await AdminCleanupUtility.checkAdminConfiguration();
      setState(() {
        _setupResults.addAll(results);
      });
    } catch (e) {
      setState(() {
        _setupResults.add('❌ Configuration check failed: $e');
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _upgradeAdminPermissions() async {
    setState(() {
      _isLoading = true;
      _setupResults.add('🚀 Upgrading admin@cbazaar.com permissions...');
      _setupResults.add('');
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Update admin@cbazaar.com with all permissions
      await firestore.collection('admins').doc('admin@cbazaar.com').set({
        'email': 'admin@cbazaar.com',
        'role': 'admin',
        'display_name': 'Administrator',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
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
      }, SetOptions(merge: true));

      setState(() {
        _setupResults.add('✅ Successfully upgraded admin@cbazaar.com with all 26 permissions');
        _setupResults.add('');
        _setupResults.add('📋 Permissions added:');
        _setupResults.add('• User Management: manage_admins, manage_users, view_users, edit_users, delete_users, suspend_users');
        _setupResults.add('• Content Management: manage_ads, manage_events, manage_bids, manage_cars, view_all_content, edit_all_content, delete_any_content');
        _setupResults.add('• System Administration: system_settings, view_analytics, manage_categories, manage_reports, access_logs');
        _setupResults.add('• Chat & Communication: manage_chats, view_all_chats, moderate_messages');
        _setupResults.add('• Financial & Billing: view_transactions, manage_payments, generate_reports');
        _setupResults.add('• Full Administrative: super_admin_access, override_permissions, emergency_access');
      });
    } catch (e) {
      setState(() {
        _setupResults.add('❌ Permission upgrade failed: $e');
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Account Setup',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This utility helps you create admin accounts for your CBazaar app. Use this only during initial setup or when adding new admins.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _initializeDefaultAdmins,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Create Default Admins'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () {
                              setState(() => _showManualCreate = !_showManualCreate);
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Custom Admin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (_showManualCreate) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Custom Admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email*',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password*',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                        ],
                        onChanged: (value) => setState(() => _selectedRole = value!),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createCustomAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Create Admin'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Setup Results:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _setupResults.length,
                        itemBuilder: (context, index) {
                          final result = _setupResults[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              result,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: result.startsWith('✅') 
                                    ? Colors.green.shade700
                                    : result.startsWith('❌')
                                        ? Colors.red.shade700
                                        : result.startsWith('⚠️')
                                            ? Colors.orange.shade700
                                            : Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkExistingAdmins,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.offAllNamed('/'),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Go to App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Admin cleanup and config check section
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cleanupOldAdmins,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Cleanup Old Admins'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkAdminConfig,
                    icon: const Icon(Icons.info),
                    label: const Text('Check Config'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Upgrade admin permissions button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _upgradeAdminPermissions,
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade Admin Permissions (admin@cbazaar.com)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
}
