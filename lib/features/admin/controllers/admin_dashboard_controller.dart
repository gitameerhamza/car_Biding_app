import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_data_models.dart';
import '../models/user_management_model.dart' as admin_models;
import '../services/admin_data_service.dart';
import '../services/admin_auth_service.dart';
import '../../home/models/car_model.dart';
import '../../user/models/user_model.dart';

class AdminDashboardController extends GetxController {
  final AdminDataService _dataService = AdminDataService();
  
  // Observable data
  final _stats = Rxn<AdminStatsModel>();
  final _users = <admin_models.AdminUserModel>[].obs;
  final _ads = <CarModel>[].obs;
  final _bids = <BidModel>[].obs;
  final _events = <AdminEventModel>[].obs;
  final _suspiciousUsers = <admin_models.AdminUserModel>[].obs;
  
  // User management specific
  final _userSearchResults = <admin_models.AdminUserModel>[].obs;
  final _selectedUser = Rxn<admin_models.AdminUserModel>();
  final _userAnalytics = <Map<String, dynamic>>[].obs;
  final _userActionLogs = <admin_models.UserActionLogModel>[].obs;
  final _userFilterType = 'all'.obs; // 'all', 'active', 'restricted', 'suspended', 'verified', 'suspicious'
  
  // Loading states
  final _isLoadingStats = false.obs;
  final _isLoadingUsers = false.obs;
  final _isLoadingAds = false.obs;
  final _isLoadingBids = false.obs;
  final _isLoadingEvents = false.obs;
  final _isSearching = false.obs;
  
  // Search controllers
  final searchController = TextEditingController();
  final _searchResults = <dynamic>[].obs;
  final _searchType = 'users'.obs;
  
  // Pagination
  final _currentPage = 1.obs;
  final _itemsPerPage = 20;
  final _hasMoreData = true.obs;
  
  // Getters
  AdminStatsModel? get stats => _stats.value;
  List<admin_models.AdminUserModel> get users => _users;
  List<CarModel> get ads => _ads;
  List<BidModel> get bids => _bids;
  List<AdminEventModel> get events => _events;
  List<admin_models.AdminUserModel> get suspiciousUsers => _suspiciousUsers;
  List<dynamic> get searchResults => _searchResults;
  List<admin_models.AdminUserModel> get userSearchResults => _userSearchResults;
  String get searchType => _searchType.value;
  String get userFilterType => _userFilterType.value;
  
