import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide RangeValues;
import 'package:get/get.dart';
import '../../home/models/car_model.dart';
import '../models/car_filter_model.dart';
import '../services/car_service.dart';

class CarSearchController extends GetxController {
  final CarService _carService = CarService();

  // Search and filter
  final TextEditingController searchController = TextEditingController();
  final RxList<CarModel> allCars = <CarModel>[].obs;
  final RxList<CarModel> filteredCars = <CarModel>[].obs;
  final RxList<CarModel> searchResults = <CarModel>[].obs;
  final Rx<CarFilter> currentFilter = const CarFilter().obs;
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isFilterLoading = false.obs;

  // Filter options
  final RxList<String> availableCompanies = <String>[].obs;
  final RxList<String> availableConditions = <String>[].obs;
  final RxList<String> availableLocations = <String>[].obs;
  final RxList<String> availableFuelTypes = <String>[].obs;
  final Rx<RangeValues> priceRange = const RangeValues(0, 100000).obs;
  final Rx<RangeValues> yearRange = const RangeValues(1990, 2024).obs;

  // Compare functionality
  final RxList<CarModel> carsForComparison = <CarModel>[].obs;
  final RxInt maxComparisonCars = 2.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllCars();
    loadFilterOptions();
    
    // Listen to search text changes
    searchController.addListener(_onSearchTextChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Load all available cars
  Future<void> loadAllCars() async {
    try {
      isLoading.value = true;
      
      _carService.getAllCars().listen((cars) {
        allCars.value = cars;
        if (currentFilter.value.hasActiveFilters || searchController.text.trim().isNotEmpty) {
          _applyFiltersAndSearch();
        } else {
          filteredCars.assignAll(cars);
        }
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load cars: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Load filter options
  Future<void> loadFilterOptions() async {
    try {
      isFilterLoading.value = true;
      
      final results = await Future.wait([
        _carService.getAvailableCompanies(),
        _carService.getAvailableConditions(),
        _carService.getAvailableLocations(),
        _carService.getAvailableFuelTypes(),
        _carService.getPriceRange(),
        _carService.getYearRange(),
      ]);

      availableCompanies.value = results[0] as List<String>;
      availableConditions.value = results[1] as List<String>;
      availableLocations.value = results[2] as List<String>;
      availableFuelTypes.value = results[3] as List<String>;
      priceRange.value = results[4] as RangeValues;
      yearRange.value = results[5] as RangeValues;
      
    } catch (e) {
      _showErrorSnackbar('Failed to load filter options: ${e.toString()}');
    } finally {
      isFilterLoading.value = false;
    }
  }

  // Handle search text changes
  void _onSearchTextChanged() {
    if (searchController.text.trim().isEmpty) {
      _applyFiltersAndSearch();
    }
  }

  // Search cars
  Future<void> searchCars([String? query]) async {
    try {
      isSearching.value = true;
      final searchText = query ?? searchController.text.trim();
      
      if (searchText.isEmpty) {
        searchResults.clear();
        _applyFiltersAndSearch();
        return;
      }

      final results = await _carService.searchCarsByText(searchText);
      searchResults.value = results;
      _applyFiltersToResults();
      
    } catch (e) {
      _showErrorSnackbar('Search failed: ${e.toString()}');
    } finally {
      isSearching.value = false;
    }
  }

  // Apply filters
  Future<void> applyFilters(CarFilter filter) async {
    try {
      isLoading.value = true;
      currentFilter.value = filter;
      await _applyFiltersAndSearch();
    } catch (e) {
      _showErrorSnackbar('Failed to apply filters: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Apply filters and search
  Future<void> _applyFiltersAndSearch() async {
    try {
      final searchText = searchController.text.trim();
      
      if (currentFilter.value.hasActiveFilters || searchText.isNotEmpty) {
        final results = await _carService.searchCarsWithFilters(
          currentFilter.value,
          searchText: searchText.isNotEmpty ? searchText : null,
        );
        filteredCars.value = results;        } else {
          filteredCars.assignAll(allCars);
        }
    } catch (e) {
      _showErrorSnackbar('Failed to apply filters: ${e.toString()}');
    }
  }

  // Apply filters to existing search results
  void _applyFiltersToResults() {
    List<CarModel> results = List.from(searchResults);
    
    if (currentFilter.value.hasActiveFilters) {
      final filter = currentFilter.value;
      
      // Apply company filter
      if (filter.companies.isNotEmpty) {
        results = results.where((car) => filter.companies.contains(car.make)).toList();
      }
      
      // Apply condition filter
      if (filter.conditions.isNotEmpty) {
        results = results.where((car) => filter.conditions.contains(car.condition)).toList();
      }
      
      // Apply fuel type filter
      if (filter.fuelType != null) {
        results = results.where((car) => car.fuelType == filter.fuelType).toList();
      }
      
      // Apply price range filter
      if (filter.priceRange != null) {
        results = results.where((car) {
          return car.price >= filter.priceRange!.start && 
                 car.price <= filter.priceRange!.end;
        }).toList();
      }
      
      // Apply year filter
      if (filter.yearMin != null) {
        results = results.where((car) => car.year >= filter.yearMin!).toList();
      }
      if (filter.yearMax != null) {
        results = results.where((car) => car.year <= filter.yearMax!).toList();
      }
      
      // Apply location filter
      if (filter.locations.isNotEmpty) {
        results = results.where((car) {
          return filter.locations.any((location) => 
            car.location.toLowerCase().contains(location.toLowerCase()));
        }).toList();
      }
      
      // Apply sorting
      if (filter.sortBy != null) {
        results.sort((a, b) {
          int comparison = 0;
          switch (filter.sortBy) {
            case 'price':
              comparison = a.price.compareTo(b.price);
              break;
            case 'year':
              comparison = a.year.compareTo(b.year);
              break;
            case 'mileage':
              comparison = a.mileage.compareTo(b.mileage);
              break;
            case 'created_at':
              comparison = a.createdAt?.compareTo(b.createdAt ?? Timestamp.now()) ?? 0;
              break;
            default:
              comparison = a.createdAt?.compareTo(b.createdAt ?? Timestamp.now()) ?? 0;
          }
          return filter.sortAscending ? comparison : -comparison;
        });
      }
    }
    
    filteredCars.assignAll(results);
  }

  // Clear search and filters
  void clearSearchAndFilters() {
    searchController.clear();
    currentFilter.value = const CarFilter();
    searchResults.clear();
    filteredCars.assignAll(allCars);
  }

  // Clear only filters
  void clearFilters() {
    currentFilter.value = const CarFilter();
    _applyFiltersAndSearch();
  }

  // Add car to comparison
  void addToComparison(CarModel car) {
    if (carsForComparison.length >= maxComparisonCars.value) {
      _showErrorSnackbar('You can only compare ${maxComparisonCars.value} cars at a time');
      return;
    }
    
    if (carsForComparison.any((c) => c.id == car.id)) {
      _showErrorSnackbar('This car is already in comparison');
      return;
    }
    
    carsForComparison.add(car);
    _showSuccessSnackbar('Car added to comparison');
  }

  // Remove car from comparison
  void removeFromComparison(String carId) {
    carsForComparison.removeWhere((car) => car.id == carId);
    _showSuccessSnackbar('Car removed from comparison');
  }

  // Clear comparison
  void clearComparison() {
    carsForComparison.clear();
  }

  // Check if car is in comparison
  bool isInComparison(String carId) {
    return carsForComparison.any((car) => car.id == carId);
  }

  // Get featured cars
  void loadFeaturedCars() {
    try {
      _carService.getFeaturedCars(limit: 10).listen((cars) {
        // You can add a separate list for featured cars if needed
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load featured cars: ${e.toString()}');
    }
  }

  // Get cars with bidding
  void loadCarsWithBidding() {
    try {
      _carService.getCarsWithBidding().listen((cars) {
        // You can add a separate list for bidding cars if needed
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load bidding cars: ${e.toString()}');
    }
  }

  // Get current cars list (filtered or all)
  List<CarModel> get currentCarsList {
    if (searchController.text.trim().isNotEmpty || currentFilter.value.hasActiveFilters) {
      return filteredCars;
    }
    return allCars;
  }

  // Helper methods
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
