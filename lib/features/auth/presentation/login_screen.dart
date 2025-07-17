import 'package:cbazaar/features/auth/controllers/login_controller.dart';
import 'package:cbazaar/features/auth/presentation/forgot_screen.dart';
import 'package:cbazaar/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue,
                Colors.cyan,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  const Text(
                    'Car Bazar',
                    style: TextStyle(
                      fontSize: 28.0,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: GetBuilder<LoginController>(
                      init: LoginController(),
                      builder: (_) {
                        return TextField(
                          controller: _.emailController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            fillColor: Colors.white,
                            hintText: 'Email',
                            filled: true,
                            isDense: true,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: GetBuilder<LoginController>(
                      builder: (_) {
                        return TextField(
                          obscureText: true,
                          controller: _.passwordController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            fillColor: Colors.white,
                            hintText: 'Password',
                            filled: true,
                            isDense: true,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Material(
                    type: MaterialType.transparency,
                    child: GetBuilder<LoginController>(
                      builder: (_) {
                        return InkWell(
                          onTap: _.signIn,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.blue.shade700,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  GetBuilder<LoginController>(
                    builder: (_) {
                      return InkWell(
                        onTap: () {
                          Get.to(() => const ForgotScreen());
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Get.to(
                            () => const RegisterScreen(),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  
                  // Admin Access Link
                  InkWell(
                    onTap: () {
                      Get.toNamed('/admin/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Admin Access',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
