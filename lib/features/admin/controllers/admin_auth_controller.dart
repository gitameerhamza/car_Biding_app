import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_model.dart';
import '../services/admin_auth_service.dart';

class AdminAuthController extends GetxController {
  final AdminAuthService _authService = AdminAuthService();
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final _isLoading = false.obs;
  final _currentAdmin = Rxn<AdminModel>();
  final _errorMessage = ''.obs;
  
  // Getters
  bool get isLoading => _isLoading.value;
  AdminModel? get currentAdmin => _currentAdmin.value;
  String get errorMessage => _errorMessage.value;
  bool get isAuthenticated => _currentAdmin.value != null;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    try {
      final admin = await _authService.getCurrentAdmin();
      if (admin != null && admin.isActive) {
        // Ensure admin permissions are up to date
        await _authService.ensureAdminPermissions();
        
        // Refresh admin data to get updated permissions
        final updatedAdmin = await _authService.getCurrentAdmin();
        _currentAdmin.value = updatedAdmin ?? admin;
      }
    } catch (e) {
      _currentAdmin.value = null;
    }
  }

  /// Admin login
  Future<bool> login() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final admin = await _authService.authenticateAdmin(
        emailController.text.trim(),
        passwordController.text,
      );

      if (admin != null && admin.isActive) {
        // Ensure admin has all required permissions
        await _authService.ensureAdminPermissions();
        
        // Refresh admin data to get updated permissions
        final updatedAdmin = await _authService.getCurrentAdmin();
        _currentAdmin.value = updatedAdmin ?? admin;
        
        _clearForm();
        _showSuccess('Login successful');
        return true;
      } else {
        _showError('Admin account is inactive');
        return false;
      }
    } catch (e) {
      _showError(_parseError(e.toString()));
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Admin logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentAdmin.value = null;
      _clearForm();
      Get.offAllNamed('/admin/login');
    } catch (e) {
      _showError('Logout failed: ${e.toString()}');
    }
  }

  /// Check if admin has specific permission
  Future<bool> hasPermission(String permission) async {
    if (_currentAdmin.value == null) return false;
    return await _authService.hasPermission(permission);
  }

  /// Refresh admin data
  Future<void> refreshAdminData() async {
    try {
      final admin = await _authService.getCurrentAdmin();
      if (admin != null) {
        _currentAdmin.value = admin;
      }
    } catch (e) {
      _showError('Failed to refresh admin data');
    }
  }

  /// Clear form fields
  void _clearForm() {
    emailController.clear();
    passwordController.clear();
  }

  /// Show error message
  void _showError(String message) {
    _errorMessage.value = message;
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Parse error messages for user-friendly display
  String _parseError(String error) {
    if (error.contains('user-not-found')) {
      return 'No admin account found with this email';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('user-disabled')) {
      return 'This admin account has been disabled';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later';
    } else if (error.contains('Access denied')) {
      return 'Access denied: Not an admin email';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection';
    }
    return error.replaceAll('Exception: ', '');
  }

  /// Validate email format
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_authService.isAdminEmail(value)) {
      return 'Not an authorized admin email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Get role display name
  String getRoleDisplayName(String role) {
    return 'Administrator';
  }

  /// Get role color
  Color getRoleColor(String role) {
    return Colors.blue;
  }
}
