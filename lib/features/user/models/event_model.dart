import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String imageUrl;
  final Timestamp eventDate;
  final Timestamp createdAt;
  final EventType eventType;
  final bool isActive;
  final List<String> attendees;
  final String organizer;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.eventDate,
    required this.createdAt,
    required this.eventType,
    required this.isActive,
    required this.attendees,
    required this.organizer,
  });

  factory EventModel.fromJson(String docId, Map<String, dynamic> json) {
    return EventModel(
      id: docId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      eventDate: json['eventDate'] ?? Timestamp.now(),
      createdAt: json['createdAt'] ?? Timestamp.now(),
      eventType: EventType.fromString(json['eventType'] ?? 'auto_show'),
      isActive: json['isActive'] ?? true,
      attendees: List<String>.from(json['attendees'] ?? []),
      organizer: json['organizer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'eventDate': eventDate,
      'createdAt': createdAt,
      'eventType': eventType.toString(),
      'isActive': isActive,
      'attendees': attendees,
      'organizer': organizer,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? imageUrl,
    Timestamp? eventDate,
    Timestamp? createdAt,
    EventType? eventType,
    bool? isActive,
    List<String>? attendees,
    String? organizer,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      eventDate: eventDate ?? this.eventDate,
      createdAt: createdAt ?? this.createdAt,
      eventType: eventType ?? this.eventType,
      isActive: isActive ?? this.isActive,
      attendees: attendees ?? this.attendees,
      organizer: organizer ?? this.organizer,
    );
  }
}

enum EventType {
  autoShow,
  carMeet,
  auction,
  exhibition,
  workshop,
  racing;

  static EventType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'auto_show':
        return EventType.autoShow;
      case 'car_meet':
        return EventType.carMeet;
      case 'auction':
        return EventType.auction;
      case 'exhibition':
        return EventType.exhibition;
      case 'workshop':
        return EventType.workshop;
      case 'racing':
        return EventType.racing;
      default:
        return EventType.autoShow;
    }
  }

  @override
  String toString() {
    switch (this) {
      case EventType.autoShow:
        return 'auto_show';
      case EventType.carMeet:
        return 'car_meet';
      case EventType.auction:
        return 'auction';
      case EventType.exhibition:
        return 'exhibition';
      case EventType.workshop:
        return 'workshop';
      case EventType.racing:
        return 'racing';
    }
  }

  String get displayName {
    switch (this) {
      case EventType.autoShow:
        return 'Auto Show';
      case EventType.carMeet:
        return 'Car Meet';
      case EventType.auction:
        return 'Auction';
      case EventType.exhibition:
        return 'Exhibition';
      case EventType.workshop:
        return 'Workshop';
      case EventType.racing:
        return 'Racing';
    }
  }
}
