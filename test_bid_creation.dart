import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final firestore = FirebaseFirestore.instance;
  
  // Create a test bid
  final testBid = {
    'car_id': 'test_car_123',
    'bidder_id': 'test_bidder_456',
    'bidder_email': 'testbidder@example.com',
    'bid_amount': 15000,
    'bid_time': Timestamp.now(),
    'status': 'active',
    'is_auto_generated': false,
    'notes': 'Test bid for debugging purposes',
    'metadata': {'test': true},
  };
  
  try {
    // Add the test bid to Firestore
    final docRef = await firestore.collection('bids').add(testBid);
    print('✅ Test bid created successfully with ID: ${docRef.id}');
    
    // Verify it was created by reading it back
    final doc = await docRef.get();
    if (doc.exists) {
      print('✅ Test bid verified in database');
      print('   Bid Amount: \$${doc.data()!['bid_amount']}');
      print('   Status: ${doc.data()!['status']}');
      print('   Bidder: ${doc.data()!['bidder_email']}');
    }
    
    // Query all bids to see the count
    final querySnapshot = await firestore.collection('bids').get();
    print('📊 Total bids in database: ${querySnapshot.docs.length}');
    
  } catch (e) {
    print('❌ Error creating test bid: $e');
  }
}
