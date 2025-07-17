import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Get all active events
  Stream<List<EventModel>> getActiveEvents() {
    try {
      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get events: $e');
    }
  }

  // Get upcoming events
  Stream<List<EventModel>> getUpcomingEvents() {
    try {
      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('eventDate', isGreaterThan: Timestamp.now())
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get upcoming events: $e');
    }
  }

  // Get events by type
  Stream<List<EventModel>> getEventsByType(EventType eventType) {
    try {
      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('eventType', isEqualTo: eventType.toString())
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get events by type: $e');
    }
  }

  // Get events by location
  Stream<List<EventModel>> getEventsByLocation(String location) {
    try {
      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('location', isGreaterThanOrEqualTo: location)
          .where('location', isLessThanOrEqualTo: '$location\uf8ff')
          .orderBy('location')
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get events by location: $e');
    }
  }

  // Get event details by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists) return null;

      return EventModel.fromJson(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get event details: $e');
    }
  }

  // Join an event
  Future<void> joinEvent(String eventId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if event exists
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');

      final event = EventModel.fromJson(eventDoc.id, eventDoc.data()!);

      // Check if user is already attending
      if (event.attendees.contains(user.uid)) {
        throw Exception('You are already registered for this event');
      }

      // Check if event is still active and upcoming
      if (!event.isActive) {
        throw Exception('This event is no longer active');
      }

      if (event.eventDate.toDate().isBefore(DateTime.now())) {
        throw Exception('This event has already passed');
      }

      // Add user to attendees list
      await _firestore.collection('events').doc(eventId).update({
        'attendees': FieldValue.arrayUnion([user.uid]),
      });

    } catch (e) {
      throw Exception('Failed to join event: $e');
    }
  }

  // Leave an event
  Future<void> leaveEvent(String eventId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if event exists
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');

      final event = EventModel.fromJson(eventDoc.id, eventDoc.data()!);

      // Check if user is attending
      if (!event.attendees.contains(user.uid)) {
        throw Exception('You are not registered for this event');
      }

      // Remove user from attendees list
      await _firestore.collection('events').doc(eventId).update({
        'attendees': FieldValue.arrayRemove([user.uid]),
      });

    } catch (e) {
      throw Exception('Failed to leave event: $e');
    }
  }

  // Get events user is attending
  Stream<List<EventModel>> getUserAttendingEvents() {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('events')
          .where('attendees', arrayContains: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get user attending events: $e');
    }
  }

  // Search events
  Future<List<EventModel>> searchEvents(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final titleQuery = await _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('title')
          .orderBy('eventDate')
          .limit(20)
          .get();

      final locationQuery = await _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('location', isGreaterThanOrEqualTo: query)
          .where('location', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('location')
          .orderBy('eventDate')
          .limit(20)
          .get();

      final events = <EventModel>[];
      final seenIds = <String>{};

      for (final doc in titleQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          events.add(EventModel.fromJson(doc.id, doc.data()));
          seenIds.add(doc.id);
        }
      }

      for (final doc in locationQuery.docs) {
        if (!seenIds.contains(doc.id)) {
          events.add(EventModel.fromJson(doc.id, doc.data()));
          seenIds.add(doc.id);
        }
      }

      // Sort by event date
      events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

      return events;
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  // Check if user is attending an event
  Future<bool> isUserAttending(String eventId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;

      final event = EventModel.fromJson(eventDoc.id, eventDoc.data()!);
      return event.attendees.contains(user.uid);
    } catch (e) {
      return false;
    }
  }

  // Get event attendees count
  Future<int> getEventAttendeesCount(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return 0;

      final event = EventModel.fromJson(eventDoc.id, eventDoc.data()!);
      return event.attendees.length;
    } catch (e) {
      return 0;
    }
  }

  // Get all available event types
  List<EventType> getAllEventTypes() {
    return EventType.values;
  }

  // Get events happening this week
  Stream<List<EventModel>> getThisWeekEvents() {
    try {
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('eventDate', isLessThan: Timestamp.fromDate(endOfWeek))
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get this week events: $e');
    }
  }

  // Get events happening this month
  Stream<List<EventModel>> getThisMonthEvents() {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('eventDate', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('eventDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromJson(doc.id, doc.data())).toList();
      });
    } catch (e) {
      throw Exception('Failed to get this month events: $e');
    }
  }
}
