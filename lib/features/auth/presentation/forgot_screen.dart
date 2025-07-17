import 'package:cbazaar/features/auth/controllers/forgot_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});

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
                    child: GetBuilder<ForgotController>(
                      init: ForgotController(),
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
                  const SizedBox(height: 24.0),
                  Material(
                    type: MaterialType.transparency,
                    child: GetBuilder<ForgotController>(
                      builder: (_) {
                        return InkWell(
                          onTap: _.forgotPassword,
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
                                  'Send Link',
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
                  InkWell(
                    onTap: Get.back,
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20.0,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
