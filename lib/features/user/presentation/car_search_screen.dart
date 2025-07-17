import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/car_search_controller.dart';
import '../controllers/bid_controller.dart';
import '../../home/models/car_model.dart';
import '../../profile/presentation/car_details_screen.dart';

class CarSearchScreen extends StatelessWidget {
  const CarSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CarSearchController());
    final bidController = Get.put(BidController());

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: const Text('Search Cars'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context, controller),
          ),
          Obx(() => controller.carsForComparison.isNotEmpty
              ? IconButton(
                  icon: Badge(
                    label: Text(controller.carsForComparison.length.toString()),
                    child: const Icon(Icons.compare),
                  ),
                  onPressed: () => _showCompareDialog(context, controller),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.searchResults.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No cars found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try adjusting your search filters',
                        style: TextStyle(
                          fontSize: 14,
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
                itemCount: controller.searchResults.length,
                itemBuilder: (context, index) {
                  final car = controller.searchResults[index];
                  return _buildCarCard(car, controller, bidController);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CarSearchController controller) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search cars...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: (value) => controller.searchCars(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => controller.searchCars(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(CarModel car, CarSearchController controller, BidController bidController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: car.imgURLs.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: car.imgURLs.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.car_rental,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.car_rental,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    Obx(() => controller.carsForComparison.any((c) => c.id == car.id)
                        ? CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.green,
                            child: IconButton(
                              icon: const Icon(Icons.check, color: Colors.white, size: 16),
                              onPressed: () => controller.removeFromComparison(car.id),
                            ),
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.black, size: 16),
                              onPressed: () => controller.addToComparison(car),
                            ),
                          )),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.red, size: 16),
                        onPressed: () {
                          // TODO: Add to favorites functionality
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (car.status == 'sold')
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SOLD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${car.make} ${car.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${car.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCarInfoChip(Icons.calendar_today, car.year.toString()),
                    const SizedBox(width: 8),
                    _buildCarInfoChip(Icons.speed, '${car.mileage.toStringAsFixed(0)} km'),
                    const SizedBox(width: 8),
                    _buildCarInfoChip(Icons.local_gas_station, car.fuelType),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        car.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => CarDetailsScreen(car: car));
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: car.status == 'sold' || !car.biddingEnabled ? null : () {
                          if (car.biddingEndDate != null && 
                              car.biddingEndDate!.toDate().isBefore(DateTime.now())) {
                            Get.snackbar(
                              'Bidding Closed',
                              'The bidding period for this car has ended.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          bidController.showBidDialog(car);
                        },
                        icon: const Icon(Icons.gavel),
                        label: const Text('Place Bid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: car.status == 'sold' || !car.biddingEnabled ? Colors.grey : Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, CarSearchController controller) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Cars',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                const Text('Basic search filters will be available here.'),
                const SizedBox(height: 16),
                const Text('Advanced filtering features coming soon!'),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCompareDialog(BuildContext context, CarSearchController controller) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Compare Cars',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final comparisonCars = controller.carsForComparison;
                  if (comparisonCars.isEmpty) {
                    return const Center(
                      child: Text('No cars selected for comparison'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Feature')),
                        ...comparisonCars.asMap().entries.map(
                          (entry) => DataColumn(
                            label: Text('Car ${entry.key + 1}'),
                          ),
                        ),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('Make')),
                          ...comparisonCars.map(
                            (car) => DataCell(Text(car.make)),
                          ),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Model')),
                          ...comparisonCars.map(
                            (car) => DataCell(Text(car.name)),
                          ),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Year')),
                          ...comparisonCars.map(
                            (car) => DataCell(Text(car.year.toString())),
                          ),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Price')),
                          ...comparisonCars.map(
                            (car) => DataCell(Text('\$${car.price.toString()}')),
                          ),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Mileage')),
                          ...comparisonCars.map(
                            (car) => DataCell(Text('${car.mileage.toString()} km')),
                          ),
                        ]),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        controller.clearComparison();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
