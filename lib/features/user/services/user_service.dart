import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromJson(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get user profile by ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return UserModel.fromJson(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel userModel) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updatedData = userModel.copyWith(
        updatedAt: Timestamp.now(),
      ).toJson();

      await _firestore.collection('users').doc(user.uid).update(updatedData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Create user profile (called during registration)
  Future<void> createUserProfile(UserModel userModel) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Update user statistics
  Future<void> updateUserStats(String userId, {int? totalAds, int? totalBids}) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (totalAds != null) {
        updates['totalAds'] = totalAds;
      }
      if (totalBids != null) {
        updates['totalBids'] = totalBids;
      }

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  // Increment user statistics
  Future<void> incrementUserAds(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalAds': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment user ads: $e');
    }
  }

  Future<void> decrementUserAds(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalAds': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to decrement user ads: $e');
    }
  }

  Future<void> incrementUserBids(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalBids': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to increment user bids: $e');
    }
  }

  // Check username availability
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // Search users by name or username
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final nameQuery = await _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      final users = <UserModel>[];
      final seenIds = <String>{};

      for (final doc in nameQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          users.add(UserModel.fromJson(doc.id, doc.data()));
          seenIds.add(doc.id);
        }
      }

      for (final doc in usernameQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          users.add(UserModel.fromJson(doc.id, doc.data()));
          seenIds.add(doc.id);
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Advanced search with multiple filters
  Future<List<UserModel>> advancedSearchUsers({
    required String query,
    bool? isActive,
    String? location,
    int? minAds,
    int? minBids,
    String? sortBy, // 'recent', 'ads', 'bids', 'name'
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      Query<Map<String, dynamic>> searchQuery = _firestore.collection('users');

      // Apply filters
      if (isActive != null) {
        searchQuery = searchQuery.where('isActive', isEqualTo: isActive);
      }

      if (location != null && location.isNotEmpty) {
        searchQuery = searchQuery.where('location', isGreaterThanOrEqualTo: location)
            .where('location', isLessThanOrEqualTo: '$location\uf8ff');
      }

      if (minAds != null) {
        searchQuery = searchQuery.where('totalAds', isGreaterThanOrEqualTo: minAds);
      }

      if (minBids != null) {
        searchQuery = searchQuery.where('totalBids', isGreaterThanOrEqualTo: minBids);
      }

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'recent':
            searchQuery = searchQuery.orderBy('createdAt', descending: true);
            break;
          case 'ads':
            searchQuery = searchQuery.orderBy('totalAds', descending: true);
            break;
          case 'bids':
            searchQuery = searchQuery.orderBy('totalBids', descending: true);
            break;
          case 'name':
            searchQuery = searchQuery.orderBy('fullName');
            break;
        }
      }

      final querySnapshot = await searchQuery.limit(limit).get();
      final users = <UserModel>[];

      for (final doc in querySnapshot.docs) {
        final user = UserModel.fromJson(doc.id, doc.data());
        // Filter by query text in name or username
        if (user.fullName.toLowerCase().contains(query.toLowerCase()) ||
            user.username.toLowerCase().contains(query.toLowerCase())) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to perform advanced search: $e');
    }
  }

  // Get popular/trending users
  Future<List<UserModel>> getPopularUsers({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('totalAds', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => UserModel.fromJson(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get popular users: $e');
    }
  }

  // Get recently joined users
  Future<List<UserModel>> getRecentUsers({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => UserModel.fromJson(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get recent users: $e');
    }
  }

  // Search users by location
  Future<List<UserModel>> searchUsersByLocation(String location, {int limit = 20}) async {
    try {
      if (location.trim().isEmpty) return [];

      final query = await _firestore
          .collection('users')
          .where('location', isGreaterThanOrEqualTo: location)
          .where('location', isLessThanOrEqualTo: '$location\uf8ff')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => UserModel.fromJson(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to search users by location: $e');
    }
  }

  // Deactivate user account
  Future<void> deactivateAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to deactivate account: $e');
    }
  }

  // Reactivate user account
  Future<void> reactivateAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).update({
        'isActive': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to reactivate account: $e');
    }
  }

  // Get user ad statistics
  Future<Map<String, int>> getUserAdStats(String userId) async {
    try {
      // Get total ads count
      final totalAdsQuery = await _firestore
          .collection('ads')
          .where('posted_by', isEqualTo: userId)
          .get();

      // Get active ads count (Available status)
      final activeAdsQuery = await _firestore
          .collection('ads')
          .where('posted_by', isEqualTo: userId)
          .where('status', isEqualTo: 'Available')
          .get();

      return {
        'totalAds': totalAdsQuery.docs.length,
        'activeAds': activeAdsQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get user ad stats: $e');
    }
  }

  // Get user bid statistics
  Future<Map<String, int>> getUserBidStats(String userId) async {
    try {
      // Get all bids by the user
      final userBidsQuery = await _firestore
          .collection('bids')
          .where('bidderId', isEqualTo: userId)
          .get();

      int totalBids = 0;
      int activeBids = 0; // pending bids

      for (final doc in userBidsQuery.docs) {
        totalBids++;
        final status = doc.data()['status'] as String?;
        if (status == 'pending') {
          activeBids++;
        }
      }

      return {
        'totalBids': totalBids,
        'activeBids': activeBids,
      };
    } catch (e) {
      throw Exception('Failed to get user bid stats: $e');
    }
  }

  // Get current user profile with updated statistics
  Future<UserModel?> getCurrentUserProfileWithStats() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final userModel = UserModel.fromJson(doc.id, doc.data()!);
      
      // Get updated ad statistics
      final adStats = await getUserAdStats(user.uid);
      
      // Get updated bid statistics
      final bidStats = await getUserBidStats(user.uid);
      
      // Return user model with updated stats
      return userModel.copyWith(
        totalAds: adStats['totalAds'] ?? 0,
        activeAds: adStats['activeAds'] ?? 0,
        totalBids: bidStats['totalBids'] ?? 0,
        activeBids: bidStats['activeBids'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to get user profile with stats: $e');
    }
  }

  // Update active ads count
  Future<void> updateActiveAdsCount(String userId, int activeAdsCount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'activeAds': activeAdsCount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update active ads count: $e');
    }
  }

  // Refresh user statistics by recalculating from actual ads and bids
  Future<void> refreshUserStats(String userId) async {
    try {
      final adStats = await getUserAdStats(userId);
      final bidStats = await getUserBidStats(userId);
      
      await _firestore.collection('users').doc(userId).update({
        'totalAds': adStats['totalAds'],
        'activeAds': adStats['activeAds'],
        'totalBids': bidStats['totalBids'],
        'activeBids': bidStats['activeBids'],
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to refresh user stats: $e');
    }
  }
}
