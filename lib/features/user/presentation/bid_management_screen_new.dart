import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/bid_controller.dart';
import '../models/bid_model.dart';
import '../../home/models/car_model.dart';

class BidManagementScreen extends StatefulWidget {
  const BidManagementScreen({super.key});

  @override
  State<BidManagementScreen> createState() => _BidManagementScreenState();
}

class _BidManagementScreenState extends State<BidManagementScreen> {
  late final BidController controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller properly
    try {
      controller = Get.find<BidController>();
    } catch (e) {
      controller = Get.put(BidController());
    }
    
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUserBids();
      controller.loadReceivedBids();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          title: const Text('Bid Management'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Bids'),
              Tab(text: 'Received Bids'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyBidsTab(controller, context),
            _buildReceivedBidsTab(controller, context),
            _buildBidHistoryTab(controller, context),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBidsTab(BidController controller, BuildContext context) {
    return GetBuilder<BidController>(
      builder: (ctrl) {
        if (ctrl.isLoadingUserBids.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.userBids.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gavel,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No bids placed yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start bidding on cars you like!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ctrl.loadUserBids(),
          child: ListView.builder(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewPadding.bottom + 70,
            ),
            itemCount: ctrl.userBids.length,
            itemBuilder: (context, index) {
              final bid = ctrl.userBids[index];
              return _buildBidCard(bid, ctrl, isMine: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildReceivedBidsTab(BidController controller, BuildContext context) {
    return GetBuilder<BidController>(
      builder: (ctrl) {
        if (ctrl.isLoadingReceivedBids.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.receivedBids.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No bids received',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Bids on your cars will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ctrl.loadReceivedBids(),
          child: ListView.builder(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewPadding.bottom + 70,
            ),
            itemCount: ctrl.receivedBids.length,
            itemBuilder: (context, index) {
              final bid = ctrl.receivedBids[index];
              return _buildBidCard(bid, ctrl, isMine: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildBidHistoryTab(BidController controller, BuildContext context) {
    return GetBuilder<BidController>(
      builder: (ctrl) {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final allBids = [...ctrl.userBids, ...ctrl.receivedBids];
        final sortedBids = allBids
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (sortedBids.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No bid history',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewPadding.bottom + 70,
          ),
          itemCount: sortedBids.length,
          itemBuilder: (context, index) {
            final bid = sortedBids[index];
            final isMine = ctrl.userBids.contains(bid);
            return _buildBidCard(bid, ctrl, isMine: isMine, isHistory: true);
          },
        );
      },
    );
  }

  Widget _buildBidCard(BidModel bid, BidController controller, {required bool isMine, bool isHistory = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMine ? 'Bid on Car' : 'Bid from ${bid.bidderName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: _getCarName(bid.carId),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Loading car details...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBidStatusColor(bid.status.toString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getBidStatusColor(bid.status.toString())),
                  ),
                  child: Text(
                    bid.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: _getBidStatusColor(bid.status.toString()),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBidInfo('Amount', '\$${bid.bidAmount.toStringAsFixed(0)}'),
                ),
                Expanded(
                  child: _buildBidInfo('Date', DateFormat('MMM dd, yyyy').format(bid.createdAt.toDate())),
                ),
              ],
            ),
            if (bid.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bid.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            if (!isHistory && bid.status == BidStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isMine) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditBidDialog(bid, controller),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteBidDialog(bid, controller),
                        icon: const Icon(Icons.delete),
                        label: const Text('Withdraw'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.rejectBid(bid.id),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => controller.acceptBid(bid.id),
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String> _getCarName(String carId) async {
    try {
      // You can implement this to fetch car details from Firestore
      // For now, returning the car ID as a placeholder
      return 'Car ID: $carId';
    } catch (e) {
      return 'Unknown Car';
    }
  }

  Widget _buildBidInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getBidStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _showEditBidDialog(BidModel bid, BidController controller) {
    final amountController = TextEditingController(text: bid.bidAmount.toString());
    final messageController = TextEditingController(text: bid.message);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Bid'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Bid Amount',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (Optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount != null) {
                await controller.updateBid(
                  bid.id,
                  amount,
                  messageController.text,
                );
                Get.back();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBidDialog(BidModel bid, BidController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Withdraw Bid'),
        content: const Text('Are you sure you want to withdraw this bid?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.withdrawBid(bid.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}
