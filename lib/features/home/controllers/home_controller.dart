import 'package:cbazaar/features/home/models/car_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'dart:async';

class HomeController extends GetxController {
  final searchController = TextEditingController();
  List<CarModel> searchedAds = [];
  List<CarModel> compareModels = [];
  
  // Enhanced comparison settings
  final int maxCompareModels = 4; // Allow up to 4 cars for comparison
  final RxBool isComparisonMode = false.obs;

  bool searching = false;
  Timer? _debounceTimer;

  void searchAds(String val) async {
    if (val.trim().isEmpty) {
      searching = false;
      searchedAds.clear();
      update();
      return;
    }

    try {
      searching = true;
      update();

      final searchQuery = val.trim().toLowerCase();
      final searchWords = searchQuery.split(' ').where((word) => word.isNotEmpty).toList();
      
      // Get all available ads to perform comprehensive search
      final allAdsQuery = await FirebaseFirestore.instance
          .collection('ads')
          .where('status', whereIn: ['active', 'Available'])
          .get();

      List<CarModel> allAds = allAdsQuery.docs
          .map((e) => CarModel.fromJson(e.id, e.data()))
          .toList();

      // Filter ads based on search criteria
      List<CarModel> results = [];
      
      for (final ad in allAds) {
        bool matches = false;
        
        // Search in car name
        if (ad.name.toLowerCase().contains(searchQuery)) {
          matches = true;
        }
        
        // Search in car make
        if (ad.make.toLowerCase().contains(searchQuery)) {
          matches = true;
        }
        
        // Search in location/city
        if (ad.location.toLowerCase().contains(searchQuery)) {
          matches = true;
        }
        
        // Search in year
        if (ad.year.toString().contains(searchQuery)) {
          matches = true;
        }
        
        // Search in condition
        if (ad.condition.toLowerCase().contains(searchQuery)) {
          matches = true;
        }
        
        // Search in fuel type
        if (ad.fuelType.toLowerCase().contains(searchQuery)) {
          matches = true;
        }
        
        // Search in description
        if (ad.descripton.toLowerCase().contains(searchQuery)) {
          matches = true;
        }
        
        // Search for multiple words (partial matching)
        if (!matches && searchWords.length > 1) {
          int matchedWords = 0;
          for (final word in searchWords) {
            if (ad.name.toLowerCase().contains(word) ||
                ad.make.toLowerCase().contains(word) ||
                ad.location.toLowerCase().contains(word) ||
                ad.condition.toLowerCase().contains(word) ||
                ad.fuelType.toLowerCase().contains(word) ||
                ad.descripton.toLowerCase().contains(word)) {
              matchedWords++;
            }
          }
          if (matchedWords >= (searchWords.length * 0.5).ceil()) { // At least 50% of words match
            matches = true;
          }
        }
        
        if (matches) {
          results.add(ad);
        }
      }

      // Sort results by relevance (exact matches first, then partial matches)
      results.sort((a, b) {
        int scoreA = _calculateRelevanceScore(a, searchQuery);
        int scoreB = _calculateRelevanceScore(b, searchQuery);
        return scoreB.compareTo(scoreA);
      });

      searchedAds = results;
      searching = true;
      update();
    } catch (e) {
      print('Search error: $e');
      searchedAds.clear();
      searching = false;
      update();
    }
  }

  int _calculateRelevanceScore(CarModel ad, String searchQuery) {
    int score = 0;
    final query = searchQuery.toLowerCase();
    
    // Exact name match gets highest score
    if (ad.name.toLowerCase() == query) score += 100;
    else if (ad.name.toLowerCase().startsWith(query)) score += 80;
    else if (ad.name.toLowerCase().contains(query)) score += 60;
    
    // Make matches
    if (ad.make.toLowerCase() == query) score += 90;
    else if (ad.make.toLowerCase().startsWith(query)) score += 70;
    else if (ad.make.toLowerCase().contains(query)) score += 50;
    
    // Location match
    if (ad.location.toLowerCase().contains(query)) score += 40;
    
    // Year match (exact match for year is important)
    if (ad.year.toString() == query) score += 85;
    else if (ad.year.toString().contains(query)) score += 30;
    
    // Condition match
    if (ad.condition.toLowerCase().contains(query)) score += 25;
    
    // Fuel type match
    if (ad.fuelType.toLowerCase().contains(query)) score += 20;
    
    // Description match (lower priority)
    if (ad.descripton.toLowerCase().contains(query)) score += 15;
    
    return score;
  }

  void clearSearch() {
    searchController.clear();
    searchedAds.clear();
    searching = false;
    _debounceTimer?.cancel();
    update();
  }

  // Debounced search for real-time search functionality
  void searchWithDebounce(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      searchAds(val);
    });
  }

  // Enhanced comparison methods
  void addToComparison(CarModel car) {
    if (compareModels.length >= maxCompareModels) {
      Get.snackbar(
        'Comparison Limit',
        'You can only compare up to $maxCompareModels cars at a time',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    if (compareModels.any((model) => model.id == car.id)) {
      Get.snackbar(
        'Already Added',
        'This car is already in your comparison list',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    compareModels.add(car);
    Get.snackbar(
      'Added to Comparison',
      '${car.name} added to comparison (${compareModels.length}/$maxCompareModels)',
      snackPosition: SnackPosition.BOTTOM,
    );
    update();
  }
  
  void removeFromComparison(CarModel car) {
    compareModels.removeWhere((model) => model.id == car.id);
    Get.snackbar(
      'Removed from Comparison',
      '${car.name} removed from comparison',
      snackPosition: SnackPosition.BOTTOM,
    );
    update();
  }
  
  void clearComparison() {
    compareModels.clear();
    isComparisonMode.value = false;
    Get.snackbar(
      'Comparison Cleared',
      'All cars removed from comparison',
      snackPosition: SnackPosition.BOTTOM,
    );
    update();
  }
  
  bool isInComparison(String carId) {
    return compareModels.any((model) => model.id == carId);
  }
  
  void toggleComparisonMode() {
    isComparisonMode.value = !isComparisonMode.value;
    update();
  }
  
  bool canAddToComparison() {
    return compareModels.length < maxCompareModels;
  }
  
  bool canCompare() {
    return compareModels.length >= 2;
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
}
