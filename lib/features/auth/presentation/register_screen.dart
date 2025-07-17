import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/register_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                  const SizedBox(height: 12.0),
                  const Text(
                    'Just one step & get your car on the Road',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: GetBuilder<RegisterController>(
                      init: RegisterController(),
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
                    child: GetBuilder<RegisterController>(
                      builder: (_) {
                        return TextField(
                          controller: _.fullNameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            fillColor: Colors.white,
                            hintText: 'Full Name',
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
                    child: GetBuilder<RegisterController>(
                      builder: (_) {
                        return TextField(
                          controller: _.usernameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            fillColor: Colors.white,
                            hintText: 'Username',
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
                    child: GetBuilder<RegisterController>(
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
                    child: GetBuilder<RegisterController>(
                      builder: (_) {
                        return Obx(() => InkWell(
                          onTap: _.isLoading.value ? null : _.signUp,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: _.isLoading.value 
                                  ? Colors.grey 
                                  : Colors.blue.shade700,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_.isLoading.value) ...[
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _.isLoading.value ? 'Creating Account...' : 'Sign Up',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                      },
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Have an account? ',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // Get.off(
                          //   () => const LoginScreen(),
                          // );
                          Get.back();
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        'We need permissions for the service you use ',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        child: const Text(
                          'Learn More',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
