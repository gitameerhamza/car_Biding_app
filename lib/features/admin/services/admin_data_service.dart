import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/admin_data_models.dart';
import '../models/user_management_model.dart' as admin_models;
import '../../home/models/car_model.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_service.dart';
import 'admin_auth_service.dart';

class AdminDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminAuthService _authService = AdminAuthService();
  final UserService _userService = UserService();

  // Event Management
  Future<List<AdminEventModel>> getAllEvents() async {
    if (!await _authService.hasPermission('manage_events')) {
      throw Exception('Insufficient permissions');
    }

    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdminEventModel.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createEvent(AdminEventModel event) async {
    if (!await _authService.hasPermission('manage_events')) {
      throw Exception('Insufficient permissions');
    }

    try {
      final docRef = await _firestore
          .collection('events')
          .add(event.toJson());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    if (!await _authService.hasPermission('manage_events')) {
      throw Exception('Insufficient permissions');
    }

    updates['updated_at'] = Timestamp.now();
    await _firestore
        .collection('events')
        .doc(eventId)
        .update(updates);
  }

  Future<void> deleteEvent(String eventId) async {
    if (!await _authService.hasPermission('manage_events')) {
      throw Exception('Insufficient permissions');
    }

    await _firestore
        .collection('events')
        .doc(eventId)
        .delete();
  }

  // Ad Management
  Future<List<CarModel>> getAllAds({
    String? status,
    String? orderBy = 'created_at',
    bool descending = true,
    int? limit,
  }) async {
    if (!await _authService.hasPermission('manage_ads')) {
      throw Exception('Insufficient permissions');
    }

    try {
      Query query = _firestore.collection('ads');

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy(orderBy!, descending: descending);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CarModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAdStatus(String adId, String status, {String? reason}) async {
    if (!await _authService.hasPermission('manage_ads')) {
      throw Exception('Insufficient permissions');
    }

    // Get ad data to find the user who posted it
    final adDoc = await _firestore.collection('ads').doc(adId).get();
    if (!adDoc.exists) {
      throw Exception('Ad not found');
    }
    
    final adData = adDoc.data()!;
    final userId = adData['posted_by'] as String?;

    final updates = {
      'status': status,
      'updated_at': Timestamp.now(),
    };

    if (reason != null) {
      updates['admin_notes'] = reason;
    }

    await _firestore
        .collection('ads')
        .doc(adId)
        .update(updates);

    // Refresh user statistics if user ID is available
    if (userId != null) {
      try {
        await _userService.refreshUserStats(userId);
      } catch (e) {
        // Don't fail the main operation if stats update fails
        print('Failed to update user stats: $e');
      }
    }
  }

  Future<void> deleteAd(String adId) async {
    if (!await _authService.hasPermission('delete_any_content')) {
      throw Exception('Insufficient permissions');
    }

    // Get ad data to delete associated images and find user ID
    final adDoc = await _firestore.collection('ads').doc(adId).get();
    String? userId;
    
    if (adDoc.exists) {
      final adData = adDoc.data()!;
      
      // Delete images from Firebase Storage
      if (adData.containsKey('car_img_url')) {
        final imageUrls = adData['car_img_url'] is String 
            ? [adData['car_img_url']] 
            : (adData['car_img_url'] as List<dynamic>).cast<String>();
        
        final storage = FirebaseStorage.instance;
        
        for (final imageUrl in imageUrls) {
          try {
            // Extract the reference path from the URL
            final ref = storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting image from storage: $e');
            // Continue with other operations even if image deletion fails
          }
        }
      }
      
      // Get user ID for stats update
      userId = adData['posted_by'] as String?;
    }

    // Delete the ad document
    await _firestore
        .collection('ads')
        .doc(adId)
        .delete();

    // Delete associated bids
    final bidsSnapshot = await _firestore
        .collection('bids')
        .where('car_id', isEqualTo: adId)
        .get();

    for (var bidDoc in bidsSnapshot.docs) {
      await bidDoc.reference.delete();
    }

    // Refresh user statistics if user ID is available
    if (userId != null) {
      try {
        await _userService.refreshUserStats(userId);
      } catch (e) {
        // Don't fail the main operation if stats update fails
        print('Failed to update user stats: $e');
      }
    }
  }

  // Bid Management
  Future<List<BidModel>> getAllBids({
    String? carId,
    String? status,
    String? orderBy = 'bid_time',
    bool descending = true,
    int? limit,
  }) async {
    print('AdminDataService.getAllBids: Starting with carId=$carId, status=$status, orderBy=$orderBy, limit=$limit');
    
    if (!await _authService.hasPermission('manage_bids')) {
      print('AdminDataService.getAllBids: Permission denied');
      throw Exception('Insufficient permissions');
    }

    try {
      Query query = _firestore.collection('bids');

      if (carId != null && carId.isNotEmpty) {
        query = query.where('car_id', isEqualTo: carId);
      }

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy(orderBy!, descending: descending);

      if (limit != null) {
        query = query.limit(limit);
      }

      print('AdminDataService.getAllBids: Executing query...');
      final snapshot = await query.get();
      print('AdminDataService.getAllBids: Found ${snapshot.docs.length} documents');
      
      final bids = snapshot.docs
          .map((doc) => BidModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
          
      print('AdminDataService.getAllBids: Parsed ${bids.length} bid models');
      return bids;
    } catch (e) {
      print('AdminDataService.getAllBids: Error: $e');
      rethrow;
    }
  }

  Future<void> deleteBid(String bidId, {String? reason}) async {
    if (!await _authService.hasPermission('manage_bids')) {
      throw Exception('Insufficient permissions');
    }

    // Log the deletion for audit purposes
    final bidDoc = await _firestore.collection('bids').doc(bidId).get();
    if (bidDoc.exists) {
      final bidData = bidDoc.data()!;
      bidData['deleted_at'] = Timestamp.now();
      bidData['deleted_by'] = (await _authService.getCurrentAdmin())?.id;
      bidData['deletion_reason'] = reason;

      await _firestore
          .collection('deleted_bids')
          .doc(bidId)
          .set(bidData);
    }

    await _firestore
        .collection('bids')
        .doc(bidId)
        .delete();
  }

  Future<void> updateBidStatus(String bidId, String status, {String? adminNotes}) async {
    if (!await _authService.hasPermission('manage_bids')) {
      throw Exception('Insufficient permissions');
    }

    final updates = {
      'status': status,
      'updated_at': Timestamp.now(),
    };

    if (adminNotes != null) {
      updates['admin_notes'] = adminNotes;
    }

    await _firestore
        .collection('bids')
        .doc(bidId)
        .update(updates);
  }

  // User Management
  Future<List<admin_models.AdminUserModel>> getAllUsers({
    bool? isRestricted,
    bool? isSuspicious,
    String? accountStatus,
    bool? requiresVerification,
    String? orderBy = 'createdAt',
    bool descending = true,
    int? limit,
    String? searchQuery,
  }) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }

    try {
      Query query = _firestore.collection('users');

      if (isRestricted != null) {
        query = query.where('isRestricted', isEqualTo: isRestricted);
      }

      if (accountStatus != null) {
        query = query.where('accountStatus', isEqualTo: accountStatus);
      }

      query = query.orderBy(orderBy!, descending: descending);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Convert to AdminUserModel with enhanced data
      final adminUsers = <admin_models.AdminUserModel>[];
      
      for (final user in users) {
        // Get user restrictions if any
        List<admin_models.UserRestrictionModel> restrictions = await getUserRestrictions(user.id);
        
        // Get recent user actions if needed for analysis
        List<admin_models.UserActionLogModel> recentActions = await getUserRecentActions(user.id);
        
        final adminUser = admin_models.AdminUserModel.fromUserModel(
          user.id,
          snapshot.docs.firstWhere((doc) => doc.id == user.id).data() as Map<String, dynamic>,
          userRestrictions: restrictions,
          userActions: recentActions,
        );
        
        // Filter based on query parameters
        bool shouldInclude = true;
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          final nameMatch = adminUser.fullName.toLowerCase().contains(searchLower);
          final emailMatch = adminUser.email.toLowerCase().contains(searchLower);
          final usernameMatch = adminUser.username.toLowerCase().contains(searchLower);
          
          if (!nameMatch && !emailMatch && !usernameMatch) {
            shouldInclude = false;
          }
        }
        
        if (isSuspicious != null && isSuspicious != adminUser.isSuspicious) {
          shouldInclude = false;
        }
        
        if (requiresVerification != null && requiresVerification != adminUser.requiresVerification) {
          shouldInclude = false;
        }
        
        if (shouldInclude) {
          adminUsers.add(adminUser);
        }
      }

      return adminUsers;
    } catch (e) {
      rethrow;
    }
  }

  Future<admin_models.AdminUserModel?> getUserById(String userId) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      // Get user restrictions if any
      List<admin_models.UserRestrictionModel> restrictions = await getUserRestrictions(userId);
      
      // Get recent user actions
      List<admin_models.UserActionLogModel> recentActions = await getUserRecentActions(userId);
      
      return admin_models.AdminUserModel.fromUserModel(
        userDoc.id, 
        userDoc.data()!,
        userRestrictions: restrictions,
        userActions: recentActions,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<admin_models.UserRestrictionModel>> getUserRestrictions(String userId) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    try {
      final restrictionsSnapshot = await _firestore
          .collection('user_restrictions')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
          
      return restrictionsSnapshot.docs
          .map((doc) => admin_models.UserRestrictionModel.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<admin_models.UserActionLogModel>> getUserRecentActions(String userId, {int limit = 10}) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    try {
      final actionsSnapshot = await _firestore
          .collection('user_actions')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
          
      return actionsSnapshot.docs
          .map((doc) => admin_models.UserActionLogModel.fromJson(doc.id, doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restrictUser(String userId, String restrictionType, String reason, {DateTime? expiresAt}) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }

    final admin = await _authService.getCurrentAdmin();
    if (admin == null) throw Exception('Admin not found');
    
    // Get user email for record-keeping
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    final userEmail = userDoc.data()?['email'] ?? '';

    // Update user restriction status and account status
    final updates = {
      'isRestricted': true,
      'restrictionType': restrictionType,
      'updatedAt': Timestamp.now(),
    };
    
    // Update account status based on restriction type
    if (restrictionType == 'banned') {
      updates['accountStatus'] = 'banned';
    } else if (restrictionType == 'suspended') {
      updates['accountStatus'] = 'suspended';
    } else {
      updates['accountStatus'] = 'restricted';
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .update(updates);

    // Create restriction record
    final restriction = admin_models.UserRestrictionModel(
      id: '',
      userId: userId,
      userEmail: userEmail,
      restrictionType: restrictionType,
      reason: reason,
      adminId: admin.id,
      createdAt: Timestamp.now(),
      expiresAt: expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      isActive: true,
    );

    await _firestore
        .collection('user_restrictions')
        .add(restriction.toJson());

    // Log the action
    await _logAdminAction('restrict_user', {
      'user_id': userId,
      'user_email': userEmail,
      'restriction_type': restrictionType,
      'reason': reason,
      'expires_at': expiresAt?.toIso8601String(),
    });
  }
  
  Future<void> removeRestriction(String userId) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    final admin = await _authService.getCurrentAdmin();
    if (admin == null) throw Exception('Admin not found');
    
    // Get user email for record-keeping
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    final userEmail = userDoc.data()?['email'] ?? '';

    // Update user restriction status
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
          'isRestricted': false,
          'restrictionType': null,
          'accountStatus': 'active',
          'updatedAt': Timestamp.now(),
        });
        
    // Mark all active restrictions as inactive
    final restrictionsSnapshot = await _firestore
        .collection('user_restrictions')
        .where('user_id', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .get();
        
    final batch = _firestore.batch();
    for (final doc in restrictionsSnapshot.docs) {
      batch.update(doc.reference, {
        'is_active': false,
        'ended_at': Timestamp.now(),
        'ended_by_admin_id': admin.id,
      });
    }
    
    await batch.commit();
    
    // Log the action
    await _logAdminAction('remove_restriction', {
      'user_id': userId,
      'user_email': userEmail,
    });
  }

  Future<void> updateUserStatus(String userId, String status, {String? reason}) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    final admin = await _authService.getCurrentAdmin();
    if (admin == null) throw Exception('Admin not found');
    
    // Get user email for record-keeping
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    final userEmail = userDoc.data()?['email'] ?? '';

    // Update user status
    final updates = {
      'accountStatus': status,
      'updatedAt': Timestamp.now(),
    };

    // Set isActive based on status
    if (status == 'active') {
      updates['isActive'] = true;
    } else if (status == 'deactivated' || status == 'banned' || status == 'suspended') {
      updates['isActive'] = false;
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .update(updates);
    
    // Log the action
    await _logAdminAction('update_user_status', {
      'user_id': userId,
      'user_email': userEmail,
      'status': status,
      'reason': reason,
    });
  }

  Future<void> verifyUser(String userId) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    // Get user email for record-keeping
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    final userEmail = userDoc.data()?['email'] ?? '';

    // Update user verification status
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
          'isVerified': true,
          'updatedAt': Timestamp.now(),
        });
    
    // Log the action
    await _logAdminAction('verify_user', {
      'user_id': userId,
      'user_email': userEmail,
    });
  }

  Future<void> addAdminNotes(String userId, String notes) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    
    // Get existing admin notes if any
    final currentData = userDoc.data()!;
    final existingNotes = currentData['adminNotes'] as Map<String, dynamic>? ?? {};
    
    // Add new note with timestamp
    final admin = await _authService.getCurrentAdmin();
    final noteKey = DateTime.now().toIso8601String();
    existingNotes[noteKey] = {
      'content': notes,
      'admin_id': admin?.id ?? 'unknown',
      'timestamp': Timestamp.now(),
    };

    // Update the document
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
          'adminNotes': existingNotes,
          'updatedAt': Timestamp.now(),
        });
  }

  Future<void> deleteUserProfile(String userId, String reason) async {
    if (!await _authService.hasPermission('delete_any_content')) {
      throw Exception('Insufficient permissions');
    }

    final batch = _firestore.batch();
    
    // Get user email for record-keeping
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    final userEmail = userDoc.data()?['email'] ?? '';

    // Get user data for backup before deletion
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      userData['deleted_at'] = Timestamp.now();
      userData['deleted_by'] = (await _authService.getCurrentAdmin())?.id;
      userData['deletion_reason'] = reason;

      // Backup to deleted_users collection
      batch.set(_firestore.collection('deleted_users').doc(userId), userData);
    }

    // Delete user profile
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete user's ads
    final adsSnapshot = await _firestore
        .collection('ads')
        .where('posted_by', isEqualTo: userId)
        .get();

    for (var adDoc in adsSnapshot.docs) {
      batch.delete(adDoc.reference);
    }

    // Delete user's bids
    final bidsSnapshot = await _firestore
        .collection('bids')
        .where('bidder_id', isEqualTo: userId)
        .get();

    for (var bidDoc in bidsSnapshot.docs) {
      batch.delete(bidDoc.reference);
    }

    // Delete user's messages
    final messagesSnapshot = await _firestore
        .collection('messages')
        .where('sender_id', isEqualTo: userId)
        .get();

    for (var msgDoc in messagesSnapshot.docs) {
      batch.delete(msgDoc.reference);
    }

    // Delete user's chat rooms
    final chatRoomsQuery1 = await _firestore
        .collection('chat_rooms')
        .where('user1_id', isEqualTo: userId)
        .get();

    for (var roomDoc in chatRoomsQuery1.docs) {
      batch.delete(roomDoc.reference);
    }

    final chatRoomsQuery2 = await _firestore
        .collection('chat_rooms')
        .where('user2_id', isEqualTo: userId)
        .get();

    for (var roomDoc in chatRoomsQuery2.docs) {
      batch.delete(roomDoc.reference);
    }

    await batch.commit();

    // Log the action
    await _logAdminAction('delete_user', {
      'user_id': userId,
      'user_email': userEmail,
      'reason': reason,
    });
  }

  Future<void> flagUserAsSuspicious(String userId, List<String> flags, String reason) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    // Get user email for record-keeping
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    final userEmail = userDoc.data()?['email'] ?? '';
    
    // Get existing flags if any
    final existingData = userDoc.data()!;
    final existingFlags = List<String>.from(existingData['flags'] ?? []);
    
    // Merge flags, removing duplicates
    final allFlags = Set<String>.from(existingFlags)
      ..addAll(flags);
      
    // Update user flags
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
          'flags': List<String>.from(allFlags),
          'updatedAt': Timestamp.now(),
        });
    
    // Log the action
    await _logAdminAction('flag_user', {
      'user_id': userId,
      'user_email': userEmail,
      'flags': flags,
      'reason': reason,
    });
  }

  Future<void> removeUserFlag(String userId, String flag) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    // Get user email for record-keeping
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User not found');
    
    // Get existing flags
    final existingData = userDoc.data()!;
    final existingFlags = List<String>.from(existingData['flags'] ?? []);
    
    // Remove the specified flag
    existingFlags.remove(flag);
      
    // Update user flags
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
          'flags': existingFlags,
          'updatedAt': Timestamp.now(),
        });
  }

  Future<List<Map<String, dynamic>>> getUserAnalytics(String userId) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }
    
    try {
      final result = <Map<String, dynamic>>[];
      
      // Get user's ads over time
      final adsSnapshot = await _firestore
          .collection('ads')
          .where('posted_by', isEqualTo: userId)
          .orderBy('created_at')
          .get();
          
      final adsDates = adsSnapshot.docs
          .map((doc) => (doc.data()['created_at'] as Timestamp).toDate())
          .toList();
          
      // Get user's bids over time
      final bidsSnapshot = await _firestore
          .collection('bids')
          .where('bidder_id', isEqualTo: userId)
          .orderBy('bid_time')
          .get();
          
      final bidsDates = bidsSnapshot.docs
          .map((doc) => (doc.data()['bid_time'] as Timestamp).toDate())
          .toList();
      
      // Group data by month for charting
      final monthlyAds = <String, int>{};
      final monthlyBids = <String, int>{};
      
      for (final date in adsDates) {
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyAds[monthKey] = (monthlyAds[monthKey] ?? 0) + 1;
      }
      
      for (final date in bidsDates) {
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyBids[monthKey] = (monthlyBids[monthKey] ?? 0) + 1;
      }
      
      // Format data for charts
      result.add({
        'type': 'monthly_ads',
        'data': monthlyAds.entries.map((e) => {
          'month': e.key,
          'count': e.value,
        }).toList(),
      });
      
      result.add({
        'type': 'monthly_bids',
        'data': monthlyBids.entries.map((e) => {
          'month': e.key,
          'count': e.value,
        }).toList(),
      });
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Dashboard Stats
  Future<AdminStatsModel> getDashboardStats() async {
    // Get current admin for debugging
    final currentAdmin = await _authService.getCurrentAdmin();
    if (currentAdmin == null) {
      throw Exception('No admin user logged in');
    }

    // Check for view_stats permission specifically for dashboard statistics
    final hasViewStatsPermission = await _authService.hasPermission('view_stats');
    final hasViewDashboardPermission = await _authService.hasPermission('view_dashboard');
    
    print('getDashboardStats: Admin email: ${currentAdmin.email}');
    print('getDashboardStats: Admin permissions: ${currentAdmin.permissions}');
    print('getDashboardStats: Has view_stats: $hasViewStatsPermission');
    print('getDashboardStats: Has view_dashboard: $hasViewDashboardPermission');
    
    // For now, bypass permission check if user is a valid admin with the admin role
    // This is a temporary fix while we update the permissions
    final isValidAdmin = currentAdmin.role == 'admin' && 
                        currentAdmin.isActive && 
                        currentAdmin.permissions.isNotEmpty;
    
    if (!isValidAdmin && !hasViewStatsPermission && !hasViewDashboardPermission) {
      throw Exception('Insufficient permissions to view dashboard statistics');
    }

    // If admin is missing view permissions but has admin role, update permissions
    if (isValidAdmin && (!hasViewStatsPermission || !hasViewDashboardPermission)) {
      print('getDashboardStats: Admin missing view permissions, attempting to update...');
      try {
        await _authService.ensureAdminPermissions();
      } catch (e) {
        print('getDashboardStats: Failed to update permissions: $e');
      }
    }

    try {
      // Get counts for all major collections
      final usersSnapshot = await _firestore.collection('users').count().get();
      final adsSnapshot = await _firestore.collection('ads').count().get();
      final bidsSnapshot = await _firestore.collection('bids').count().get();
      final eventsSnapshot = await _firestore.collection('events').count().get();

      // Get active counts
      final activeAdsSnapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      // Get today's new users and ads
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      
      final todayUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startOfToday))
          .count()
          .get();

      final todayAdsSnapshot = await _firestore
          .collection('ads')
          .where('created_at', isGreaterThan: Timestamp.fromDate(startOfToday))
          .count()
          .get();

      // Get pending ads
      final pendingAdsSnapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return AdminStatsModel(
        id: 'current_stats',
        totalUsers: usersSnapshot.count ?? 0,
        totalAds: adsSnapshot.count ?? 0,
        totalBids: bidsSnapshot.count ?? 0,
        totalEvents: eventsSnapshot.count ?? 0,
        activeAds: activeAdsSnapshot.count ?? 0,
        pendingAds: pendingAdsSnapshot.count ?? 0,
        todayNewUsers: todayUsersSnapshot.count ?? 0,
        todayNewAds: todayAdsSnapshot.count ?? 0,
        lastUpdated: Timestamp.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Log admin action for audit trail
  Future<void> _logAdminAction(String actionType, Map<String, dynamic> details) async {
    final admin = await _authService.getCurrentAdmin();
    if (admin == null) return;
    
    await _firestore.collection('admin_logs').add({
      'admin_id': admin.id,
      'admin_email': admin.email,
      'action_type': actionType,
      'details': details,
      'timestamp': Timestamp.now(),
    });
  }
  
  // Search functionality
  Future<List<admin_models.AdminUserModel>> searchUsers(String query) async {
    if (!await _authService.hasPermission('manage_users')) {
      throw Exception('Insufficient permissions');
    }

    try {
      final lowercaseQuery = query.toLowerCase();
      
      // Search by email first (most common search)
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('email', isLessThanOrEqualTo: lowercaseQuery + '\uf8ff')
          .limit(20)
          .get();

      // Also search by fullName and username
      final nameSnapshot = await _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('fullName', isLessThanOrEqualTo: lowercaseQuery + '\uf8ff')
          .limit(10)
          .get();

      final usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('username', isLessThanOrEqualTo: lowercaseQuery + '\uf8ff')
          .limit(10)
          .get();

      // Combine results and remove duplicates based on ID
      final userMap = <String, admin_models.AdminUserModel>{};
      
      for (final doc in emailSnapshot.docs) {
        userMap[doc.id] = admin_models.AdminUserModel.fromUserModel(doc.id, doc.data());
      }
      
      for (final doc in nameSnapshot.docs) {
        if (!userMap.containsKey(doc.id)) {
          userMap[doc.id] = admin_models.AdminUserModel.fromUserModel(doc.id, doc.data());
        }
      }
      
      for (final doc in usernameSnapshot.docs) {
        if (!userMap.containsKey(doc.id)) {
          userMap[doc.id] = admin_models.AdminUserModel.fromUserModel(doc.id, doc.data());
        }
      }

      return userMap.values.toList();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<CarModel>> searchAds(String query) async {
    if (!await _authService.hasPermission('manage_ads')) {
      throw Exception('Insufficient permissions');
    }

    try {
      final queryLower = query.toLowerCase().trim();
      if (queryLower.isEmpty) return [];

      // First try searching with search_keys
      var snapshot = await _firestore
          .collection('ads')
          .where('search_keys', arrayContains: queryLower)
          .limit(20)
          .get();

      List<CarModel> results = snapshot.docs
          .map((doc) => CarModel.fromJson(doc.id, doc.data()))
          .toList();

      // If no results found, try searching by car name or make
      if (results.isEmpty) {
        final carNameSnapshot = await _firestore
            .collection('ads')
            .where('car_name', isGreaterThanOrEqualTo: queryLower)
            .where('car_name', isLessThanOrEqualTo: '$queryLower\uf8ff')
            .limit(10)
            .get();

        final makeSnapshot = await _firestore
            .collection('ads')
            .where('car_make', isGreaterThanOrEqualTo: queryLower)
            .where('car_make', isLessThanOrEqualTo: '$queryLower\uf8ff')
            .limit(10)
            .get();

        results.addAll(carNameSnapshot.docs
            .map((doc) => CarModel.fromJson(doc.id, doc.data()))
            .toList());
        
        results.addAll(makeSnapshot.docs
            .map((doc) => CarModel.fromJson(doc.id, doc.data()))
            .toList());

        // Remove duplicates
        final seen = <String>{};
        results = results.where((ad) => seen.add(ad.id)).toList();
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  // Utility method to fix existing ads that might be missing search keys
  Future<void> fixMissingSearchKeys() async {
    if (!await _authService.hasPermission('manage_ads')) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Get all ads without search_keys field
      final snapshot = await _firestore
          .collection('ads')
          .get();

      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Check if search_keys field is missing or empty
        if (!data.containsKey('search_keys') || 
            (data['search_keys'] as List?)?.isEmpty == true) {
          
          final carName = data['car_name'] ?? '';
          final carMake = data['car_make'] ?? '';
          final location = data['car_location'] ?? '';
          
          // Generate search keys similar to the add_car_controller
          List<String> searchKeys = [];
          
          // Add car name search keys
          if (carName.isNotEmpty) {
            List<String> nameWords = carName.toString()
                .replaceAll(RegExp('[^A-Za-z0-9& ]'), '')
                .split(" ");
            
            for (int i = 0; i < nameWords.length; i++) {
              if (i != nameWords.length - 1) {
                searchKeys.add(nameWords[i].trim().toLowerCase());
              }
              List<String> temp = [nameWords[i].trim().toLowerCase()];
              for (int j = i + 1; j < nameWords.length; j++) {
                temp.add(nameWords[j].trim().toLowerCase());
                searchKeys.add(temp.join(' '));
              }
            }
          }
          
          // Add make search keys
          if (carMake.isNotEmpty) {
            searchKeys.add(carMake.toString().toLowerCase());
          }
          
          // Add location search keys
          if (location.isNotEmpty) {
            searchKeys.add(location.toString().toLowerCase());
          }
          
          // Remove duplicates
          searchKeys = searchKeys.toSet().toList();
          
          batch.update(doc.reference, {'search_keys': searchKeys});
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        await _logAdminAction('fix_search_keys', {
          'updated_ads_count': updateCount,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific car by ID
  Future<CarModel?> getCarById(String carId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('ads').doc(carId).get();
      
      if (doc.exists && doc.data() != null) {
        return CarModel.fromJson(doc.id, doc.data()!);
      }
      
      return null;
    } catch (e) {
      print('Error getting car by ID: $e');
      return null;
    }
  }
}
