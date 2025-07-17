import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_bottom_navigation.dart';
import '../models/admin_data_models.dart';
import '../../home/models/car_model.dart';
import 'package:intl/intl.dart';

class AdminBidManagementScreen extends StatefulWidget {
  const AdminBidManagementScreen({super.key});

  @override
  State<AdminBidManagementScreen> createState() => _AdminBidManagementScreenState();
}

class _AdminBidManagementScreenState extends State<AdminBidManagementScreen> {
  final AdminDashboardController _controller = Get.find<AdminDashboardController>();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, CarModel> _carCache = {};
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBids() async {
    await _controller.loadBids(
      status: _selectedFilter == 'all' ? null : _selectedFilter,
      refresh: true,
    );
    // Pre-load car details for the loaded bids
    _preloadCarDetails();
  }
  
  Future<void> _preloadCarDetails() async {
    for (var bid in _controller.bids) {
      if (!_carCache.containsKey(bid.carId)) {
        try {
          final carDetails = await _controller.getCarById(bid.carId);
          if (carDetails != null && mounted) {
            setState(() {
              _carCache[bid.carId] = carDetails;
            });
          }
        } catch (e) {
          debugPrint('Error fetching car details for ${bid.carId}: $e');
        }
      }
    }
  }
  
  CarModel? _getCarDetails(String carId) {
    return _carCache[carId];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bid Management'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value == 'all' ? null : value;
              });
              _loadBids();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('All Bids')),
              PopupMenuItem(value: 'active', child: Text('Active Bids')),
              PopupMenuItem(value: 'withdrawn', child: Text('Withdrawn Bids')),
              PopupMenuItem(value: 'rejected', child: Text('Rejected Bids')),
              PopupMenuItem(value: 'accepted', child: Text('Accepted Bids')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBids(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by car ID, bidder email or amount',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                // Status filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('Active', 'active'),
                      _buildFilterChip('Accepted', 'accepted'),
                      _buildFilterChip('Rejected', 'rejected'),
                      _buildFilterChip('Withdrawn', 'withdrawn'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bid list
          Expanded(
            child: Obx(() {
              if (_controller.isLoadingBids && _controller.bids.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredBids = _filterBids(_controller.bids);
              
              if (filteredBids.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No bids found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
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
                onRefresh: _loadBids,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBids.length,
                  itemBuilder: (context, index) {
                    final bid = filteredBids[index];
                    return _buildBidCard(bid);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildBidCard(BidModel bid) {
    final carDetails = _getCarDetails(bid.carId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bid Header
            Row(
              children: [
                carDetails != null && carDetails.imgURLs.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          carDetails.imgURLs.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.car_rental, color: Colors.grey),
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.car_rental, color: Colors.grey),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bid Amount: \$${bid.bidAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (carDetails != null)
                        Text(
                          '${carDetails.make} ${carDetails.name} (${carDetails.year})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'Car ID: ${bid.carId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(bid.status),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Bidder Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bidder Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Email', bid.bidderEmail),
                  _buildInfoRow('Bidder ID', bid.bidderId),
                  _buildInfoRow('Bid Time', _formatDate(bid.bidTime.toDate())),
                  if (bid.isAutoGenerated)
                    _buildInfoRow('Type', 'Auto-generated', 
                        valueColor: Colors.orange),
                ],
              ),
            ),
            
            if (bid.notes != null && bid.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
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
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bid.notes!,
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                if (bid.status == 'active') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                      onPressed: () => _showUpdateBidStatusDialog(
                        bid, 
                        'accepted',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _showUpdateBidStatusDialog(
                        bid, 
                        'rejected',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showDeleteBidDialog(bid),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showBidDetailsDialog(bid),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'withdrawn':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  void _showUpdateBidStatusDialog(
    BidModel bid,
    String newStatus,
  ) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus.toUpperCase()} Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to ${newStatus.toLowerCase()} this bid of \$${bid.bidAmount.toStringAsFixed(0)}?',
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await _controller.updateBidStatus(
                  bid.id,
                  newStatus,
                  adminNotes: notesController.text.trim().isEmpty 
                      ? null 
                      : notesController.text.trim(),
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bid status updated to ${newStatus.toUpperCase()}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh the bids
                  _loadBids();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating bid status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
            ),
            child: Text(newStatus.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showDeleteBidDialog(BidModel bid) {
    final reasonController = TextEditingController();
    bool isValid = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Bid'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you sure you want to delete this bid of \$${bid.bidAmount.toStringAsFixed(0)}? This action cannot be undone.',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason for deletion (required)',
                      border: const OutlineInputBorder(),
                      errorText: reasonController.text.trim().isEmpty && !isValid
                          ? 'Reason is required'
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isValid = value.trim().isNotEmpty;
                      });
                    },
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      setState(() {
                        isValid = false;
                      });
                      return;
                    }
                    
                    Navigator.of(context).pop();
                    
                    try {
                      await _controller.deleteBid(
                        bid.id, 
                        reason: reasonController.text.trim()
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bid deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Refresh the bids
                        _loadBids();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting bid: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showBidDetailsDialog(BidModel bid) {
    final carDetails = _getCarDetails(bid.carId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bid Details - \$${bid.bidAmount.toStringAsFixed(0)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (carDetails != null) ...[
                _buildInfoRow('Car', '${carDetails.make} ${carDetails.name}'),
                _buildInfoRow('Year', carDetails.year.toString()),
                _buildInfoRow('Price', '\$${carDetails.price.toStringAsFixed(0)}'),
                const Divider(height: 24),
              ],
              _buildInfoRow('Bid ID', bid.id),
              _buildInfoRow('Car ID', bid.carId),
              _buildInfoRow('Bidder ID', bid.bidderId),
              _buildInfoRow('Bidder Email', bid.bidderEmail),
              _buildInfoRow('Bid Amount', '\$${bid.bidAmount.toStringAsFixed(0)}'),
              _buildInfoRow('Status', bid.status.toUpperCase(),
                  valueColor: _getStatusColor(bid.status)),
              _buildInfoRow('Bid Time', _formatDate(bid.bidTime.toDate())),
              _buildInfoRow('Auto-generated', bid.isAutoGenerated ? 'Yes' : 'No'),
              if (bid.notes != null && bid.notes!.isNotEmpty)
                _buildInfoRow('Notes', bid.notes!),
              if (bid.metadata != null && bid.metadata!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Metadata:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                ...bid.metadata!.entries.map((entry) =>
                    _buildInfoRow(entry.key, entry.value.toString())),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<BidModel> _filterBids(List<BidModel> bids) {
    final searchQuery = _searchController.text.trim().toLowerCase();
    
    if (searchQuery.isEmpty) {
      return bids;
    }
    
    return bids.where((bid) {
      return bid.carId.toLowerCase().contains(searchQuery) ||
          bid.bidderEmail.toLowerCase().contains(searchQuery) ||
          bid.bidAmount.toString().contains(searchQuery);
    }).toList();
  }
  
  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : null;
          });
          _loadBids();
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade700,
        side: BorderSide(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
