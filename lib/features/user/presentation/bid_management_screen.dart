import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    // Load data immediately when screen opens
    controller.loadUserBids();
    controller.loadReceivedBids();
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.loadUserBids();
                controller.loadReceivedBids();
              },
              tooltip: 'Refresh All',
            ),
          ],
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
    return Obx(() {
      if (controller.isLoadingUserBids.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.userBids.isEmpty) {
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
        onRefresh: () async => controller.loadUserBids(),
        child: Column(
          children: [
            _buildBidStatsCard(controller),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 0.0,
                  bottom: MediaQuery.of(context).viewPadding.bottom + 70,
                ),
                itemCount: controller.userBids.length,
                itemBuilder: (context, index) {
                  final bid = controller.userBids[index];
                  return _buildBidCard(bid, controller, isMine: true);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

Widget _buildReceivedBidsTab(BidController controller, BuildContext context) {
  return Obx(() {
    if (controller.isLoadingReceivedBids.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.receivedBids.isEmpty) {
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
      onRefresh: () async => controller.loadReceivedBids(),
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewPadding.bottom + 70,
        ),
        itemCount: controller.receivedBids.length,
        itemBuilder: (context, index) {
          final bid = controller.receivedBids[index];
          return _buildBidCard(bid, controller, isMine: false);
        },
      ),
    );
  });
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

Widget _buildBidCard(BidModel bid, BidController controller,
    {required bool isMine, bool isHistory = false}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16.0),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check car status and show indicators
          FutureBuilder<Map<String, dynamic>?>(
            future: _getCarStatus(bid.carId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final carData = snapshot.data!;
                if (carData['exists'] == false) {
                  return _buildCarDeletedIndicator();
                } else if (carData['status'] == 'Sold') {
                  return _buildCarSoldIndicator();
                }
              }
              return const SizedBox.shrink();
            },
          ),
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
              _buildBidStatusChip(bid.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBidInfo(
                    'Amount', '\$${bid.bidAmount.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _buildBidInfo('Date',
                    DateFormat('MMM dd, yyyy').format(bid.createdAt.toDate())),
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
            FutureBuilder<Map<String, dynamic>?>(
              future: _getCarStatus(bid.carId),
              builder: (context, snapshot) {
                // Check if car still exists and is available
                final carExists = snapshot.data?['exists'] == true;
                final carStatus = snapshot.data?['status'] ?? '';
                final isCarSold = carStatus == 'Sold';

                if (!carExists || isCarSold) {
                  // Don't show action buttons if car is deleted or sold
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !carExists
                              ? Icons.delete_outline
                              : Icons.sell_outlined,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          !carExists
                              ? 'Car listing has been removed'
                              : 'Car has been sold',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show normal action buttons if car is still available
                return Row(
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
                          onPressed: () =>
                              _showWithdrawBidDialog(bid, controller),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Withdraw'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
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
                );
              },
            ),
          ] else if (!isHistory &&
              bid.status == BidStatus.withdrawn &&
              isMine) ...[
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>?>(
              future: _getCarStatus(bid.carId),
              builder: (context, snapshot) {
                // Check if car still exists and is available for reactivation
                final carExists = snapshot.data?['exists'] == true;
                final carStatus = snapshot.data?['status'] ?? '';
                final isCarSold = carStatus == 'Sold';

                if (!carExists || isCarSold) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          !carExists
                              ? 'Cannot reactivate - car listing removed'
                              : 'Cannot reactivate - car has been sold',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReactivateBidDialog(bid, controller),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reactivate Bid'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ], // Action buttons are handled above with car status check
        ],
      ),
    ),
  );
}

Widget _buildBidStatusChip(BidStatus status) {
  String label;
  Color backgroundColor;
  Color textColor;
  IconData icon;

  switch (status) {
    case BidStatus.pending:
      label = 'Pending';
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      icon = Icons.schedule;
      break;
    case BidStatus.accepted:
      label = 'Accepted';
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle;
      break;
    case BidStatus.rejected:
      label = 'Rejected';
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      icon = Icons.cancel;
      break;
    case BidStatus.withdrawn:
      label = 'Withdrawn';
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade800;
      icon = Icons.remove_circle;
      break;
    case BidStatus.expired:
      label = 'Expired';
      backgroundColor = Colors.purple.shade100;
      textColor = Colors.purple.shade800;
      icon = Icons.access_time;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

Future<String> _getCarName(String carId) async {
  try {
    // Import the car service to fetch car details
    final carService = Get.find<BidController>().currentCar.value;
    if (carService != null && carService.id == carId) {
      return '${carService.make} ${carService.name}';
    }

    // If not in current car, fetch from Firestore
    final doc =
        await FirebaseFirestore.instance.collection('ads').doc(carId).get();
    if (doc.exists) {
      final data = doc.data()!;
      return '${data['make'] ?? ''} ${data['name'] ?? ''}'.trim();
    }
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

Widget _buildBidStatsCard(BidController controller) {
  return FutureBuilder<Map<String, int>>(
    future: controller.getBidStatistics(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Container(
          height: 100,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final stats = snapshot.data!;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Your Bidding Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child:
                        _buildStatItem('Total', stats['total']!, Colors.blue)),
                Expanded(
                    child: _buildStatItem(
                        'Pending', stats['pending']!, Colors.orange)),
                Expanded(
                    child: _buildStatItem(
                        'Won', stats['accepted']!, Colors.green)),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildStatItem(String label, int value, Color color) {
  return Column(
    children: [
      Text(
        value.toString(),
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    ],
  );
}

void _showEditBidDialog(BidModel bid, BidController controller) {
  final amountController =
      TextEditingController(text: bid.bidAmount.toString());
  final messageController = TextEditingController(text: bid.message);

  Get.dialog(
    AlertDialog(
      title: const Text('Edit Bid'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current bid: \$${bid.bidAmount}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'New Bid Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                border: OutlineInputBorder(),
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
            if (amount == null) {
              Get.snackbar(
                'Invalid Amount',
                'Please enter a valid bid amount',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }

            if (amount <= 0) {
              Get.snackbar(
                'Invalid Amount',
                'Bid amount must be greater than zero',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }

            await controller.updateBidWithValidation(
              bidId: bid.id,
              newAmount: amount,
              newMessage: messageController.text,
            );
            Get.back();
          },
          child: const Text('Update Bid'),
        ),
      ],
    ),
  );
}

void _showWithdrawBidDialog(BidModel bid, BidController controller) {
  Get.dialog(
    AlertDialog(
      title: const Text('Withdraw Bid'),
      content: const Text(
          'Are you sure you want to withdraw this bid? You can reactivate it later if the bidding period is still active.'),
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
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Withdraw'),
        ),
      ],
    ),
  );
}

void _showReactivateBidDialog(BidModel bid, BidController controller) {
  Get.dialog(
    AlertDialog(
      title: const Text('Reactivate Bid'),
      content: const Text(
          'Do you want to reactivate this bid? It will become active again and visible to the car owner.'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await controller.reactivateBid(bid.id);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reactivate'),
        ),
      ],
    ),
  );
}

Future<Map<String, dynamic>?> _getCarStatus(String carId) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection('ads').doc(carId).get();
    if (!doc.exists) {
      return {'exists': false};
    }
    final data = doc.data()!;
    return {
      'exists': true,
      'status': data['status'] ?? 'Available',
      'make': data['make'] ?? '',
      'name': data['name'] ?? '',
    };
  } catch (e) {
    return null;
  }
}

Widget _buildCarDeletedIndicator() {
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'This car listing has been removed by the seller',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCarSoldIndicator() {
  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.sell_outlined, color: Colors.orange.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'This car has been sold',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}
