import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../user/services/user_service.dart';

class AddCarController extends GetxController {
  final imagePicker = ImagePicker();
  final userService = UserService();

  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final yearController = TextEditingController();
  final mileageController = TextEditingController();
  final priceController = TextEditingController();
  final conditionController = TextEditingController();
  final fuelController = TextEditingController();
  final transmissionController = TextEditingController();
  final colorController = TextEditingController();
  final locationController = TextEditingController();
  final contactController = TextEditingController();
  final descriptionController = TextEditingController();

  final minBidController = TextEditingController();
  final maxBidController = TextEditingController();
  final bidDaysController = TextEditingController();

  List<File?> carImage = [null];
  bool biddingEnabled = false;

  // Dropdown options
  final List<String> carMakes = [
    'Toyota', 'Honda', 'Ford', 'Chevrolet', 'Nissan', 'BMW', 'Mercedes-Benz',
    'Audi', 'Volkswagen', 'Hyundai', 'Kia', 'Mazda', 'Subaru', 'Lexus',
    'Infiniti', 'Acura', 'Jeep', 'Ram', 'GMC', 'Cadillac', 'Buick',
    'Chrysler', 'Dodge', 'Lincoln', 'Volvo', 'Jaguar', 'Land Rover',
    'Porsche', 'Tesla', 'Mitsubishi', 'Suzuki', 'Other'
  ];

  final List<String> conditions = [
    'Excellent', 'Very Good', 'Good', 'Fair', 'Poor'
  ];

  final List<String> fuelTypes = [
    'Gasoline', 'Diesel', 'Hybrid', 'Electric', 'CNG', 'LPG'
  ];

  final List<String> transmissionTypes = [
    'Manual', 'Automatic', 'CVT', 'Semi-Automatic'
  ];

  final List<String> colors = [
    'White', 'Black', 'Silver', 'Gray', 'Red', 'Blue', 'Brown', 'Gold',
    'Green', 'Orange', 'Yellow', 'Purple', 'Pink', 'Beige', 'Other'
  ];

  final List<String> years = List.generate(
    DateTime.now().year - 1990 + 1,
    (index) => (DateTime.now().year - index).toString(),
  );

  // Selected values
  String? selectedMake;
  String? selectedCondition;
  String? selectedFuelType;
  String? selectedTransmission;
  String? selectedColor;
  String? selectedYear;

  Future<void> postAd() async {
    if (makeController.text.trim().isEmpty ||
        modelController.text.trim().isEmpty ||
        yearController.text.trim().isEmpty ||
        mileageController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        conditionController.text.trim().isEmpty ||
        fuelController.text.trim().isEmpty ||
        transmissionController.text.trim().isEmpty ||
        colorController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        carImage.isEmpty ||
        carImage.any((e) => e == null)) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Fill all the data'),
        ),
      );
      return;
    }
    // Upload images to Firebase Storage and get download URLs
    final imageURLs = <String>[];
    final storageRef = FirebaseStorage.instance.ref();
    
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );
      
      // Upload each image and get its download URL
      for (int i = 0; i < carImage.length; i++) {
        if (carImage[i] != null) {
          final fileName = 'car_images/${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final imageRef = storageRef.child(fileName);
          
          // Upload file
          await imageRef.putFile(carImage[i]!);
          
          // Get download URL
          final imageUrl = await imageRef.getDownloadURL();
          imageURLs.add(imageUrl);
        }
      }
      
      // Close loading dialog
      Get.back();
    } catch (e) {
      // Close loading dialog
      Get.back();
      
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to upload images: ${e.toString()}'),
        ),
      );
      return;
    }

    List<String> listnumber = modelController.text.trim().replaceAll(RegExp('[^A-Za-z0-9& ]'), '').split(" ");
    List<String> output = [];
    for (int i = 0; i < listnumber.length; i++) {
      if (i != listnumber.length - 1) {
        output.add(listnumber[i].trim().toLowerCase());
      }
      List<String> temp = [listnumber[i].trim().toLowerCase()];
      for (int j = i + 1; j < listnumber.length; j++) {
        temp.add(listnumber[j].trim().toLowerCase());
        output.add((temp.join(' ')));
      }
    }

    output.add(locationController.text.trim().toLowerCase());

    await FirebaseFirestore.instance.collection('ads').add({
      "car_condition": conditionController.text.trim(),
      "car_description": descriptionController.text.trim(),
      "car_img_url": imageURLs,
      "car_location": locationController.text.trim(),
      "car_name": modelController.text.trim(),
      "car_make": makeController.text.trim(),
      "car_year": int.parse(yearController.text.trim()),
      "car_mileage": int.parse(mileageController.text.trim()),
      "car_fuel_type": fuelController.text.trim(),
      "car_transmission": transmissionController.text.trim(),
      "car_color": colorController.text.trim(),
      "car_price": int.parse(priceController.text.trim()),
      "contact_number": contactController.text.trim(),
      "created_at": Timestamp.now(),
      "posted_by": FirebaseAuth.instance.currentUser!.uid,
      "status": "pending", // Changed from "Available" to "pending" for admin review
      "search_keys": output,
      "bidding_enabled": biddingEnabled,
      "max_bid_amount": maxBidController.text.trim().isNotEmpty ? int.parse(maxBidController.text.trim()) : null,
      "min_bid_amount": minBidController.text.trim().isNotEmpty ? int.parse(minBidController.text.trim()) : null,
      "bid_end_time": bidDaysController.text.trim().isNotEmpty
          ? Timestamp.fromDate(DateTime.now().add(Duration(days: int.parse(bidDaysController.text.trim()))))
          : null,
    });

    // Refresh user statistics after posting ad
    try {
      await userService.refreshUserStats(FirebaseAuth.instance.currentUser!.uid);
    } catch (e) {
      // Don't fail the whole operation if stats update fails
      print('Failed to update user stats: $e');
    }

    Get.back();
  }

  void addImage(int index) async {
    try {
      final pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Reduce quality for storage optimization
      );

      if (pickedImage != null) {
        final File imageFile = File(pickedImage.path);
        
        // Check file size (limit to 5MB)
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          Get.snackbar(
            'Image Too Large', 
            'Please select an image smaller than 5MB',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        
        carImage[index] = imageFile;
        update();
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to select image: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void addAnotherImage() {
    if (carImage.last == null) return;
    
    // Limit the number of images to a reasonable amount (e.g., 6)
    if (carImage.length >= 6) {
      Get.snackbar(
        'Maximum Images', 
        'You can add up to 6 images per car listing',
        backgroundColor: Colors.amber,
        colorText: Colors.black,
      );
      return;
    }
    
    carImage.add(null);
    update();
  }

  void toggleBidding(bool? val) {
    biddingEnabled = val ?? false;
    update();
  }

  // Dropdown selection methods
  void setMake(String? value) {
    selectedMake = value;
    makeController.text = value ?? '';
    update();
  }

  void setCondition(String? value) {
    selectedCondition = value;
    conditionController.text = value ?? '';
    update();
  }

  void setFuelType(String? value) {
    selectedFuelType = value;
    fuelController.text = value ?? '';
    update();
  }

  void setTransmission(String? value) {
    selectedTransmission = value;
    transmissionController.text = value ?? '';
    update();
  }

  void setColor(String? value) {
    selectedColor = value;
    colorController.text = value ?? '';
    update();
  }

  void setYear(String? value) {
    selectedYear = value;
    yearController.text = value ?? '';
    update();
  }
}
