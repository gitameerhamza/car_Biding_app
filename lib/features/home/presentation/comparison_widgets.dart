import 'package:cached_network_image/cached_network_image.dart';
import 'package:cbazaar/features/home/controllers/home_controller.dart';
import 'package:cbazaar/features/home/models/car_model.dart';
import 'package:cbazaar/features/home/presentation/compare_cars_screen_enhanced.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComparisonFloatingPanel extends StatelessWidget {
  const ComparisonFloatingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        if (controller.compareModels.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Compare Cars (${controller.compareModels.length}/${controller.maxCompareModels})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: controller.clearComparison,
                          icon: const Icon(Icons.clear_all),
                          tooltip: 'Clear all',
                        ),
                        IconButton(
                          onPressed: controller.canCompare()
                              ? () => Get.to(() => EnhancedCompareCarsScreen(cars: controller.compareModels))
                              : null,
                          icon: const Icon(Icons.analytics),
                          tooltip: 'Compare',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.compareModels.length,
                    itemBuilder: (context, index) {
                      final car = controller.compareModels[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: car.imgURLs.isNotEmpty ? car.imgURLs.first : '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.car_rental, size: 30),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => controller.removeFromComparison(car),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car.name.length > 15 
                                          ? '${car.name.substring(0, 15)}...'
                                          : car.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${NumberFormat('#,###').format(car.price)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ComparisonButton extends StatelessWidget {
  final CarModel car;
  
  const ComparisonButton({
    super.key,
    required this.car,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        final isInComparison = controller.isInComparison(car.id);
        final canAdd = controller.canAddToComparison();
        
        return Material(
          child: InkWell(
            onTap: isInComparison
                ? () => controller.removeFromComparison(car)
                : canAdd
                    ? () => controller.addToComparison(car)
                    : () {
                        Get.snackbar(
                          'Comparison Full',
                          'You can only compare up to ${controller.maxCompareModels} cars at once',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
            borderRadius: BorderRadius.circular(12.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: isInComparison 
                    ? Colors.green.withOpacity(0.8)
                    : canAdd 
                        ? Colors.purple
                        : Colors.grey.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isInComparison
                          ? Icons.check_circle
                          : Icons.compare_arrows,
                      color: Colors.white,
                      size: 16,
                      key: ValueKey(isInComparison),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isInComparison
                          ? 'In Comparison'
                          : canAdd
                              ? 'Add to Compare'
                              : 'Comparison Full',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      key: ValueKey('$isInComparison-$canAdd'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}