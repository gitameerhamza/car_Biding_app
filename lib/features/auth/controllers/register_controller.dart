import 'package:cbazaar/core/firebase/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  final _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> signUp() async {
    // Validate inputs
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        fullNameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final res = await _authService.signUpWithEmailPassword(emailController.text.trim(), passwordController.text);

      if (res != null) {
        // Save user data to Firestore including email and timestamps
        await FirebaseFirestore.instance.collection('users').doc(_authService.currentUser!.uid).set({
          'fullName': fullNameController.text.trim(),
          'username': usernameController.text.trim(),
          'email': emailController.text.trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        await _authService.signOut();
        
        Get.snackbar(
          'Success',
          'Account created successfully! Please log in.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        Get.back();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create account: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
