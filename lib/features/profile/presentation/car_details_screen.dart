import 'package:cached_network_image/cached_network_image.dart';
import 'package:cbazaar/features/home/models/car_model.dart';
import 'package:cbazaar/features/user/controllers/chat_controller.dart';
import 'package:cbazaar/features/user/controllers/bid_controller.dart';
import 'package:cbazaar/features/user/models/bid_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CarDetailsScreen extends StatefulWidget {
  final CarModel car;
  const CarDetailsScreen({super.key, required this.car});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  late final BidController bidController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the controller properly - try to find existing first, then put if not found
    try {
      bidController = Get.find<BidController>();
    } catch (e) {
      bidController = Get.put(BidController());
    }
    // Load bids for this car when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bidController.loadBidsForCar(widget.car.id);
    });
  }

  void _showBidsDialog() {
    Get.dialog(
      Dialog(
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bids on Your Car',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: GetBuilder<BidController>(
                  builder: (controller) {
                    if (controller.carBids.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No bids received yet'),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: controller.carBids.length,
                      itemBuilder: (context, index) {
                        final bid = controller.carBids[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getBidStatusColor(bid.status),
                              child: Text(
                                '\$${(bid.bidAmount / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${bid.bidderName} - \$${bid.bidAmount}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bid.message.isNotEmpty ? bid.message : 'No message'),
                                Text(
                                  'Status: ${bid.status.toString().toUpperCase()}',
                                  style: TextStyle(
                                    color: _getBidStatusColor(bid.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: bid.status == BidStatus.pending 
                              ? PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      onTap: () => controller.acceptBid(bid.id),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Accept'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: () => controller.rejectBid(bid.id),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.close, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Reject'),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBidStatusColor(BidStatus status) {
    switch (status) {
      case BidStatus.pending:
        return Colors.orange;
      case BidStatus.accepted:
        return Colors.green;
      case BidStatus.rejected:
        return Colors.red;
      case BidStatus.expired:
        return Colors.grey;
      case BidStatus.withdrawn:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  void _showFullScreenGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: widget.car.imgURLs.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: 'car_image_${widget.car.id}_$index',
                    child: CachedNetworkImage(
                      imageUrl: widget.car.imgURLs[index],
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: const Text('Car Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: PageView.builder(
                        itemCount: widget.car.imgURLs.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenGallery(context, index),
                            child: Hero(
                              tag: 'car_image_${widget.car.id}_$index',
                              child: CachedNetworkImage(
                                imageUrl: widget.car.imgURLs[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Image counter indicator
                    if (widget.car.imgURLs.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1}/${widget.car.imgURLs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.car.imgURLs.length > 1)
                Container(
                  height: 60,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.car.imgURLs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentImageIndex == index 
                                ? Colors.blue 
                                : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: widget.car.imgURLs[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24.0),
          Text(
            widget.car.name,
            style: const TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.car.descripton,
            style: const TextStyle(fontSize: 18.0),
          ),
          const Divider(height: 36.0),
          Text(
            'Price: \$${widget.car.price}',
            style: const TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Condition: ${widget.car.condition}',
            style: const TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Location: ${widget.car.location}',
            style: const TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Contact: ${widget.car.contactNumber}',
            style: const TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Fuel Type: ${widget.car.fuelType}',
            style: const TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Year: ${widget.car.year}',
            style: const TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Mileage: ${widget.car.mileage}',
            style: const TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 24.0),
          if (widget.car.biddingEnabled)
            GetBuilder<BidController>(
              builder: (controller) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  const SizedBox(height: 24.0),
                  const Text(
                    "Bidding",
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Min Bid: \$${widget.car.minBid ?? 'Not set'}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Max Bid: \$${widget.car.maxBid ?? 'Not set'}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Current Highest Bid: \$${widget.car.currentBid ?? 'No bids yet'}',
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Bidding Ends On: ${widget.car.biddingEndDate?.toDate().toString().split(' ')[0] ?? 'Not set'}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Show bid statistics for car owner
                  if (widget.car.postedBy == FirebaseAuth.instance.currentUser!.uid) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bid Summary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        GetBuilder<BidController>(
                          builder: (ctrl) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Bids: ${ctrl.carBids.length}'),
                              if (ctrl.carBids.isNotEmpty) ...[
                                Text('Highest Bid: \$${ctrl.carBids.first.bidAmount}'),
                                Text('Latest Bidder: ${ctrl.carBids.first.bidderName}'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GetBuilder<BidController>(
                    builder: (ctrl) => ElevatedButton.icon(
                      onPressed: () => _showBidsDialog(),
                      icon: const Icon(Icons.list),
                      label: Text('View All Bids (${ctrl.carBids.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                
                // Show bid placement for non-owners
                if (widget.car.postedBy != FirebaseAuth.instance.currentUser!.uid) ...[
                  if (widget.car.biddingEndDate != null && 
                      widget.car.biddingEndDate!.toDate().isBefore(DateTime.now()))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.timer_off, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Bidding period has ended',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => controller.showBidDialog(widget.car),
                      icon: const Icon(Icons.gavel),
                      label: const Text('Place Bid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                ],
              ],
            ))
          else
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade200,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                  ),
                  SizedBox(width: 4.0),
                  Text('Bidding is not available for this car'),
                ],
              ),
            ),
          const SizedBox(height: 24.0),
          if (widget.car.postedBy != FirebaseAuth.instance.currentUser!.uid)
            Material(
              child: InkWell(
                onTap: () {
                  launchUrlString('tel://${widget.car.contactNumber}');
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.purple,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Chat with seller button for non-owners
          if (widget.car.postedBy != FirebaseAuth.instance.currentUser!.uid)
            Column(
              children: [
                const Divider(),
                const SizedBox(height: 24.0),
                Material(
                  child: InkWell(
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // Import the controller
                        final chatController = Get.put(ChatController());
                        final chatId = await chatController.createOrGetChat(
                          carId: widget.car.id,
                          sellerId: widget.car.postedBy,
                          carTitle: '${widget.car.make} ${widget.car.name}',
                        );
                        
                        if (chatId != null) {
                          Get.toNamed('/user/chat/$chatId/Seller');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.blue,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'Chat with Seller',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
              ],
            ),
          if (widget.car.postedBy == FirebaseAuth.instance.currentUser!.uid)
            Column(
              children: [
                const Divider(),
                const SizedBox(height: 24.0),
                Material(
                  child: InkWell(
                    onTap: () {
                      Get.dialog(
                        Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          backgroundColor: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 20.0),
                                ),
                                const Text('Do you really want to delete this ad?'),
                                const SizedBox(height: 16.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        borderRadius: BorderRadius.circular(12.0),
                                        child: Ink(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.0),
                                            color: Colors.grey,
                                          ),
                                          child: const Text(
                                            'No',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          try {
                                            // Show loading indicator
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => const Center(child: CircularProgressIndicator()),
                                            );
                                            
                                            // Delete images from Firebase Storage
                                            final storage = FirebaseStorage.instance;
                                            for (final imageUrl in widget.car.imgURLs) {
                                              try {
                                                final ref = storage.refFromURL(imageUrl);
                                                await ref.delete();
                                              } catch (e) {
                                                print('Error deleting image: $e');
                                                // Continue with other deletions even if this one fails
                                              }
                                            }
                                            
                                            // Delete the ad document from Firestore
                                            await FirebaseFirestore.instance.collection('ads').doc(widget.car.id).delete();
                                            
                                            // Close loading dialog
                                            Navigator.pop(context);
                                            // Close confirmation dialog
                                            Navigator.pop(context);
                                            // Return to previous screen
                                            Navigator.pop(context);
                                          } catch (e) {
                                            // Close loading dialog
                                            Navigator.pop(context);
                                            // Show error message
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: Colors.red,
                                                content: Text('Error deleting car listing: ${e.toString()}'),
                                              ),
                                            );
                                          }
                                        },
                                        child: Ink(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.0),
                                            color: Colors.red,
                                          ),
                                          child: const Text(
                                            'Yes',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.red,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(
            height: MediaQuery.of(context).viewPadding.bottom + 12.0,
          ),
        ],
      ),
    );
  }
}
