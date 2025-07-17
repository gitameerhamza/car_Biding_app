import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? carId;
  final int? bidAmount;
  final String? bidderName;
  final String? status;
  final bool read;
  final Timestamp createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.carId,
    this.bidAmount,
    this.bidderName,
    this.status,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(String docId, Map<String, dynamic> json) {
    return NotificationModel(
      id: docId,
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      carId: json['carId'],
      bidAmount: json['bidAmount'],
      bidderName: json['bidderName'],
      status: json['status'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'carId': carId,
      'bidAmount': bidAmount,
      'bidderName': bidderName,
      'status': status,
      'read': read,
      'createdAt': createdAt,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? carId,
    int? bidAmount,
    String? bidderName,
    String? status,
    bool? read,
    Timestamp? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      carId: carId ?? this.carId,
      bidAmount: bidAmount ?? this.bidAmount,
      bidderName: bidderName ?? this.bidderName,
      status: status ?? this.status,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum NotificationType {
  newBid,
  bidStatus,
  general;

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'new_bid':
        return NotificationType.newBid;
      case 'bid_status':
        return NotificationType.bidStatus;
      case 'general':
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }

  @override
  String toString() {
    switch (this) {
      case NotificationType.newBid:
        return 'new_bid';
      case NotificationType.bidStatus:
        return 'bid_status';
      case NotificationType.general:
        return 'general';
    }
  }
}
