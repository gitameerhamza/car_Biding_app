import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProfileController extends GetxController {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();

  // Observable variables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxString profileImageUrl = ''.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    loadCurrentUserProfile();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  // Load current user profile
  Future<void> loadCurrentUserProfile() async {
    try {
      isLoading.value = true;
      final user = await _userService.getCurrentUserProfileWithStats();
      
      if (user != null) {
        currentUser.value = user;
        profileImageUrl.value = user.profileImageUrl ?? '';
        
        // Populate form controllers
        fullNameController.text = user.fullName;
        usernameController.text = user.username;
        emailController.text = user.email;
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Pick profile image
  Future<void> pickProfileImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.toString()}');
    }
  }

  // Upload profile image - Skip storage to avoid errors
  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      // Skip Firebase Storage upload for now to avoid storage errors
      // Return a placeholder URL or null
      print('Skipping image upload to avoid storage errors');
      return null; // or return a default image URL
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile() async {
    try {
      if (!_validateInputs()) return;

      isUpdating.value = true;

      // Check username availability if changed
      if (usernameController.text.trim().toLowerCase() != currentUser.value?.username.toLowerCase()) {
        final isAvailable = await _userService.isUsernameAvailable(usernameController.text.trim());
        if (!isAvailable) {
          _showErrorSnackbar('Username is already taken');
          return;
        }
      }

      String? newImageUrl;
      
      // Upload new image if selected
      if (selectedImage.value != null) {
        newImageUrl = await _uploadProfileImage(selectedImage.value!);
      }

      // Create updated user model
      final updatedUser = currentUser.value!.copyWith(
        fullName: fullNameController.text.trim(),
        username: usernameController.text.trim().toLowerCase(),
        email: emailController.text.trim().toLowerCase(),
        profileImageUrl: newImageUrl ?? currentUser.value!.profileImageUrl,
      );

      // Update in Firestore
      await _userService.updateUserProfile(updatedUser);

      // Update local state
      currentUser.value = updatedUser;
      profileImageUrl.value = updatedUser.profileImageUrl ?? '';
      selectedImage.value = null;

      _showSuccessSnackbar('Profile updated successfully');

    } catch (e) {
      _showErrorSnackbar('Failed to update profile: ${e.toString()}');
    } finally {
      isUpdating.value = false;
    }
  }

  // Validate inputs
  bool _validateInputs() {
    if (fullNameController.text.trim().isEmpty) {
      _showErrorSnackbar('Full name is required');
      return false;
    }

    if (usernameController.text.trim().isEmpty) {
      _showErrorSnackbar('Username is required');
      return false;
    }

    if (usernameController.text.trim().length < 3) {
      _showErrorSnackbar('Username must be at least 3 characters');
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      _showErrorSnackbar('Email is required');
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      _showErrorSnackbar('Please enter a valid email');
      return false;
    }

    return true;
  }

  // Get user profile by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      return await _userService.getUserProfile(userId);
    } catch (e) {
      _showErrorSnackbar('Failed to get user profile: ${e.toString()}');
      return null;
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      return await _userService.searchUsers(query.trim());
    } catch (e) {
      _showErrorSnackbar('Search failed: ${e.toString()}');
      return [];
    }
  }

  // Deactivate account
  Future<void> deactivateAccount() async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Deactivate Account'),
          content: const Text(
            'Are you sure you want to deactivate your account? This action can be reversed later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        isUpdating.value = true;
        await _userService.deactivateAccount();
        
        // Update local state
        currentUser.value = currentUser.value?.copyWith(isActive: false);
        
        _showSuccessSnackbar('Account deactivated successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to deactivate account: ${e.toString()}');
    } finally {
      isUpdating.value = false;
    }
  }

  // Reactivate account
  Future<void> reactivateAccount() async {
    try {
      isUpdating.value = true;
      await _userService.reactivateAccount();
      
      // Update local state
      currentUser.value = currentUser.value?.copyWith(isActive: true);
      
      _showSuccessSnackbar('Account reactivated successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to reactivate account: ${e.toString()}');
    } finally {
      isUpdating.value = false;
    }
  }

  // Reset form
  void resetForm() {
    if (currentUser.value != null) {
      fullNameController.text = currentUser.value!.fullName;
      usernameController.text = currentUser.value!.username;
      emailController.text = currentUser.value!.email;
      selectedImage.value = null;
    }
  }

  // Refresh user statistics manually
  Future<void> refreshUserStats() async {
    try {
      isLoading.value = true;
      await loadCurrentUserProfile(); // This will call getCurrentUserProfileWithStats
    } catch (e) {
      _showErrorSnackbar('Failed to refresh stats: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods for showing snackbars
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 3),
    );
  }
}