  bool get isLoadingStats => _isLoadingStats.value;
  bool get isLoadingUsers => _isLoadingUsers.value;
  bool get isLoadingAds => _isLoadingAds.value;
  bool get isLoadingBids => _isLoadingBids.value;
  bool get isLoadingEvents => _isLoadingEvents.value;
  bool get isSearching => _isSearching.value;
  bool get hasMoreData => _hasMoreData.value;
  int get currentPage => _currentPage.value;
  admin_models.AdminUserModel? get selectedUser => _selectedUser.value;
  List<Map<String, dynamic>> get userAnalytics => _userAnalytics;
  List<admin_models.UserActionLogModel> get userActionLogs => _userActionLogs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    await Future.wait([
      loadStats(),
      loadUsers(),
      loadAds(),
      loadBids(),
      loadEvents(),
      loadSuspiciousUsers(),
    ]);
  }

  /// Load users
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _users.clear();
      _currentPage.value = 1;
      _hasMoreData.value = true;
    }
    
    if (!_hasMoreData.value) return;
    
    _isLoadingUsers.value = true;
    try {
      // Apply filter based on userFilterType
      bool? isRestricted;
      bool? isSuspicious;
      String? accountStatus;
      bool? requiresVerification;
      
      switch (_userFilterType.value) {
        case 'restricted':
          isRestricted = true;
          break;
        case 'suspicious':
          isSuspicious = true;
          break;
        case 'active':
          accountStatus = 'active';
          break;
        case 'suspended':
          accountStatus = 'suspended';
          break;
        case 'banned':
          accountStatus = 'banned';
          break;
        case 'verified':
          requiresVerification = false;
          break;
        case 'needs_verification':
          requiresVerification = true;
          break;
      }
      
      final newUsers = await _dataService.getAllUsers(
        limit: _itemsPerPage,
        orderBy: 'createdAt',
        descending: true,
        isRestricted: isRestricted,
        isSuspicious: isSuspicious,
        accountStatus: accountStatus,
        requiresVerification: requiresVerification,
      );
      
      if (newUsers.length < _itemsPerPage) {
        _hasMoreData.value = false;
      }
      
      if (refresh) {
        _users.assignAll(newUsers);
      } else {
        _users.addAll(newUsers);
      }
      
      _currentPage.value++;
    } catch (e) {
      _showError('Failed to load users: ${e.toString()}');
    } finally {
      _isLoadingUsers.value = false;
    }
  }

  /// Load suspicious users
  Future<void> loadSuspiciousUsers() async {
    try {
      final users = await _dataService.getAllUsers(isSuspicious: true);
      _suspiciousUsers.assignAll(users);
    } catch (e) {
      print('Failed to load suspicious users: ${e.toString()}');
    }
  }

  /// Load ads
  Future<void> loadAds({String? status, bool refresh = false}) async {
    if (refresh) {
      _ads.clear();
    }
    
    _isLoadingAds.value = true;
    try {
      final newAds = await _dataService.getAllAds(
        status: status,
        limit: _itemsPerPage,
        orderBy: 'created_at',
        descending: true,
      );
      
      if (refresh) {
        _ads.assignAll(newAds);
      } else {
        _ads.addAll(newAds);
      }
    } catch (e) {
      _showError('Failed to load ads: ${e.toString()}');
    } finally {
      _isLoadingAds.value = false;
    }
  }

  /// Load bids
  Future<List<BidModel>> loadBids({String? status, String? carId, bool refresh = false}) async {
    print('AdminDashboardController.loadBids: Starting with status=$status, carId=$carId, refresh=$refresh');
    
    if (refresh) {
      _bids.clear();
    }
    
    _isLoadingBids.value = true;
    try {
      final newBids = await _dataService.getAllBids(
        status: status,
        carId: carId,
        limit: _itemsPerPage,
        orderBy: 'bid_time',
        descending: true,
      );
      
      print('AdminDashboardController.loadBids: Loaded ${newBids.length} bids');
      
      if (refresh) {
        _bids.assignAll(newBids);
      } else {
        _bids.addAll(newBids);
      }
      
      return newBids;
    } catch (e) {
      print('AdminDashboardController.loadBids: Error loading bids: $e');
      _showError('Failed to load bids: ${e.toString()}');
      return [];
    } finally {
      _isLoadingBids.value = false;
    }
  }

  /// Load events
  Future<void> loadEvents({bool refresh = false}) async {
    if (refresh) {
      _events.clear();
    }
    
    _isLoadingEvents.value = true;
    try {
      final newEvents = await _dataService.getAllEvents();
      
      if (refresh) {
        _events.assignAll(newEvents);
      } else {
        _events.addAll(newEvents);
      }
    } catch (e) {
      _showError('Failed to load events: ${e.toString()}');
    } finally {
      _isLoadingEvents.value = false;
    }
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _userSearchResults.clear();
      return;
    }
    
    _isSearching.value = true;
    try {
      final results = await _dataService.getAllUsers(
        searchQuery: query,
        limit: 20,
      );
      
      _userSearchResults.assignAll(results);
    } catch (e) {
      _showError('Failed to search users: ${e.toString()}');
    } finally {
      _isSearching.value = false;
    }
  }

  /// Change search type and perform search
  void changeSearchType(String type) {
    _searchType.value = type;
    search(searchController.text);
  }

  /// Perform search based on current search type
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      return;
    }
    
    _isSearching.value = true;
    try {
      switch (_searchType.value) {
        case 'users':
          await searchUsers(query);
          _searchResults.assignAll(_userSearchResults);
          break;
        // Add other search types as needed
      }
    } finally {
      _isSearching.value = false;
    }
  }

  /// Set user filter type and refresh
  void setUserFilterType(String filterType) {
    if (_userFilterType.value == filterType) return;
    
    _userFilterType.value = filterType;
    loadUsers(refresh: true);
  }

  /// Select a user for detailed view
  Future<void> selectUserForDetails(String userId) async {
    try {
      final user = await _dataService.getUserById(userId);
      if (user == null) {
        _showError('User not found');
        return;
      }
      
      _selectedUser.value = user;
      
      // Load user analytics and action logs
      await loadUserAnalytics(userId);
      await loadUserActionLogs(userId);
    } catch (e) {
      _showError('Failed to load user details: ${e.toString()}');
    }
  }

  /// Load user analytics
  Future<void> loadUserAnalytics(String userId) async {
    try {
      final analytics = await _dataService.getUserAnalytics(userId);
      _userAnalytics.assignAll(analytics);
    } catch (e) {
      _showError('Failed to load user analytics: ${e.toString()}');
    }
  }

  /// Load user action logs
  Future<void> loadUserActionLogs(String userId) async {
    try {
      final logs = await _dataService.getUserRecentActions(userId, limit: 50);
      _userActionLogs.assignAll(logs);
    } catch (e) {
      _showError('Failed to load user activity logs: ${e.toString()}');
    }
  }

  /// Get color for user priority/status visualization
  Color getPriorityColor(dynamic user) {
    if (user is admin_models.AdminUserModel) {
      if (user.isRestricted) {
        return Colors.red;
      } else if (user.isSuspicious) {
        return Colors.orange;
      } else if (user.flags.isNotEmpty) {
        return Colors.amber;
      }
      return Colors.green;
    } else if (user is UserModel) {
      // For regular user model with limited properties
      if (user.isActive == false) {
        return Colors.grey;
      }
      return Colors.green;
    }
    
    return Colors.grey;
  }

  /// Restrict user (suspend, ban, etc.)
  Future<void> handleRestrictUser(String userId, String restrictionType, String reason, {DateTime? expiresAt}) async {
    try {
      await _dataService.restrictUser(userId, restrictionType, reason, expiresAt: expiresAt);
      _showSuccess('User restricted successfully');
      
      // Refresh the user in the list
      await _refreshUserInList(userId);
    } catch (e) {
      _showError('Failed to restrict user: ${e.toString()}');
    }
  }

  /// Remove restriction from user
  Future<void> handleRemoveRestriction(String userId) async {
    try {
      await _dataService.removeRestriction(userId);
      _showSuccess('Restriction removed successfully');
      
      // Refresh the user in the list
      await _refreshUserInList(userId);
    } catch (e) {
      _showError('Failed to remove restriction: ${e.toString()}');
    }
  }

  /// Delete user
  Future<void> handleDeleteUser(String userId, String reason) async {
    try {
      await _dataService.deleteUserProfile(userId, reason);
      _showSuccess('User deleted successfully');
      
      // Remove user from the list
      _users.removeWhere((user) => user.id == userId);
      _selectedUser.value = null;
    } catch (e) {
      _showError('Failed to delete user: ${e.toString()}');
    }
  }

  /// Flag user as suspicious
  Future<void> handleFlagUser(String userId, List<String> flags, String reason) async {
    try {
      await _dataService.flagUserAsSuspicious(userId, flags, reason);
      _showSuccess('User flagged successfully');
      
      // Refresh the user in the list
      await _refreshUserInList(userId);
    } catch (e) {
      _showError('Failed to flag user: ${e.toString()}');
    }
  }
  
  /// Remove flag from user
  Future<void> handleRemoveFlag(String userId, String flag) async {
    try {
      await _dataService.removeUserFlag(userId, flag);
      _showSuccess('Flag removed successfully');
      
      // Refresh the user in the list
      await _refreshUserInList(userId);
    } catch (e) {
      _showError('Failed to remove flag: ${e.toString()}');
    }
  }
  
  /// Verify user
  Future<void> handleVerifyUser(String userId) async {
    try {
      await _dataService.verifyUser(userId);
      _showSuccess('User verified successfully');
      
      // Refresh the user in the list
      await _refreshUserInList(userId);
    } catch (e) {
      _showError('Failed to verify user: ${e.toString()}');
    }
  }
  
  /// Update user status
  Future<void> handleUpdateUserStatus(String userId, String status, {String? reason}) async {
    try {
      await _dataService.updateUserStatus(userId, status, reason: reason);
      _showSuccess('User status updated successfully');
      
      // Refresh the user in the list
      await _refreshUserInList(userId);
    } catch (e) {
      _showError('Failed to update user status: ${e.toString()}');
    }
  }
  
  /// Add admin notes to user
  Future<void> handleAddAdminNotes(String userId, String notes) async {
    try {
      await _dataService.addAdminNotes(userId, notes);
      _showSuccess('Notes added successfully');
      
      // Refresh the user in the list
      await _refreshUserInList(userId);
    } catch (e) {
      _showError('Failed to add notes: ${e.toString()}');
    }
  }

  /// Helper method to refresh a single user in the list
  Future<void> _refreshUserInList(String userId) async {
    try {
      final updatedUser = await _dataService.getUserById(userId);
      if (updatedUser != null) {
        // Update in the main list
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = updatedUser;
        }
        
        // Update in search results if present
        final searchIndex = _userSearchResults.indexWhere((u) => u.id == userId);
        if (searchIndex != -1) {
          _userSearchResults[searchIndex] = updatedUser;
        }
        
        // Update selected user if it's the same
        if (_selectedUser.value?.id == userId) {
          _selectedUser.value = updatedUser;
        }
      }
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Ad Management Methods
  Future<void> updateAdStatusEnhanced(String adId, String status, {String? reason}) async {
    try {
      await _dataService.updateAdStatus(adId, status, reason: reason);
      await loadAds(refresh: true);
      _showSuccess('Ad status updated successfully');
    } catch (e) {
      _showError('Failed to update ad status: ${e.toString()}');
    }
  }

  Future<void> deleteAd(String adId, {String? reason}) async {
    try {
      await _dataService.deleteAd(adId);
      await loadAds(refresh: true);
      _showSuccess('Ad deleted successfully');
    } catch (e) {
      _showError('Failed to delete ad: ${e.toString()}');
    }
  }

  Future<void> fixAdSearchKeys() async {
    try {
      _isLoadingAds.value = true;
      
      // Get all ads
      final QuerySnapshot adsSnapshot = await FirebaseFirestore.instance
          .collection('ads')
          .get();

      int fixedCount = 0;
      for (var doc in adsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final carMake = data['car_make']?.toString().toLowerCase() ?? '';
          final carModel = data['car_model']?.toString().toLowerCase() ?? '';
          
          if (carMake.isNotEmpty || carModel.isNotEmpty) {
            // Generate search keys
            final searchKeys = <String>{};
            
            // Add complete words
            searchKeys.add(carMake);
            searchKeys.add(carModel);
            searchKeys.add('$carMake $carModel');
            
            // Add partial matches (prefixes)
            for (int i = 1; i <= carMake.length; i++) {
              searchKeys.add(carMake.substring(0, i));
            }
            for (int i = 1; i <= carModel.length; i++) {
              searchKeys.add(carModel.substring(0, i));
            }
            
            // Update the document with search keys
            await doc.reference.update({
              'search_keys': searchKeys.where((key) => key.isNotEmpty).toList(),
              'updated_at': Timestamp.now(),
            });
            
            fixedCount++;
          }
        } catch (e) {
          print('Error fixing search keys for doc ${doc.id}: $e');
        }
      }
      
      _showSuccess('Fixed search keys for $fixedCount ads');
    } catch (e) {
      _showError('Failed to fix search keys: ${e.toString()}');
    } finally {
      _isLoadingAds.value = false;
    }
  }

  Future<void> fixAllAdsData() async {
    try {
      _isLoadingAds.value = true;
      
      // Get all ads
      final QuerySnapshot adsSnapshot = await FirebaseFirestore.instance
          .collection('ads')
          .get();

      int fixedCount = 0;
      for (var doc in adsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final updates = <String, dynamic>{};
          
          // Fix missing fields
          if (!data.containsKey('status')) {
            updates['status'] = 'active';
          }
          
          if (!data.containsKey('created_at') && data.containsKey('date_time')) {
            updates['created_at'] = data['date_time'];
          }
          
          if (!data.containsKey('updated_at')) {
            updates['updated_at'] = data.containsKey('created_at') 
                ? data['created_at'] 
                : Timestamp.now();
          }
          
          // Fix search keys
          final carMake = data['car_make']?.toString().toLowerCase() ?? '';
          final carModel = data['car_model']?.toString().toLowerCase() ?? '';
          
          if (carMake.isNotEmpty || carModel.isNotEmpty) {
            final searchKeys = <String>{};
            
            searchKeys.add(carMake);
            searchKeys.add(carModel);
            searchKeys.add('$carMake $carModel');
            
            for (int i = 1; i <= carMake.length; i++) {
              searchKeys.add(carMake.substring(0, i));
            }
            for (int i = 1; i <= carModel.length; i++) {
              searchKeys.add(carModel.substring(0, i));
            }
            
            updates['search_keys'] = searchKeys.where((key) => key.isNotEmpty).toList();
          }
          
          // Fix image URLs format
          if (data.containsKey('car_img_url')) {
            final imageUrls = data['car_img_url'];
            if (imageUrls is String) {
              updates['car_img_url'] = [imageUrls];
            }
          }
          
          if (updates.isNotEmpty) {
            updates['updated_at'] = Timestamp.now();
            await doc.reference.update(updates);
            fixedCount++;
          }
        } catch (e) {
          print('Error fixing data for doc ${doc.id}: $e');
        }
      }
      
      _showSuccess('Fixed data for $fixedCount ads');
      await loadAds(refresh: true);
    } catch (e) {
      _showError('Failed to fix ads data: ${e.toString()}');
    } finally {
      _isLoadingAds.value = false;
    }
  }

  // Bid Management Methods
  Future<void> updateBidStatus(String bidId, String status, {String? adminNotes}) async {
    try {
      await _dataService.updateBidStatus(bidId, status, adminNotes: adminNotes);
      await loadBids(refresh: true);
      _showSuccess('Bid status updated successfully');
    } catch (e) {
      _showError('Failed to update bid status: ${e.toString()}');
    }
  }

  Future<void> deleteBid(String bidId, {String? reason}) async {
    try {
      await _dataService.deleteBid(bidId, reason: reason);
      await loadBids(refresh: true);
      _showSuccess('Bid deleted successfully');
    } catch (e) {
      _showError('Failed to delete bid: ${e.toString()}');
    }
  }

  // Stats and General Methods
  Future<void> loadStats() async {
    _isLoadingStats.value = true;
    try {
      final stats = await _dataService.getDashboardStats();
      _stats.value = stats;
    } catch (e) {
      print('loadStats error: $e');
      _showError('Failed to load stats: ${e.toString()}');
    } finally {
      _isLoadingStats.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadStats(),
      loadUsers(refresh: true),
      loadAds(refresh: true),
      loadBids(refresh: true),
      loadEvents(refresh: true),
    ]);
  }

  // Event Management Methods
  Future<void> createEvent(AdminEventModel event) async {
    try {
      await _dataService.createEvent(event);
      await loadEvents(refresh: true);
      _showSuccess('Event created successfully');
    } catch (e) {
      _showError('Failed to create event: ${e.toString()}');
    }
  }

  // Version without showing success message (for UI management)
  Future<void> createEventSilent(AdminEventModel event) async {
    try {
      await _dataService.createEvent(event);
      await loadEvents(refresh: true);
    } catch (e) {
      throw Exception('Failed to create event: ${e.toString()}');
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _dataService.updateEvent(eventId, updates);
      await loadEvents(refresh: true);
      _showSuccess('Event updated successfully');
    } catch (e) {
      _showError('Failed to update event: ${e.toString()}');
    }
  }

  // Version without showing success message (for UI management)
  Future<void> updateEventSilent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _dataService.updateEvent(eventId, updates);
      await loadEvents(refresh: true);
    } catch (e) {
      throw Exception('Failed to update event: ${e.toString()}');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _dataService.deleteEvent(eventId);
      await loadEvents(refresh: true);
      _showSuccess('Event deleted successfully');
    } catch (e) {
      _showError('Failed to delete event: ${e.toString()}');
    }
  }

  /// Get car details by ID
  Future<CarModel?> getCarById(String carId) async {
    try {
      return await _dataService.getCarById(carId);
    } catch (e) {
      print('Error fetching car details: $e');
      return null;
    }
  }
}
