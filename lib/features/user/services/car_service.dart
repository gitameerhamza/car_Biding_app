import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/models/car_model.dart';
import '../models/car_filter_model.dart';
import 'user_service.dart';

class CarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;

  // Get all available cars
  Stream<List<CarModel>> getAllCars() {
    try {
      return _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => CarModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get cars: $e');
    }
  }

  // Get user's cars
  Stream<List<CarModel>> getUserCars() {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('ads')
          .where('posted_by', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => CarModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get user cars: $e');
    }
  }

  // Get car by ID
  Future<CarModel?> getCarById(String carId) async {
    try {
      final doc = await _firestore.collection('ads').doc(carId).get();
      if (!doc.exists) return null;

      return CarModel.fromJson(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get car details: $e');
    }
  }

  // Mark car as sold
  Future<void> markCarAsSold(String carId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final carDoc = await _firestore.collection('ads').doc(carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      if (carData['posted_by'] != user.uid) {
        throw Exception('You can only mark your own cars as sold');
      }

      // Mark all remaining bids as expired when car is sold
      await _expireAllBidsForCar(carId);

      // Update car status
      await _firestore.collection('ads').doc(carId).update({
        'status': 'Sold',
        'soldAt': Timestamp.now(),
      });

      // Refresh user statistics
      await _userService.refreshUserStats(user.uid);

    } catch (e) {
      throw Exception('Failed to mark car as sold: $e');
    }
  }

  // Private method to expire all bids when car is sold
  Future<void> _expireAllBidsForCar(String carId) async {
    try {
      // Get all pending bids for this car
      final bidsQuery = await _firestore
          .collection('bids')
          .where('carId', isEqualTo: carId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (bidsQuery.docs.isEmpty) return;

      // Create batch for atomic operation
      final batch = _firestore.batch();
      int bidCount = 0;

      // Process each pending bid
      for (final bidDoc in bidsQuery.docs) {
        final bidData = bidDoc.data();
        bidCount++;

        // Mark bid as expired
        batch.update(bidDoc.reference, {
          'status': 'expired',
          'expiredAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Create notification for bidder about car being sold
        batch.set(
          _firestore.collection('notifications').doc(),
          {
            'userId': bidData['bidderId'],
            'type': 'car_sold',
            'title': 'Car Sold',
            'message': 'The car you bid on has been sold. Your bid has been marked as expired.',
            'carId': carId,
            'bidAmount': bidData['bidAmount'] ?? 0,
            'read': false,
            'createdAt': Timestamp.now(),
          },
        );
      }

      // Execute all operations atomically
      await batch.commit();

      print('Expired $bidCount bids for sold car $carId');

    } catch (e) {
      print('Failed to expire bids for car: $e');
      // Don't throw here as we still want to mark car as sold
    }
  }

  // Mark car as available
  Future<void> markCarAsAvailable(String carId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final carDoc = await _firestore.collection('ads').doc(carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      if (carData['posted_by'] != user.uid) {
        throw Exception('You can only update your own cars');
      }

      await _firestore.collection('ads').doc(carId).update({
        'status': 'Available',
      });

      // Refresh user statistics
      await _userService.refreshUserStats(user.uid);

    } catch (e) {
      throw Exception('Failed to mark car as available: $e');
    }
  }

  // Delete car ad
  Future<void> deleteCarAd(String carId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify ownership
      final carDoc = await _firestore.collection('ads').doc(carId).get();
      if (!carDoc.exists) throw Exception('Car not found');

      final carData = carDoc.data()!;
      if (carData['posted_by'] != user.uid) {
        throw Exception('You can only delete your own cars');
      }

      // First, remove all bids for this car
      await _removeAllBidsForCar(carId);

      // Delete the car ad
      await _firestore.collection('ads').doc(carId).delete();

      // Refresh user statistics
      await _userService.refreshUserStats(user.uid);

    } catch (e) {
      throw Exception('Failed to delete car ad: $e');
    }
  }

  // Private method to remove all bids for a car
  Future<void> _removeAllBidsForCar(String carId) async {
    try {
      // Get all bids for this car
      final bidsQuery = await _firestore
          .collection('bids')
          .where('carId', isEqualTo: carId)
          .get();

      if (bidsQuery.docs.isEmpty) return;

      // Create batch for atomic operation
      final batch = _firestore.batch();
      int bidCount = 0;

      // Process each bid
      for (final bidDoc in bidsQuery.docs) {
        final bidData = bidDoc.data();
        bidCount++;

        // Delete the bid
        batch.delete(bidDoc.reference);

        // Update user bid statistics for each bidder
        batch.update(
          _firestore.collection('users').doc(bidData['bidderId']),
          {
            'totalBids': FieldValue.increment(-1),
            'updatedAt': Timestamp.now(),
          },
        );

        // Create notification for bidder about car removal
        batch.set(
          _firestore.collection('notifications').doc(),
          {
            'userId': bidData['bidderId'],
            'type': 'car_removed',
            'title': 'Car Listing Removed',
            'message': 'The car you bid on has been removed by the seller. Your bid has been automatically cancelled.',
            'carId': carId,
            'bidAmount': bidData['bidAmount'] ?? 0,
            'read': false,
            'createdAt': Timestamp.now(),
          },
        );
      }

      // Execute all operations atomically
      await batch.commit();

      print('Removed $bidCount bids for deleted car $carId');

    } catch (e) {
      print('Failed to remove bids for car: $e');
      // Don't throw here as we still want to delete the car
    }
  }

  // Search cars with filters
  Future<List<CarModel>> searchCarsWithFilters(CarFilter filter, {String? searchText}) async {
    try {
      Query query = _firestore.collection('ads').where('status', isEqualTo: 'Available');

      // Apply filters
      if (filter.companies.isNotEmpty) {
        query = query.where('car_make', whereIn: filter.companies);
      }

      if (filter.conditions.isNotEmpty) {
        query = query.where('car_condition', whereIn: filter.conditions);
      }

      if (filter.fuelType != null) {
        query = query.where('car_fuel_type', isEqualTo: filter.fuelType);
      }

      if (filter.priceRange != null) {
        query = query
            .where('car_price', isGreaterThanOrEqualTo: filter.priceRange!.start.toInt())
            .where('car_price', isLessThanOrEqualTo: filter.priceRange!.end.toInt());
      }

      if (filter.yearMin != null) {
        query = query.where('car_year', isGreaterThanOrEqualTo: filter.yearMin);
      }

      if (filter.yearMax != null) {
        query = query.where('car_year', isLessThanOrEqualTo: filter.yearMax);
      }

      // Apply search text filter
      if (searchText != null && searchText.trim().isNotEmpty) {
        query = query.where('search_keys', arrayContains: searchText.trim().toLowerCase());
      }

      // Execute query
      final snapshot = await query.get();
      List<CarModel> cars = snapshot.docs.map((doc) => CarModel.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList();

      // Apply additional filters that can't be done in Firestore query
      if (filter.colors.isNotEmpty) {
        cars = cars.where((car) {
          // Assuming color is stored in description or we need to add a color field
          return filter.colors.any((color) => 
            car.descripton.toLowerCase().contains(color.toLowerCase()));
        }).toList();
      }

      if (filter.locations.isNotEmpty) {
        cars = cars.where((car) {
          return filter.locations.any((location) => 
            car.location.toLowerCase().contains(location.toLowerCase()));
        }).toList();
      }

      // Apply sorting
      if (filter.sortBy != null) {
        cars.sort((a, b) {
          int comparison = 0;
          switch (filter.sortBy) {
            case 'price':
              comparison = a.price.compareTo(b.price);
              break;
            case 'year':
              comparison = a.year.compareTo(b.year);
              break;
            case 'mileage':
              comparison = a.mileage.compareTo(b.mileage);
              break;
            case 'created_at':
              comparison = a.createdAt?.compareTo(b.createdAt ?? Timestamp.now()) ?? 0;
              break;
            default:
              comparison = a.createdAt?.compareTo(b.createdAt ?? Timestamp.now()) ?? 0;
          }
          return filter.sortAscending ? comparison : -comparison;
        });
      }

      return cars;
    } catch (e) {
      throw Exception('Failed to search cars: $e');
    }
  }

  // Get available car companies
  Future<List<String>> getAvailableCompanies() async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .get();

      final companies = <String>{};
      for (final doc in snapshot.docs) {
        final make = doc.data()['car_make'] as String?;
        if (make != null && make.isNotEmpty) {
          companies.add(make);
        }
      }

      final sortedCompanies = companies.toList()..sort();
      return sortedCompanies;
    } catch (e) {
      throw Exception('Failed to get available companies: $e');
    }
  }

  // Get available conditions
  Future<List<String>> getAvailableConditions() async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .get();

      final conditions = <String>{};
      for (final doc in snapshot.docs) {
        final condition = doc.data()['car_condition'] as String?;
        if (condition != null && condition.isNotEmpty) {
          conditions.add(condition);
        }
      }

      final sortedConditions = conditions.toList()..sort();
      return sortedConditions;
    } catch (e) {
      throw Exception('Failed to get available conditions: $e');
    }
  }

  // Get available locations
  Future<List<String>> getAvailableLocations() async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .get();

      final locations = <String>{};
      for (final doc in snapshot.docs) {
        final location = doc.data()['car_location'] as String?;
        if (location != null && location.isNotEmpty) {
          locations.add(location);
        }
      }

      final sortedLocations = locations.toList()..sort();
      return sortedLocations;
    } catch (e) {
      throw Exception('Failed to get available locations: $e');
    }
  }

  // Get available fuel types
  Future<List<String>> getAvailableFuelTypes() async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .get();

      final fuelTypes = <String>{};
      for (final doc in snapshot.docs) {
        final fuelType = doc.data()['car_fuel_type'] as String?;
        if (fuelType != null && fuelType.isNotEmpty) {
          fuelTypes.add(fuelType);
        }
      }

      final sortedFuelTypes = fuelTypes.toList()..sort();
      return sortedFuelTypes;
    } catch (e) {
      throw Exception('Failed to get available fuel types: $e');
    }
  }

  // Get price range of available cars
  Future<RangeValues> getPriceRange() async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .get();

      if (snapshot.docs.isEmpty) {
        return const RangeValues(0, 100000);
      }

      int minPrice = double.maxFinite.toInt();
      int maxPrice = 0;

      for (final doc in snapshot.docs) {
        final price = doc.data()['car_price'] as int?;
        if (price != null) {
          if (price < minPrice) minPrice = price;
          if (price > maxPrice) maxPrice = price;
        }
      }

      return RangeValues(minPrice.toDouble(), maxPrice.toDouble());
    } catch (e) {
      return const RangeValues(0, 100000);
    }
  }

  // Get year range of available cars
  Future<RangeValues> getYearRange() async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .get();

      if (snapshot.docs.isEmpty) {
        final currentYear = DateTime.now().year;
        return RangeValues((currentYear - 30).toDouble(), currentYear.toDouble());
      }

      int minYear = double.maxFinite.toInt();
      int maxYear = 0;

      for (final doc in snapshot.docs) {
        final year = doc.data()['car_year'] as int?;
        if (year != null) {
          if (year < minYear) minYear = year;
          if (year > maxYear) maxYear = year;
        }
      }

      return RangeValues(minYear.toDouble(), maxYear.toDouble());
    } catch (e) {
      final currentYear = DateTime.now().year;
      return RangeValues((currentYear - 30).toDouble(), currentYear.toDouble());
    }
  }

  // Get featured cars (highest priced or newest)
  Stream<List<CarModel>> getFeaturedCars({int limit = 10}) {
    try {
      return _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .orderBy('car_price', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => CarModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get featured cars: $e');
    }
  }

  // Get cars with bidding enabled
  Stream<List<CarModel>> getCarsWithBidding() {
    try {
      return _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .where('bidding_enabled', isEqualTo: true)
          .where('bid_end_time', isGreaterThan: Timestamp.now())
          .orderBy('bid_end_time', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => CarModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get cars with bidding: $e');
    }
  }

  // Search cars by text
  Future<List<CarModel>> searchCarsByText(String searchText) async {
    try {
      if (searchText.trim().isEmpty) return [];

      final query = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'Available')
          .where('search_keys', arrayContains: searchText.trim().toLowerCase())
          .limit(50)
          .get();

      return query.docs.map((doc) => CarModel.fromJson(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to search cars by text: $e');
    }
  }
}
