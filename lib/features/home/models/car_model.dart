import 'package:cloud_firestore/cloud_firestore.dart';

class CarModel {
  final String id, descripton, name, contactNumber, location, postedBy, status, condition, fuelType, make;
  final List<String> imgURLs;
  final int price, year, mileage;
  final int? currentBid, minBid, maxBid;
  final Timestamp? createdAt, biddingEndDate;
  final bool biddingEnabled;

  const CarModel({
    required this.id,
    required this.name,
    required this.descripton,
    required this.condition,
    required this.contactNumber,
    required this.currentBid,
    required this.imgURLs,
    required this.location,
    required this.postedBy,
    required this.price,
    required this.status,
    required this.make,
    required this.fuelType,
    required this.mileage,
    required this.year,
    required this.createdAt,
    required this.maxBid,
    required this.minBid,
    required this.biddingEndDate,
    required this.biddingEnabled,
  });

  factory CarModel.fromJson(String docID, Map<String, dynamic> json) {
    return CarModel(
      id: docID,
      name: json["car_name"] ?? 'Unknown Car',
      descripton: json["car_description"] ?? 'No description available',
      condition: json["car_condition"] ?? 'Unknown',
      contactNumber: json["contact_number"] ?? 'No contact provided',
      currentBid: json.containsKey("current_bid") ? json["current_bid"] : null,
      imgURLs: json["car_img_url"] is String
          ? [json["car_img_url"]]
          : json["car_img_url"] is List
              ? json["car_img_url"].map<String>((e) => e.toString()).toList()
              : [],
      location: json["car_location"] ?? 'Location not specified',
      postedBy: json["posted_by"] ?? 'Unknown user',
      price: json["car_price"] ?? 0,
      status: json["status"] ?? "Available",
      make: json["car_make"] ?? 'Unknown',
      year: json["car_year"] ?? 0,
      fuelType: json["car_fuel_type"] ?? 'Unknown',
      mileage: json["car_mileage"] ?? 0,
      createdAt: json['created_at'] ?? Timestamp.now(),
      biddingEnabled: json.containsKey('bidding_enabled') ? json['bidding_enabled'] : false,
      maxBid: json.containsKey('max_bid_amount') ? json['max_bid_amount'] : null,
      minBid: json.containsKey('min_bid_amount') ? json['min_bid_amount'] : null,
      biddingEndDate: json.containsKey('bid_end_time') ? json['bid_end_time'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_name': name,
      'car_description': descripton,
      'car_condition': condition,
      'contact_number': contactNumber,
      'current_bid': currentBid,
      'car_img_url': imgURLs,
      'car_location': location,
      'posted_by': postedBy,
      'car_price': price,
      'status': status,
      'car_make': make,
      'car_year': year,
      'car_fuel_type': fuelType,
      'car_mileage': mileage,
      'created_at': createdAt,
      'bidding_enabled': biddingEnabled,
      'max_bid_amount': maxBid,
      'min_bid_amount': minBid,
      'bid_end_time': biddingEndDate,
    };
  }

  // Helper method to generate search keys for existing ads
  List<String> generateSearchKeys() {
    List<String> searchKeys = [];
    
    // Add car name search keys
    if (name.isNotEmpty) {
      List<String> nameWords = name
          .replaceAll(RegExp('[^A-Za-z0-9& ]'), '')
          .split(" ");
      
      for (int i = 0; i < nameWords.length; i++) {
        if (i != nameWords.length - 1) {
          searchKeys.add(nameWords[i].trim().toLowerCase());
        }
        List<String> temp = [nameWords[i].trim().toLowerCase()];
        for (int j = i + 1; j < nameWords.length; j++) {
          temp.add(nameWords[j].trim().toLowerCase());
          searchKeys.add(temp.join(' '));
        }
      }
    }
    
    // Add make search keys
    if (make.isNotEmpty) {
      searchKeys.add(make.toLowerCase());
    }
    
    // Add location search keys
    if (location.isNotEmpty) {
      searchKeys.add(location.toLowerCase());
    }
    
    // Remove duplicates and empty strings
    return searchKeys.where((key) => key.isNotEmpty).toSet().toList();
  }
}
