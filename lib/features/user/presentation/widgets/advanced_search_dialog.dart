import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_search_controller.dart';

class AdvancedSearchDialog extends StatefulWidget {
  const AdvancedSearchDialog({super.key});

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  final _queryController = TextEditingController();
  final _locationController = TextEditingController();
  final _minAdsController = TextEditingController();
  final _minBidsController = TextEditingController();
  
  bool? _isActive = true;
  String _sortBy = 'recent';

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    _minAdsController.dispose();
    _minBidsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Advanced Search',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Search Query
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Search Query',
                hintText: 'Enter name or username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Enter city or area',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Min Ads and Bids
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAdsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Ads',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _minBidsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Bids',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Active Status
            const Text(
              'User Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Radio<bool?>(
                  value: null,
                  groupValue: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const Text('All'),
                Radio<bool?>(
                  value: true,
                  groupValue: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const Text('Active'),
                Radio<bool?>(
                  value: false,
                  groupValue: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const Text('Inactive'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sort By
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'recent', child: Text('Recently Joined')),
                DropdownMenuItem(value: 'ads', child: Text('Most Ads')),
                DropdownMenuItem(value: 'bids', child: Text('Most Bids')),
                DropdownMenuItem(value: 'name', child: Text('Name')),
              ],
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _queryController.clear();
                      _locationController.clear();
                      _minAdsController.clear();
                      _minBidsController.clear();
                      setState(() {
                        _isActive = null;
                        _sortBy = 'recent';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final controller = Get.find<UserSearchController>();
                      
                      controller.advancedSearch(
                        query: _queryController.text.trim().isEmpty 
                            ? null 
                            : _queryController.text.trim(),
                        isActive: _isActive,
                        location: _locationController.text.trim().isEmpty 
                            ? null 
                            : _locationController.text.trim(),
                        minAds: _minAdsController.text.trim().isEmpty 
                            ? null 
                            : int.tryParse(_minAdsController.text.trim()),
                        minBids: _minBidsController.text.trim().isEmpty 
                            ? null 
                            : int.tryParse(_minBidsController.text.trim()),
                        sortBy: _sortBy,
                      );
                      
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
