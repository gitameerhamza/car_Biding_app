import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/user_service.dart';
import '../services/search_history_service.dart';
import '../models/user_model.dart';
import 'dart:async';

class UserSearchController extends GetxController {
  final UserService _userService = UserService();
  final SearchHistoryService _historyService = Get.find<SearchHistoryService>();
  
  // Search functionality
  final TextEditingController searchController = TextEditingController();
  final RxList<UserModel> searchResults = <UserModel>[].obs;
  final RxList<UserModel> filteredResults = <UserModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxString selectedFilter = 'all'.obs;
  
  // Debounce timer for search
  Timer? _searchDebounce;
  
  @override
  void onInit() {
    super.onInit();
    // Listen to search controller changes
    searchController.addListener(_onSearchChanged);
  }
  
  @override
  void onClose() {
    searchController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }
  
  void _onSearchChanged() {
    // Cancel previous timer
    _searchDebounce?.cancel();
    
    // Set new timer with 300ms delay
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = searchController.text.trim();
      if (query.isNotEmpty) {
        searchUsers(query);
      } else {
        clearSearch();
      }
    });
  }
  
  // Search users
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }
    
    try {
      isSearching.value = true;
      final results = await _userService.searchUsers(query.trim());
      searchResults.value = results;
      _applyFilter();
      
      // Add to search history if results found
      if (results.isNotEmpty) {
        _historyService.addToHistory(query.trim());
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to search users: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSearching.value = false;
    }
  }
  
  // Clear search
  void clearSearch() {
    searchResults.clear();
    filteredResults.clear();
    isSearching.value = false;
  }
  
  // Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }
  
  // Apply filter to search results
  void _applyFilter() {
    switch (selectedFilter.value) {
      case 'all':
        filteredResults.value = List.from(searchResults);
        break;
      case 'active':
        filteredResults.value = searchResults.where((user) => user.isActive).toList();
        break;
      case 'recent':
        filteredResults.value = List.from(searchResults)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'sellers':
        filteredResults.value = searchResults.where((user) => user.totalAds > 0).toList()
          ..sort((a, b) => b.totalAds.compareTo(a.totalAds));
        break;
      case 'bidders':
        filteredResults.value = searchResults.where((user) => user.totalBids > 0).toList()
          ..sort((a, b) => b.totalBids.compareTo(a.totalBids));
        break;
      default:
        filteredResults.value = List.from(searchResults);
    }
  }
  
  // Refresh search
  Future<void> refreshSearch() async {
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      await searchUsers(query);
    }
  }
  
  // Get popular users (for initial state)
  Future<void> loadPopularUsers() async {
    try {
      isSearching.value = true;
      final users = await _userService.getPopularUsers();
      searchResults.value = users;
      filteredResults.value = users;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load popular users: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // Load recent users
  Future<void> loadRecentUsers() async {
    try {
      isSearching.value = true;
      final users = await _userService.getRecentUsers();
      searchResults.value = users;
      filteredResults.value = users;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load recent users: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // Advanced search with filters
  Future<void> advancedSearch({
    String? query,
    bool? isActive,
    String? location,
    int? minAds,
    int? minBids,
    String? sortBy,
  }) async {
    try {
      isSearching.value = true;
      final results = await _userService.advancedSearchUsers(
        query: query ?? searchController.text.trim(),
        isActive: isActive,
        location: location,
        minAds: minAds,
        minBids: minBids,
        sortBy: sortBy,
      );
      searchResults.value = results;
      _applyFilter();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to perform advanced search: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // Search users by location
  Future<void> searchByLocation(String location) async {
    try {
      isSearching.value = true;
      final results = await _userService.searchUsersByLocation(location);
      searchResults.value = results;
      _applyFilter();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to search by location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // Get search suggestions based on current query
  List<String> getSearchSuggestions() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return [];

    // Create suggestions based on current users in results
    final suggestions = <String>{};
    
    for (final user in searchResults) {
      if (user.fullName.toLowerCase().contains(query)) {
        suggestions.add(user.fullName);
      }
      if (user.username.toLowerCase().contains(query)) {
        suggestions.add('@${user.username}');
      }
    }

    return suggestions.take(5).toList();
  }
}
