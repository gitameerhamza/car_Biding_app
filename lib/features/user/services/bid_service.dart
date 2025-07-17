import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bid_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class BidService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;

  // Place a bid on a car
  Future<void> placeBid({
    required String carId,
    required int bidAmount,
    required String message,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User profile not found');

      final userModel = UserModel.fromJson(userDoc.id, userDoc.data()!);

      // Check if car exists and is available for bidding
      final carDoc = await _firestore.collection('ads').doc(carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      final bool biddingEnabled = carData['bidding_enabled'] ?? false;
      
      if (!biddingEnabled) {
        throw Exception('Bidding is not enabled for this car');
      }

      final Timestamp? biddingEndDate = carData['bid_end_time'];
      if (biddingEndDate != null && biddingEndDate.toDate().isBefore(DateTime.now())) {
        throw Exception('Bidding period has ended');
      }

      final int? minBidAmount = carData['min_bid_amount'];
      if (minBidAmount != null && bidAmount < minBidAmount) {
        throw Exception('Bid amount must be at least \$${minBidAmount}');
      }

      final int? maxBidAmount = carData['max_bid_amount'];
      if (maxBidAmount != null && bidAmount > maxBidAmount) {
        throw Exception('Bid amount cannot exceed \$${maxBidAmount}');
      }

      // Check if user is not the owner of the car
      final String carOwnerId = carData['posted_by'];
      if (carOwnerId == user.uid) {
        throw Exception('You cannot bid on your own car');
      }

      // Create bid
      final bidData = BidModel(
        id: '',
        carId: carId,
        bidderId: user.uid,
        bidderName: userModel.fullName,
        bidderEmail: userModel.email,
        bidAmount: bidAmount,
        message: message,
        status: BidStatus.pending,
        createdAt: Timestamp.now(),
      );

      // Save bid to Firestore
      await _firestore.collection('bids').add(bidData.toJson());

      // Update current bid amount on the car if this is higher
      final int? currentBid = carData['current_bid'];
      if (currentBid == null || bidAmount > currentBid) {
        await _firestore.collection('ads').doc(carId).update({
          'current_bid': bidAmount,
          'last_bid_at': Timestamp.now(),
        });
      }

      // Create notification for car owner
      await _createBidNotification(carOwnerId, carId, bidAmount, userModel.fullName);

      // Refresh user bid statistics
      try {
        await _userService.refreshUserStats(user.uid);
      } catch (e) {
        // Don't fail the main operation if stats update fails
        print('Failed to update user stats: $e');
      }

    } catch (e) {
      throw Exception('Failed to place bid: $e');
    }
  }

  // Get all bids for a specific car
  Future<List<BidModel>> getBidsForCar(String carId) async {
    try {
      final query = await _firestore
          .collection('bids')
          .where('carId', isEqualTo: carId)
          .orderBy('bidAmount', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => BidModel.fromJson(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get bids for car: $e');
    }
  }

  // Get user's bids
  Stream<List<BidModel>> getUserBids() {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('bids')
          .where('bidderId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => BidModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get user bids: $e');
    }
  }

  // Get bids received on user's cars
  Stream<List<BidModel>> getBidsOnUserCars() {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('bids')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final bids = <BidModel>[];
        
        for (final doc in snapshot.docs) {
          final bid = BidModel.fromJson(doc.id, doc.data());
          
          // Check if the car belongs to the current user
          final carDoc = await _firestore.collection('ads').doc(bid.carId).get();
          if (carDoc.exists) {
            final carData = carDoc.data()!;
            if (carData['posted_by'] == user.uid) {
              bids.add(bid);
            }
          }
        }
        
        return bids;
      });
    } catch (e) {
      throw Exception('Failed to get bids on user cars: $e');
    }
  }

  // Accept a bid
  Future<void> acceptBid(String bidId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get bid details
      final bidDoc = await _firestore.collection('bids').doc(bidId).get();
      if (!bidDoc.exists) throw Exception('Bid not found');

      final bid = BidModel.fromJson(bidDoc.id, bidDoc.data()!);

      // Verify car ownership
      final carDoc = await _firestore.collection('ads').doc(bid.carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      if (carData['posted_by'] != user.uid) {
        throw Exception('You can only accept bids on your own cars');
      }

      // Update bid status
      await _firestore.collection('bids').doc(bidId).update({
        'status': BidStatus.accepted.toString(),
        'acceptedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Create notification for bidder
      await _createBidStatusNotification(bid.bidderId, bid.carId, 'accepted', bid.bidAmount);

      // Reject all other bids for this car
      final otherBidsQuery = await _firestore
          .collection('bids')
          .where('carId', isEqualTo: bid.carId)
          .where('status', isEqualTo: BidStatus.pending.toString())
          .get();

      final batch = _firestore.batch();
      for (final doc in otherBidsQuery.docs) {
        if (doc.id != bidId) {
          final otherBid = BidModel.fromJson(doc.id, doc.data());
          batch.update(doc.reference, {
            'status': BidStatus.rejected.toString(),
            'rejectedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
          
          // Create notification for rejected bidders (don't await to avoid blocking)
          _createBidStatusNotification(otherBid.bidderId, otherBid.carId, 'rejected', otherBid.bidAmount);
        }
      }
      await batch.commit();

      // Mark car as sold
      await _firestore.collection('ads').doc(bid.carId).update({
        'status': 'Sold',
      });

      // Refresh user statistics for the bidder (since bid status changed from pending to accepted)
      try {
        await _userService.refreshUserStats(bid.bidderId);
      } catch (e) {
        print('Failed to update bidder stats: $e');
      }

    } catch (e) {
      throw Exception('Failed to accept bid: $e');
    }
  }

  // Reject a bid
  Future<void> rejectBid(String bidId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get bid details
      final bidDoc = await _firestore.collection('bids').doc(bidId).get();
      if (!bidDoc.exists) throw Exception('Bid not found');

      final bid = BidModel.fromJson(bidDoc.id, bidDoc.data()!);

      // Verify car ownership
      final carDoc = await _firestore.collection('ads').doc(bid.carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      if (carData['posted_by'] != user.uid) {
        throw Exception('You can only reject bids on your own cars');
      }

      // Update bid status
      await _firestore.collection('bids').doc(bidId).update({
        'status': BidStatus.rejected.toString(),
        'rejectedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Create notification for bidder
      await _createBidStatusNotification(bid.bidderId, bid.carId, 'rejected', bid.bidAmount);

      // Refresh user statistics for the bidder (since bid status changed from pending to rejected)
      try {
        await _userService.refreshUserStats(bid.bidderId);
      } catch (e) {
        print('Failed to update bidder stats: $e');
      }

    } catch (e) {
      throw Exception('Failed to reject bid: $e');
    }
  }

  // Delete a bid (only if pending and by bidder)
  Future<void> deleteBid(String bidId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get bid details
      final bidDoc = await _firestore.collection('bids').doc(bidId).get();
      if (!bidDoc.exists) throw Exception('Bid not found');

      final bid = BidModel.fromJson(bidDoc.id, bidDoc.data()!);

      // Verify bid ownership and status
      if (bid.bidderId != user.uid) {
        throw Exception('You can only delete your own bids');
      }

      if (bid.status != BidStatus.pending) {
        throw Exception('You can only delete pending bids');
      }

      // Delete the bid
      await _firestore.collection('bids').doc(bidId).delete();

      // Update user bid statistics
      await _firestore.collection('users').doc(user.uid).update({
        'totalBids': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });

    } catch (e) {
      throw Exception('Failed to delete bid: $e');
    }
  }

  // Update an existing bid
  Future<void> updateBid({
    required String bidId,
    required int newAmount,
    required String newMessage,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get bid details to verify ownership
      final bidDoc = await _firestore.collection('bids').doc(bidId).get();
      if (!bidDoc.exists) throw Exception('Bid not found');

      final bidData = bidDoc.data()!;
      if (bidData['bidderId'] != user.uid) {
        throw Exception('You can only update your own bids');
      }

      // Check if bid is still pending
      if (bidData['status'] != BidStatus.pending.toString()) {
        throw Exception('You can only update pending bids');
      }

      // Validate the new bid amount against car constraints
      final carId = bidData['carId'];
      final carDoc = await _firestore.collection('ads').doc(carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      final int? minBidAmount = carData['min_bid_amount'];
      if (minBidAmount != null && newAmount < minBidAmount) {
        throw Exception('Bid amount must be at least \$${minBidAmount}');
      }

      final int? maxBidAmount = carData['max_bid_amount'];
      if (maxBidAmount != null && newAmount > maxBidAmount) {
        throw Exception('Bid amount cannot exceed \$${maxBidAmount}');
      }

      // Update the bid
      await _firestore.collection('bids').doc(bidId).update({
        'bidAmount': newAmount,
        'message': newMessage,
        'updatedAt': Timestamp.now(),
      });

      // Update current bid on car if this is now the highest
      final int? currentBid = carData['current_bid'];
      if (currentBid == null || newAmount > currentBid) {
        await _firestore.collection('ads').doc(carId).update({
          'current_bid': newAmount,
          'last_bid_at': Timestamp.now(),
        });
      }

    } catch (e) {
      throw Exception('Failed to update bid: $e');
    }
  }

  // Withdraw a bid
  Future<void> withdrawBid(String bidId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get bid details to verify ownership
      final bidDoc = await _firestore.collection('bids').doc(bidId).get();
      if (!bidDoc.exists) throw Exception('Bid not found');

      final bidData = bidDoc.data()!;
      if (bidData['bidderId'] != user.uid) {
        throw Exception('You can only withdraw your own bids');
      }

      // Check if bid is still pending
      if (bidData['status'] != BidStatus.pending.toString()) {
        throw Exception('You can only withdraw pending bids');
      }

      // Update bid status to withdrawn
      await _firestore.collection('bids').doc(bidId).update({
        'status': BidStatus.withdrawn.toString(),
        'withdrawnAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Refresh user bid statistics (since bid status changed from pending to withdrawn)
      try {
        await _userService.refreshUserStats(user.uid);
      } catch (e) {
        print('Failed to update user stats: $e');
      }

    } catch (e) {
      throw Exception('Failed to withdraw bid: $e');
    }
  }

  // Reactivate a withdrawn bid
  Future<void> reactivateBid(String bidId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get bid details to verify ownership
      final bidDoc = await _firestore.collection('bids').doc(bidId).get();
      if (!bidDoc.exists) throw Exception('Bid not found');

      final bidData = bidDoc.data()!;
      if (bidData['bidderId'] != user.uid) {
        throw Exception('You can only reactivate your own bids');
      }

      // Check if bid is withdrawn
      if (bidData['status'] != BidStatus.withdrawn.toString()) {
        throw Exception('You can only reactivate withdrawn bids');
      }

      // Check if car still allows bidding
      final carId = bidData['carId'];
      final carDoc = await _firestore.collection('ads').doc(carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      final bool biddingEnabled = carData['bidding_enabled'] ?? false;
      
      if (!biddingEnabled) {
        throw Exception('Bidding is no longer enabled for this car');
      }

      final Timestamp? biddingEndDate = carData['bid_end_time'];
      if (biddingEndDate != null && biddingEndDate.toDate().isBefore(DateTime.now())) {
        throw Exception('Bidding period has ended');
      }

      // Reactivate the bid
      await _firestore.collection('bids').doc(bidId).update({
        'status': BidStatus.pending.toString(),
        'reactivatedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Update user bid statistics
      await _firestore.collection('users').doc(user.uid).update({
        'totalBids': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

    } catch (e) {
      throw Exception('Failed to reactivate bid: $e');
    }
  }

  // Check if bidding period has expired and update statuses
  Future<void> updateExpiredBids() async {
    try {
      final now = Timestamp.now();
      
      // Get all cars with expired bidding
      final expiredCarsQuery = await _firestore
          .collection('ads')
          .where('bidding_enabled', isEqualTo: true)
          .where('bid_end_time', isLessThan: now)
          .get();

      final batch = _firestore.batch();

      for (final carDoc in expiredCarsQuery.docs) {
        // Get all pending bids for this car
        final pendingBidsQuery = await _firestore
            .collection('bids')
            .where('carId', isEqualTo: carDoc.id)
            .where('status', isEqualTo: BidStatus.pending.toString())
            .get();

        // Mark all pending bids as expired
        for (final bidDoc in pendingBidsQuery.docs) {
          final bidData = bidDoc.data();
          batch.update(bidDoc.reference, {
            'status': BidStatus.expired.toString(),
            'updatedAt': now,
          });
          
          // Create notification for expired bidders (don't await to avoid blocking)
          _createBidStatusNotification(
            bidData['bidderId'], 
            bidData['carId'], 
            'expired', 
            bidData['bidAmount']
          );
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update expired bids: $e');
    }
  }

  // Create notification for car owner when bid is placed
  Future<void> _createBidNotification(String ownerId, String carId, int bidAmount, String bidderName) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': ownerId,
        'type': 'new_bid',
        'title': 'New Bid Received',
        'message': '$bidderName placed a bid of \$${bidAmount} on your car',
        'carId': carId,
        'bidAmount': bidAmount,
        'bidderName': bidderName,
        'read': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      // Don't throw error for notification failure, just log it
      print('Failed to create bid notification: $e');
    }
  }

  // Create notification for bidder when bid status changes
  Future<void> _createBidStatusNotification(String bidderId, String carId, String status, int bidAmount) async {
    try {
      String title = '';
      String message = '';
      
      switch (status) {
        case 'accepted':
          title = 'Bid Accepted!';
          message = 'Congratulations! Your bid of \$${bidAmount} has been accepted.';
          break;
        case 'rejected':
          title = 'Bid Rejected';
          message = 'Your bid of \$${bidAmount} has been rejected.';
          break;
        case 'expired':
          title = 'Bid Expired';
          message = 'Your bid of \$${bidAmount} has expired.';
          break;
      }

      if (title.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'userId': bidderId,
          'type': 'bid_status',
          'title': title,
          'message': message,
          'carId': carId,
          'bidAmount': bidAmount,
          'status': status,
          'read': false,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      // Don't throw error for notification failure, just log it
      print('Failed to create bid status notification: $e');
    }
  }

  // Get bid statistics for a user
  Future<Map<String, int>> getUserBidStatistics() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userBidsQuery = await _firestore
          .collection('bids')
          .where('bidderId', isEqualTo: user.uid)
          .get();

      int totalBids = 0;
      int pendingBids = 0;
      int acceptedBids = 0;
      int rejectedBids = 0;
      int withdrawnBids = 0;
      int expiredBids = 0;

      for (final doc in userBidsQuery.docs) {
        final bid = BidModel.fromJson(doc.id, doc.data());
        totalBids++;
        
        switch (bid.status) {
          case BidStatus.pending:
            pendingBids++;
            break;
          case BidStatus.accepted:
            acceptedBids++;
            break;
          case BidStatus.rejected:
            rejectedBids++;
            break;
          case BidStatus.withdrawn:
            withdrawnBids++;
            break;
          case BidStatus.expired:
            expiredBids++;
            break;
        }
      }

      return {
        'total': totalBids,
        'pending': pendingBids,
        'accepted': acceptedBids,
        'rejected': rejectedBids,
        'withdrawn': withdrawnBids,
        'expired': expiredBids,
      };
    } catch (e) {
      throw Exception('Failed to get bid statistics: $e');
    }
  }

  // Check if user can edit a bid (additional validations)
  Future<bool> canEditBid(String bidId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final bidDoc = await _firestore.collection('bids').doc(bidId).get();
      if (!bidDoc.exists) return false;

      final bid = BidModel.fromJson(bidDoc.id, bidDoc.data()!);
      
      // Must be owner and pending
      if (bid.bidderId != user.uid || bid.status != BidStatus.pending) {
        return false;
      }

      // Check if car still allows bidding
      final carDoc = await _firestore.collection('ads').doc(bid.carId).get();
      if (!carDoc.exists) return false;

      final carData = carDoc.data()!;
      final bool biddingEnabled = carData['bidding_enabled'] ?? false;
      if (!biddingEnabled) return false;

      final Timestamp? biddingEndDate = carData['bid_end_time'];
      if (biddingEndDate != null && biddingEndDate.toDate().isBefore(DateTime.now())) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Remove all bids for a car (used when car is deleted)
  Future<void> removeAllBidsForCar(String carId) async {
    try {
      // Get all bids for this car
      final bidsQuery = await _firestore
          .collection('bids')
          .where('carId', isEqualTo: carId)
          .get();

      if (bidsQuery.docs.isEmpty) return;

      // Create batch for atomic operation
      final batch = _firestore.batch();
      final List<BidModel> bidsToRemove = [];

      // Process each bid
      for (final bidDoc in bidsQuery.docs) {
        final bid = BidModel.fromJson(bidDoc.id, bidDoc.data());
        bidsToRemove.add(bid);

        // Delete the bid
        batch.delete(bidDoc.reference);

        // Update user bid statistics for each bidder
        batch.update(
          _firestore.collection('users').doc(bid.bidderId),
          {
            'totalBids': FieldValue.increment(-1),
            'updatedAt': Timestamp.now(),
          },
        );

        // Create notification for bidder about car removal
        batch.set(
          _firestore.collection('notifications').doc(),
          {
            'userId': bid.bidderId,
            'type': 'car_removed',
            'title': 'Car Listing Removed',
            'message': 'The car you bid on has been removed by the seller. Your bid has been automatically cancelled.',
            'carId': carId,
            'bidAmount': bid.bidAmount,
            'read': false,
            'createdAt': Timestamp.now(),
          },
        );
      }

      // Execute all operations atomically
      await batch.commit();

      print('Removed ${bidsToRemove.length} bids for car $carId');

    } catch (e) {
      throw Exception('Failed to remove bids for car: $e');
    }
  }
}
