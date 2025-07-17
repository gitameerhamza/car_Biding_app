import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String id;
  final String carId;
  final String bidderId;
  final String bidderName;
  final String bidderEmail;
  final int bidAmount;
  final String message;
  final BidStatus status;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? acceptedAt;
  final Timestamp? rejectedAt;

  const BidModel({
    required this.id,
    required this.carId,
    required this.bidderId,
    required this.bidderName,
    required this.bidderEmail,
    required this.bidAmount,
    required this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.rejectedAt,
  });

  factory BidModel.fromJson(String docId, Map<String, dynamic> json) {
    return BidModel(
      id: docId,
      carId: json['carId'] ?? '',
      bidderId: json['bidderId'] ?? '',
      bidderName: json['bidderName'] ?? '',
      bidderEmail: json['bidderEmail'] ?? '',
      bidAmount: json['bidAmount'] ?? 0,
      message: json['message'] ?? '',
      status: BidStatus.fromString(json['status'] ?? 'pending'),
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'],
      acceptedAt: json['acceptedAt'],
      rejectedAt: json['rejectedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carId': carId,
      'bidderId': bidderId,
      'bidderName': bidderName,
      'bidderEmail': bidderEmail,
      'bidAmount': bidAmount,
      'message': message,
      'status': status.toString(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'acceptedAt': acceptedAt,
      'rejectedAt': rejectedAt,
    };
  }

  BidModel copyWith({
    String? id,
    String? carId,
    String? bidderId,
    String? bidderName,
    String? bidderEmail,
    int? bidAmount,
    String? message,
    BidStatus? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? acceptedAt,
    Timestamp? rejectedAt,
  }) {
    return BidModel(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      bidderId: bidderId ?? this.bidderId,
      bidderName: bidderName ?? this.bidderName,
      bidderEmail: bidderEmail ?? this.bidderEmail,
      bidAmount: bidAmount ?? this.bidAmount,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
    );
  }
}

enum BidStatus {
  pending,
  accepted,
  rejected,
  expired,
  withdrawn;

  static BidStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BidStatus.pending;
      case 'accepted':
        return BidStatus.accepted;
      case 'rejected':
        return BidStatus.rejected;
      case 'expired':
        return BidStatus.expired;
      case 'withdrawn':
        return BidStatus.withdrawn;
      default:
        return BidStatus.pending;
    }
  }

  @override
  String toString() {
    return name;
  }
}
