import 'package:cbazaar/core/firebase/auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signIn() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) return;

    await _authService.signInWithEmailPassword(emailController.text.trim(), passwordController.text);
  }
}
