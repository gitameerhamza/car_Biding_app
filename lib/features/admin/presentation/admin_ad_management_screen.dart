import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_bottom_navigation.dart';
import '../../home/models/car_model.dart';
import '../models/admin_data_models.dart';

class AdminAdManagementScreen extends StatefulWidget {
  const AdminAdManagementScreen({super.key});

  @override
  State<AdminAdManagementScreen> createState() => _AdminAdManagementScreenState();
}

class _AdminAdManagementScreenState extends State<AdminAdManagementScreen> {
  final AdminDashboardController _controller = Get.find<AdminDashboardController>();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadCars();
  }
  
  Future<void> _loadCars() async {
    try {
      await _controller.loadAds(refresh: true);
    } catch (e) {
      debugPrint('Error loading cars: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Management'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          // Enhanced filtering
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter ads',
            onSelected: (value) {
              _controller.loadAds(status: value == 'all' ? null : value, refresh: true);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('All Ads')),
              PopupMenuItem(value: 'active', child: Text('Active Ads')),
              PopupMenuItem(value: 'pending', child: Text('Pending Approval')),
              PopupMenuItem(value: 'rejected', child: Text('Rejected Ads')),
              PopupMenuItem(value: 'sold', child: Text('Sold Ads')),
              PopupMenuItem(value: 'flagged', child: Text('Flagged Ads')),
              PopupMenuItem(value: 'expired', child: Text('Expired Ads')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadAds(refresh: true),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'bulk_approve':
                  _showBulkActionDialog(_controller, 'approve');
                  break;
                case 'bulk_reject':
                  _showBulkActionDialog(_controller, 'reject');
                  break;
                case 'export_ads':
                  _exportAdsList(_controller);
                  break;
                case 'analytics':
                  _showAdsAnalytics(_controller);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'bulk_approve',
                child: Row(
                  children: [
                    Icon(Icons.check_box_outlined),
                    SizedBox(width: 8),
                    Text('Bulk Approve'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bulk_reject',
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined),
                    SizedBox(width: 8),
                    Text('Bulk Reject'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined),
                    SizedBox(width: 8),
                    Text('View Analytics'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_ads',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and stats bar
          _buildSearchAndStatsBar(_controller),
          
          // Filter chips
          _buildFilterChips(_controller),
          
          // Ads list
          Expanded(
            child: Obx(() {
              if (_controller.isLoadingAds && _controller.ads.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.ads.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No ads found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _controller.loadAds(refresh: true),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.ads.length,
                  itemBuilder: (context, index) {
                    final ad = _controller.ads[index];
                    return _buildEnhancedAdCard(ad, _controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildSearchAndStatsBar(AdminDashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search ads by name, make, or location...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),
          
          const SizedBox(height: 12),
          
          // Quick stats
          Obx(() => Row(
            children: [
              _buildQuickStat(
                'Total Ads',
                controller.ads.length.toString(),
                Icons.directions_car,
                Colors.blue,
              ),
              _buildQuickStat(
                'Pending',
                controller.ads.where((ad) => ad.status == 'pending').length.toString(),
                Icons.pending,
                Colors.orange,
              ),
              _buildQuickStat(
                'Active',
                controller.ads.where((ad) => ad.status == 'active').length.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildQuickStat(
                'Flagged',
                controller.ads.where((ad) => ad.status == 'flagged').length.toString(),
                Icons.flag,
                Colors.red,
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(AdminDashboardController controller) {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Active', 'value': 'active'},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Rejected', 'value': 'rejected'},
      {'label': 'Sold', 'value': 'sold'},
      {'label': 'Flagged', 'value': 'flagged'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter['label']!),
              onSelected: (selected) {
                if (selected) {
                  controller.loadAds(
                    status: filter['value'] == 'all' ? null : filter['value'],
                    refresh: true,
                  );
                }
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: const Color(0xFF1565C0).withOpacity(0.2),
              checkmarkColor: const Color(0xFF1565C0),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedAdCard(CarModel ad, AdminDashboardController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(ad.status),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: _buildAdThumbnail(ad),
        title: Text(
          ad.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${ad.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildStatusChip(ad.status),
                if (ad.biddingEnabled)
                  _buildBiddingChip(),
                if (_isUrgentReview(ad))
                  _buildUrgentChip(),
              ],
            ),
          ],
        ),
        trailing: _buildPriorityIndicator(ad),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic ad information
                _buildAdInfoSection(ad),
                
                if (ad.biddingEnabled) ...[
                  const Divider(height: 24),
                  _buildBiddingInfoSection(ad),
                ],
                
                const Divider(height: 24),
                
                const SizedBox(height: 16),
                
                // Action buttons
                _buildActionButtons(ad, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdThumbnail(CarModel ad) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: ad.imgURLs.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(ad.imgURLs.first),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey.shade200,
      ),
      child: ad.imgURLs.isEmpty
          ? const Icon(Icons.car_rental, color: Colors.grey)
          : null,
    );
  }

  Widget _buildAdInfoSection(CarModel ad) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Make', ad.make),
                    _buildInfoRow('Year', ad.year.toString()),
                    _buildInfoRow('Condition', ad.condition),
                    _buildInfoRow('Fuel Type', ad.fuelType),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Location', ad.location),
                    _buildInfoRow('Mileage', '${ad.mileage} km'),
                    _buildInfoRow('Posted By', ad.postedBy),
                    _buildInfoRow('Contact', ad.contactNumber),
                  ],
                ),
              ),
            ],
          ),
          if (ad.createdAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Posted Date', _formatDate(ad.createdAt!.toDate())),
          ],
        ],
      ),
    );
  }

  Widget _buildBiddingInfoSection(CarModel ad) {
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bidding Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ad.currentBid != null)
                      _buildInfoRow('Current Bid', '\$${ad.currentBid!.toStringAsFixed(0)}'),
                    if (ad.minBid != null)
                      _buildInfoRow('Min Bid', '\$${ad.minBid!.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ad.maxBid != null)
                      _buildInfoRow('Max Bid', '\$${ad.maxBid!.toStringAsFixed(0)}'),
                    if (ad.biddingEndDate != null)
                      _buildInfoRow('Ends', _formatDate(ad.biddingEndDate!.toDate())),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getBidStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
  
  // Method to properly load bids for a specific car
  Future<List<BidModel>> _loadCarBids(String carId) async {
    try {
      print('Loading bids for car: $carId');
      
      // Access the bids collection directly to ensure we get all bids for this car
      final snapshot = await FirebaseFirestore.instance
          .collection('bids')
          .where('car_id', isEqualTo: carId)
          .orderBy('bid_time', descending: true)
          .get();
      
      // Convert the snapshot to BidModel objects
      final bids = snapshot.docs
          .map((doc) => BidModel.fromJson(doc.id, doc.data()))
          .toList();
      
      print('Loaded ${bids.length} bids for car $carId directly from Firestore');
      
      return bids;
    } catch (e) {
      debugPrint('Error loading bids for car $carId: $e');
      return [];
    }
  }

  Widget _buildActionButtons(CarModel ad, AdminDashboardController controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (ad.status == 'pending') ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showUpdateAdStatusDialog(
              ad,
              controller,
              'active',
              'Approve Ad',
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showUpdateAdStatusDialog(
              ad,
              controller,
              'rejected',
              'Reject Ad',
            ),
          ),
        ],
        
        if (ad.status == 'active') ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.flag, size: 16),
            label: const Text('Flag'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showUpdateAdStatusDialog(
              ad,
              controller,
              'flagged',
              'Flag Ad',
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.pause, size: 16),
            label: const Text('Suspend'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showUpdateAdStatusDialog(
              ad,
              controller,
              'suspended',
              'Suspend Ad',
            ),
          ),
        ],
        
        if (ad.status == 'flagged') ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Unflag'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showUpdateAdStatusDialog(
              ad,
              controller,
              'active',
              'Unflag Ad',
            ),
          ),
        ],
        
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever, size: 16),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _showDeleteAdDialog(ad, controller),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBiddingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gavel, size: 12, color: Colors.purple.shade700),
          const SizedBox(width: 4),
          Text(
            'BIDDING',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, size: 12, color: Colors.red.shade700),
          const SizedBox(width: 4),
          Text(
            'URGENT',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator(CarModel ad) {
    if (_isUrgentReview(ad)) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      );
    } else if (ad.status == 'pending') {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }



  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'sold':
        return Colors.blue;
      case 'flagged':
        return Colors.purple;
      case 'suspended':
        return Colors.amber;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  bool _isUrgentReview(CarModel ad) {
    if (ad.createdAt == null) return false;
    
    final daysSincePosted = DateTime.now().difference(ad.createdAt!.toDate()).inDays;
    
    // Flag as urgent if pending for more than 2 days or if high value
    return (ad.status == 'pending' && daysSincePosted > 2) || 
           (ad.price > 50000);
  }

  String _formatDate(DateTime date) {
    // Format: May 15, 2023
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
  }
  
  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  void _showUpdateAdStatusDialog(
    CarModel ad,
    AdminDashboardController controller,
    String newStatus,
    String actionName,
  ) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('$actionName Ad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to ${newStatus.toLowerCase()} "${ad.name}"?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateAdStatusEnhanced(
                ad.id,
                newStatus,
                reason: notesController.text.trim().isEmpty 
                    ? null 
                    : notesController.text.trim(),
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'active' ? Colors.green : 
                             newStatus == 'flagged' ? Colors.orange : Colors.red,
            ),
            child: Text(newStatus.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAdDialog(CarModel ad, AdminDashboardController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Ad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete "${ad.name}"? This action cannot be undone and will also delete all associated bids.',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for deletion (required)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.deleteAd(ad.id, reason: reasonController.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  void _showBulkActionDialog(AdminDashboardController controller, String action) {
    String title = action == 'approve' ? 'Bulk Approve Ads' : 'Bulk Reject Ads';
    String message = action == 'approve' 
        ? 'Are you sure you want to approve all selected ads?' 
        : 'Are you sure you want to reject all selected ads?';
    Color color = action == 'approve' ? Colors.green : Colors.red;

    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement bulk action logic
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _exportAdsList(AdminDashboardController controller) {
    // For now, show a placeholder dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Export Ads'),
        content: const Text(
          'Export functionality will be implemented in a future update.'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAdsAnalytics(AdminDashboardController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Ads Analytics'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Placeholder for analytics data
              ListTile(
                title: const Text('Total Ads'),
                trailing: Obx(() => Text(controller.ads.length.toString())),
              ),
              ListTile(
                title: const Text('Active Ads'),
                trailing: Obx(() => Text(
                  controller.ads.where((ad) => ad.status == 'active').length.toString(),
                )),
              ),
              ListTile(
                title: const Text('Pending Ads'),
                trailing: Obx(() => Text(
                  controller.ads.where((ad) => ad.status == 'pending').length.toString(),
                )),
              ),
              ListTile(
                title: const Text('Rejected Ads'),
                trailing: Obx(() => Text(
                  controller.ads.where((ad) => ad.status == 'rejected').length.toString(),
                )),
              ),
              ListTile(
                title: const Text('Sold Ads'),
                trailing: Obx(() => Text(
                  controller.ads.where((ad) => ad.status == 'sold').length.toString(),
                )),
              ),
              ListTile(
                title: const Text('Flagged Ads'),
                trailing: Obx(() => Text(
                  controller.ads.where((ad) => ad.status == 'flagged').length.toString(),
                )),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
