import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bid_model.dart';
import '../models/user_model.dart';
import '../services/bid_service.dart';
import '../services/user_service.dart';
import '../../home/models/car_model.dart';
import '../services/car_service.dart';

class BidController extends GetxController {
  final BidService _bidService = BidService();
  final UserService _userService = UserService();
  final CarService _carService = CarService();

  // Form controllers
  final TextEditingController bidAmountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // Observable variables
  final RxList<BidModel> userBids = <BidModel>[].obs;
  final RxList<BidModel> receivedBids = <BidModel>[].obs;
  final RxList<BidModel> carBids = <BidModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingUserBids = false.obs;
  final RxBool isLoadingReceivedBids = false.obs;
  final RxBool isPlacingBid = false.obs;
  final RxBool isProcessingBid = false.obs;

  // Current car details for bidding
  final Rx<CarModel?> currentCar = Rx<CarModel?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
    loadUserBids();
    loadReceivedBids();
  }

  @override
  void onClose() {
    bidAmountController.dispose();
    messageController.dispose();
    super.onClose();
  }

  // Load current user
  Future<void> loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserProfile();
      currentUser.value = user;
    } catch (e) {
      _showErrorSnackbar('Failed to load user profile: ${e.toString()}');
    }
  }

  // Load user's bids
  void loadUserBids() {
    try {
      isLoadingUserBids.value = true;
      _bidService.getUserBids().listen((bids) {
        userBids.assignAll(bids);
        isLoadingUserBids.value = false;
      }, onError: (e) {
        isLoadingUserBids.value = false;
        _showErrorSnackbar('Failed to load your bids: ${e.toString()}');
      });
    } catch (e) {
      isLoadingUserBids.value = false;
      _showErrorSnackbar('Failed to load your bids: ${e.toString()}');
    }
  }

  // Load bids received on user's cars
  void loadReceivedBids() {
    try {
      isLoadingReceivedBids.value = true;
      _bidService.getBidsOnUserCars().listen((bids) {
        receivedBids.assignAll(bids);
        isLoadingReceivedBids.value = false;
      }, onError: (e) {
        isLoadingReceivedBids.value = false;
        _showErrorSnackbar('Failed to load received bids: ${e.toString()}');
      });
    } catch (e) {
      isLoadingReceivedBids.value = false;
      _showErrorSnackbar('Failed to load received bids: ${e.toString()}');
    }
  }

  // Load bids for a specific car
  Future<void> loadBidsForCar(String carId) async {
    try {
      isLoading.value = true;
      
      // Load car details
      final car = await _carService.getCarById(carId);
      currentCar.value = car;
      
      // Load bids for this car
      final bids = await _bidService.getBidsForCar(carId);
      carBids.assignAll(bids);
      
    } catch (e) {
      _showErrorSnackbar('Failed to load bids: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Place a bid
  Future<void> placeBid(String carId) async {
    try {
      print('=== PLACE BID DEBUG ===');
      print('Car ID: $carId');
      print('Bid Amount Text: "${bidAmountController.text}"');
      print('Message Text: "${messageController.text}"');
      
      if (!_validateBidInputs()) {
        print('Validation failed');
        return;
      }

      isPlacingBid.value = true;

      final bidAmount = int.tryParse(bidAmountController.text.trim());
      if (bidAmount == null) {
        print('ERROR: Invalid bid amount - cannot parse as integer');
        _showErrorSnackbar('Please enter a valid bid amount');
        return;
      }
      
      print('Parsed bid amount: $bidAmount');
      print('Calling bid service...');

      await _bidService.placeBid(
        carId: carId,
        bidAmount: bidAmount,
        message: messageController.text.trim(),
      );

      print('Bid placed successfully');

      // Clear form
      bidAmountController.clear();
      messageController.clear();

      // Reload bids for the car to show updated data
      await loadBidsForCar(carId);
      
      // Refresh user bids to show the new bid
      loadUserBids();
      
      _showSuccessSnackbar('Bid placed successfully');
      Get.back(); // Close bid dialog/screen
      print('======================');

    } catch (e) {
      print('ERROR placing bid: $e');
      print('Error type: ${e.runtimeType}');
      _showErrorSnackbar('Failed to place bid: ${e.toString()}');
    } finally {
      isPlacingBid.value = false;
    }
  }

  // Accept a bid
  Future<void> acceptBid(String bidId) async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Accept Bid'),
          content: const Text(
            'Are you sure you want to accept this bid? This will mark your car as sold and reject all other bids.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isProcessingBid.value = true;
      await _bidService.acceptBid(bidId);
      
      _showSuccessSnackbar('Bid accepted successfully');
      
      // Refresh all bid data
      loadReceivedBids();
      loadUserBids();
      
      // Close the dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      
    } catch (e) {
      _showErrorSnackbar('Failed to accept bid: ${e.toString()}');
    } finally {
      isProcessingBid.value = false;
    }
  }

  // Reject a bid
  Future<void> rejectBid(String bidId) async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Reject Bid'),
          content: const Text('Are you sure you want to reject this bid?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isProcessingBid.value = true;
      await _bidService.rejectBid(bidId);
      
      _showSuccessSnackbar('Bid rejected');
      
      // Refresh all bid data
      loadReceivedBids();
      loadUserBids();
      
    } catch (e) {
      _showErrorSnackbar('Failed to reject bid: ${e.toString()}');
    } finally {
      isProcessingBid.value = false;
    }
  }

  // Delete a bid (only if pending and by bidder)
  Future<void> deleteBid(String bidId) async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Bid'),
          content: const Text('Are you sure you want to delete this bid?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      isProcessingBid.value = true;
      await _bidService.deleteBid(bidId);
      
      _showSuccessSnackbar('Bid deleted');
      
      // Refresh user bids
      loadUserBids();
      
    } catch (e) {
      _showErrorSnackbar('Failed to delete bid: ${e.toString()}');
    } finally {
      isProcessingBid.value = false;
    }
  }

  // Update an existing bid
  Future<void> updateBid(String bidId, int newAmount, String newMessage) async {
    try {
      isProcessingBid.value = true;
      
      await _bidService.updateBid(
        bidId: bidId,
        newAmount: newAmount,
        newMessage: newMessage,
      );
      
      // Refresh data
      loadUserBids();
      loadReceivedBids();
      
      _showSuccessSnackbar('Bid updated successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to update bid: ${e.toString()}');
    } finally {
      isProcessingBid.value = false;
    }
  }

  // Enhanced bid update with car constraint validation
  Future<void> updateBidWithValidation({
    required String bidId,
    required int newAmount,
    required String newMessage,
  }) async {
    try {
      isProcessingBid.value = true;

      // Check if bid can be edited
      final canEdit = await _bidService.canEditBid(bidId);
      if (!canEdit) {
        throw Exception('This bid can no longer be edited');
      }
      
      await _bidService.updateBid(
        bidId: bidId,
        newAmount: newAmount,
        newMessage: newMessage,
      );
      
      // Refresh data
      loadUserBids();
      loadReceivedBids();
      
      _showSuccessSnackbar('Bid updated successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to update bid: ${e.toString()}');
    } finally {
      isProcessingBid.value = false;
    }
  }

  // Withdraw a bid
  Future<void> withdrawBid(String bidId) async {
    try {
      isProcessingBid.value = true;
      
      await _bidService.withdrawBid(bidId);
      
      // Refresh data
      loadUserBids();
      loadReceivedBids();
      
      _showSuccessSnackbar('Bid withdrawn successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to withdraw bid: ${e.toString()}');
    } finally {
      isProcessingBid.value = false;
    }
  }

  // Reactivate a withdrawn bid
  Future<void> reactivateBid(String bidId) async {
    try {
      isProcessingBid.value = true;
      
      await _bidService.reactivateBid(bidId);
      
      // Refresh data
      loadUserBids();
      loadReceivedBids();
      
      _showSuccessSnackbar('Bid reactivated successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to reactivate bid: ${e.toString()}');
    } finally {
      isProcessingBid.value = false;
    }
  }

  // Show bid dialog
  void showBidDialog(CarModel car) {
    currentCar.value = car;
    
    // Enhanced debugging and validation
    print('=== BID DIALOG DEBUG ===');
    print('Car ID: ${car.id}');
    print('Car Name: ${car.name}');
    print('Bidding Enabled: ${car.biddingEnabled}');
    print('Car Status: ${car.status}');
    print('Car Owner: ${car.postedBy}');
    print('Current User: ${FirebaseAuth.instance.currentUser?.uid}');
    print('Current Bid: ${car.currentBid}');
    print('Min Bid: ${car.minBid}');
    print('Max Bid: ${car.maxBid}');
    
    if (car.biddingEndDate != null) {
      final endDate = car.biddingEndDate!.toDate();
      final isExpired = endDate.isBefore(DateTime.now());
      print('Bidding End Date: $endDate');
      print('Is Expired: $isExpired');
    } else {
      print('Bidding End Date: Not set');
    }
    print('========================');
    
    // Check if bidding is still available
    if (car.biddingEndDate != null && car.biddingEndDate!.toDate().isBefore(DateTime.now())) {
      _showErrorSnackbar('Bidding period has ended for this car');
      return;
    }

    if (!car.biddingEnabled) {
      _showErrorSnackbar('Bidding is not enabled for this car');
      return;
    }
    
    // Check if user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackbar('Please log in to place a bid');
      return;
    }
    
    // Check if user is trying to bid on their own car
    if (car.postedBy == currentUser.uid) {
      _showErrorSnackbar('You cannot bid on your own car');
      return;
    }
    
    // Set suggested bid amount (slightly above current bid)
    if (car.currentBid != null) {
      bidAmountController.text = (car.currentBid! + 1000).toString();
    } else if (car.minBid != null) {
      bidAmountController.text = car.minBid.toString();
    }

    Get.dialog(
      AlertDialog(
        title: Text('Place Bid on ${car.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${car.make} ${car.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Price: \$${car.price}'),
                    Text('Location: ${car.location}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Bidding information
              if (car.currentBid != null)
                Text(
                  'Current Highest Bid: \$${car.currentBid!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                ),
              if (car.minBid != null)
                Text('Minimum Bid: \$${car.minBid!.toStringAsFixed(0)}'),
              if (car.maxBid != null)
                Text('Maximum Bid: \$${car.maxBid!.toStringAsFixed(0)}'),
              if (car.biddingEndDate != null)
                Text(
                  'Bidding Ends: ${_formatDate(car.biddingEndDate!.toDate())}',
                  style: TextStyle(
                    color: car.biddingEndDate!.toDate().difference(DateTime.now()).inHours < 24 
                      ? Colors.red 
                      : Colors.orange
                  ),
                ),
              const SizedBox(height: 16),
              
              // Bid amount input
              TextField(
                controller: bidAmountController,
                decoration: InputDecoration(
                  labelText: 'Your Bid Amount (\$)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  helperText: car.currentBid != null 
                    ? 'Must be higher than \$${car.currentBid}'
                    : car.minBid != null 
                      ? 'Must be at least \$${car.minBid}'
                      : null,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Message input
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  helperText: 'Add a personal message to the seller',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              bidAmountController.clear();
              messageController.clear();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton.icon(
            onPressed: isPlacingBid.value ? null : () => placeBid(car.id),
            icon: isPlacingBid.value 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Icon(Icons.gavel),
            label: Text(isPlacingBid.value ? 'Placing...' : 'Place Bid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          )),
        ],
      ),
    );
  }

  // Get bid statistics
  Future<Map<String, int>> getBidStatistics() async {
    try {
      return await _bidService.getUserBidStatistics();
    } catch (e) {
      _showErrorSnackbar('Failed to load bid statistics: ${e.toString()}');
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'withdrawn': 0,
        'expired': 0,
      };
    }
  }

  // Get received bid statistics
  Map<String, int> getReceivedBidStatistics() {
    int pendingBids = receivedBids.where((bid) => bid.status == BidStatus.pending).length;
    int acceptedBids = receivedBids.where((bid) => bid.status == BidStatus.accepted).length;
    int rejectedBids = receivedBids.where((bid) => bid.status == BidStatus.rejected).length;
    int expiredBids = receivedBids.where((bid) => bid.status == BidStatus.expired).length;

    return {
      'pending': pendingBids,
      'accepted': acceptedBids,
      'rejected': rejectedBids,
      'expired': expiredBids,
      'total': receivedBids.length,
    };
  }

  // Validate bid inputs
  bool _validateBidInputs() {
    print('=== BID VALIDATION DEBUG ===');
    print('Bid amount text: "${bidAmountController.text.trim()}"');
    
    if (bidAmountController.text.trim().isEmpty) {
      print('ERROR: Bid amount is empty');
      _showErrorSnackbar('Please enter a bid amount');
      return false;
    }

    final bidAmount = int.tryParse(bidAmountController.text.trim());
    if (bidAmount == null || bidAmount <= 0) {
      print('ERROR: Invalid bid amount: $bidAmount');
      _showErrorSnackbar('Please enter a valid bid amount');
      return false;
    }
    
    print('Parsed bid amount: $bidAmount');
    print('Current car: ${currentCar.value?.name}');
    print('Min bid: ${currentCar.value?.minBid}');
    print('Max bid: ${currentCar.value?.maxBid}');
    print('Current bid: ${currentCar.value?.currentBid}');

    if (currentCar.value?.minBid != null && bidAmount < currentCar.value!.minBid!) {
      print('ERROR: Bid below minimum');
      _showErrorSnackbar('Bid amount must be at least \$${currentCar.value!.minBid}');
      return false;
    }

    if (currentCar.value?.maxBid != null && bidAmount > currentCar.value!.maxBid!) {
      print('ERROR: Bid above maximum');
      _showErrorSnackbar('Bid amount cannot exceed \$${currentCar.value!.maxBid}');
      return false;
    }

    if (currentCar.value?.currentBid != null && bidAmount <= currentCar.value!.currentBid!) {
      print('ERROR: Bid not higher than current');
      _showErrorSnackbar('Bid amount must be higher than current bid of \$${currentCar.value!.currentBid}');
      return false;
    }

    print('Validation passed');
    print('============================');
    return true;
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper methods
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  // Handle car deletion from bid perspective (refresh user bids)
  void handleCarDeleted(String carId) {
    try {
      // Remove bids for deleted car from local lists
      userBids.removeWhere((bid) => bid.carId == carId);
      receivedBids.removeWhere((bid) => bid.carId == carId);
      carBids.removeWhere((bid) => bid.carId == carId);
      
      // Show notification to user
      _showInfoSnackbar('Some bids have been removed because the car listing was deleted');
      
      // Refresh data from server to ensure consistency
      loadUserBids();
      loadReceivedBids();
      
    } catch (e) {
      print('Error handling car deletion: $e');
    }
  }

  // Handle car sold status (mark bids as expired)
  void handleCarSold(String carId) {
    try {
      // Update local bid statuses
      for (int i = 0; i < userBids.length; i++) {
        if (userBids[i].carId == carId && userBids[i].status == BidStatus.pending) {
          userBids[i] = userBids[i].copyWith(status: BidStatus.expired);
        }
      }
      
      for (int i = 0; i < receivedBids.length; i++) {
        if (receivedBids[i].carId == carId && receivedBids[i].status == BidStatus.pending) {
          receivedBids[i] = receivedBids[i].copyWith(status: BidStatus.expired);
        }
      }
      
      // Show notification to user
      _showInfoSnackbar('Pending bids have been marked as expired because the car was sold');
      
      // Refresh data from server
      loadUserBids();
      loadReceivedBids();
      
    } catch (e) {
      print('Error handling car sold: $e');
    }
  }

  // Show info snackbar
  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'Information',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade900,
      duration: const Duration(seconds: 4),
    );
  }
}
