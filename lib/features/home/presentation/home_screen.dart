import 'package:cbazaar/features/home/controllers/home_controller.dart';
import 'package:cbazaar/features/home/models/event_model.dart';
import 'package:cbazaar/features/home/presentation/compare_cars_screen.dart';
import 'package:cbazaar/features/home/presentation/compare_cars_screen_enhanced.dart';
import 'package:cbazaar/features/home/presentation/comparison_widgets.dart';
import 'package:cbazaar/features/home/presentation/widgets/comparison_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../profile/presentation/car_details_screen.dart';
import '../models/car_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController(), permanent: true);
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          title: const Text('Car Bazar'),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 140, // Extra padding for comparison panel
              ),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text(
                'Events',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              height: 160,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('events').orderBy('created_at').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final data = snapshot.data!.docs.map((e) => EventModel.fromJson(e.data())).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final event = data[index];

                      return Container(
                        margin: index == 0
                            ? const EdgeInsets.symmetric(horizontal: 12.0)
                            : const EdgeInsets.only(right: 12.0),
                        padding: const EdgeInsets.all(12.0),
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13.0),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CachedNetworkImage(
                                  imageUrl: event.imgURL,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    event.name,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Date: ${event.date}',
                                  ),
                                  Text(
                                    'Vanue: ${event.location}',
                                  ),
                                  const Spacer(),
                                  Text(
                                    event.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 24.0),
              child: GetBuilder<HomeController>(
                init: HomeController(),
                builder: (_) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _.searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Search cars by name, make, city, year, condition...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        suffixIcon: _.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _.clearSearch();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (val) {
                        // Real-time search with debouncing
                        _.searchWithDebounce(val);
                      },
                      onSubmitted: (val) {
                        _.searchAds(val);
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GetBuilder<HomeController>(
                    init: HomeController(),
                    builder: (_) {
                      return Opacity(
                        opacity: _.compareModels.length < 2 ? 0.75 : 1,
                        child: InkWell(
                          onTap: _.compareModels.length < 2
                              ? null
                              : () {
                                  Get.to(() => EnhancedCompareCarsScreen(cars: _.compareModels));
                                },
                          borderRadius: BorderRadius.circular(24.0),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.0),
                              color: Colors.purple.withOpacity(_.compareModels.length < 2 ? 0.75 : 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _.compareModels.length >= 2 ? Icons.analytics : Icons.compare_arrows,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _.compareModels.length >= 2 
                                      ? 'Compare ${_.compareModels.length}'
                                      : 'Compare ${_.compareModels.length}/${_.maxCompareModels}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            GetBuilder<HomeController>(
              builder: (_) {
                if (_.searching) {
                  if (_.searchedAds.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cars found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords like car name, make, location, or year',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _.clearSearch(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Clear Search'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Search Results (${_.searchedAds.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _.clearSearch(),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _.searchedAds.length,
                        itemBuilder: (context, index) {
                          final car = _.searchedAds[index];
                          return Container(
                            margin: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                Get.to(() => CarDetailsScreen(car: car));
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: PageView.builder(
                                          itemCount: car.imgURLs.length,
                                          itemBuilder: (context, imgIndex) {
                                            return CachedNetworkImage(
                                              imageUrl: car.imgURLs[imgIndex],
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.error),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                car.name,
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${car.make} • ${car.year} • ${car.fuelType}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    car.location,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: car.status.toLowerCase() == 'available' 
                                                    ? Colors.green.shade100
                                                    : Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                car.status,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: car.status.toLowerCase() == 'available' 
                                                      ? Colors.green.shade700
                                                      : Colors.orange.shade700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '₹${car.price.toString()}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (car.currentBid != null)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.gavel,
                                              size: 16,
                                              color: Colors.blue.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Current Bid: ₹${car.currentBid}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'No bids yet',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('ads')
                      .where('posted_by', isNotEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final data = snapshot.data!.docs.map((e) => CarModel.fromJson(e.id, e.data())).toList();
                    data.sort((a, b) => a.createdAt!.toDate().isAfter(b.createdAt!.toDate()) ? 0 : 1);

                    return ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final car = data[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                          child: InkWell(
                            onTap: () {
                              Get.to(
                                () => CarDetailsScreen(car: car),
                              );
                            },
                            borderRadius: BorderRadius.circular(12.0),
                            child: Ink(
                              padding: const EdgeInsets.all(12.0),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: PageView.builder(
                                          itemCount: car.imgURLs.length,
                                          itemBuilder: (context, index) {
                                            return CachedNetworkImage(
                                              imageUrl: car.imgURLs[index],
                                              fit: BoxFit.cover,
                                            );
                                          }),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          car.name,
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text('Status: ${car.status}'),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    'Current Bid: ${car.currentBid ?? "No Bids Yet"}',
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 12.0),
                                  ComparisonButton(car: car),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            ],
            ),
            // Add the floating comparison panel
            const ComparisonFloatingPanel(),
          ],
        ),
      ),
    );
  }
}
