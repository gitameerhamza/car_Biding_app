import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  String? newName, newEmail;

  void updateData() async {
    if (nameController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
        "fullName": nameController.text.trim(),
      });
      newName = nameController.text.trim();
    }

    if (emailController.text.trim().isNotEmpty) {
      await FirebaseAuth.instance.currentUser!.updateEmail(emailController.text.trim());
      newEmail = emailController.text.trim().toLowerCase();
    }

    nameController.clear();
    emailController.clear();
    update();
  }
}
