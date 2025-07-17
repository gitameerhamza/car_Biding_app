import 'package:cbazaar/core/firebase/auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotController extends GetxController {
  final _authService = AuthService();
  final emailController = TextEditingController();

  Future<void> forgotPassword() async {
    return _authService.forgotPassword(emailController.text.trim());
  }
}
