import 'package:cached_network_image/cached_network_image.dart';
import 'package:cbazaar/features/home/models/car_model.dart';
import 'package:cbazaar/features/profile/presentation/car_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class YourCarsScreen extends StatelessWidget {
  const YourCarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: const Text('Your Cars'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ads')
            .where('posted_by', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          final data = snapshot.data!.docs.map((e) => CarModel.fromJson(e.id, e.data())).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            shrinkWrap: true,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final car = data[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
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
                        if (car.biddingEnabled)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.0),
                                color: Colors.amber.shade200,
                              ),
                              child: const Text(
                                'Bidding Available',
                              ),
                            ),
                          ),
                        Text(
                          'Current Bid: ${car.currentBid ?? "No Bids Yet"}',
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
