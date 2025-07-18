import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String id;
  final String carId;
  final String bidderId;
  final String bidderEmail;
  final int bidAmount;
  final Timestamp bidTime;
  final String status; // 'active', 'withdrawn', 'rejected', 'accepted'
  final String? notes;
  final bool isAutoGenerated;
  final Map<String, dynamic>? metadata;

  const BidModel({
    required this.id,
    required this.carId,
    required this.bidderId,
    required this.bidderEmail,
    required this.bidAmount,
    required this.bidTime,
    required this.status,
    this.notes,
    required this.isAutoGenerated,
    this.metadata,
  });

  factory BidModel.fromJson(String docId, Map<String, dynamic> json) {
    return BidModel(
      id: docId,
      carId: json['car_id'] ?? '',
      bidderId: json['bidder_id'] ?? '',
      bidderEmail: json['bidder_email'] ?? '',
      bidAmount: json['bid_amount'] ?? 0,
      bidTime: json['bid_time'] ?? Timestamp.now(),
      status: json['status'] ?? 'active',
      notes: json['notes'],
      isAutoGenerated: json['is_auto_generated'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_id': carId,
      'bidder_id': bidderId,
      'bidder_email': bidderEmail,
      'bid_amount': bidAmount,
      'bid_time': bidTime,
      'status': status,
      'notes': notes,
      'is_auto_generated': isAutoGenerated,
      'metadata': metadata,
    };
  }
}

class AdminEventModel {
  final String id;
  final String eventName;
  final String eventDescription;
  final String eventVenue;
  final String eventDate;
  final String eventImgUrl;
  final String createdBy;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final bool isActive;
  final String status; // 'draft', 'published', 'cancelled'
  final Map<String, dynamic>? additionalInfo;

  const AdminEventModel({
    required this.id,
    required this.eventName,
    required this.eventDescription,
    required this.eventVenue,
    required this.eventDate,
    required this.eventImgUrl,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.status,
    this.additionalInfo,
  });

  factory AdminEventModel.fromJson(String docId, Map<String, dynamic> json) {
    return AdminEventModel(
      id: docId,
      eventName: json['event_name'] ?? '',
      eventDescription: json['event_description'] ?? '',
      eventVenue: json['event_venue'] ?? '',
      eventDate: json['event_date'] ?? '',
      eventImgUrl: json['event_img_url'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] ?? Timestamp.now(),
      updatedAt: json['updated_at'],
      isActive: json['is_active'] ?? true,
      status: json['status'] ?? 'draft',
      additionalInfo: json['additional_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_name': eventName,
      'event_description': eventDescription,
      'event_venue': eventVenue,
      'event_date': eventDate,
      'event_img_url': eventImgUrl,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_active': isActive,
      'status': status,
      'additional_info': additionalInfo,
    };
  }
}

class AdminStatsModel {
  final String id;
  final int totalUsers;
  final int totalAds;
  final int totalBids;
  final int totalEvents;
  final int activeAds;
  final int pendingAds;
  final int todayNewUsers;
  final int todayNewAds;
  final Timestamp lastUpdated;
  final int? restrictedUsers;
  final int? suspiciousUsers;
  final int? expiredAds;
  final Map<String, int>? usersByMonth;
  final Map<String, int>? adsByCategory;
  final Map<String, int>? bidsByStatus;

  const AdminStatsModel({
    required this.id,
    required this.totalUsers,
    required this.totalAds,
    required this.totalBids,
    required this.totalEvents,
    required this.activeAds,
    required this.pendingAds,
    required this.todayNewUsers,
    required this.todayNewAds,
    required this.lastUpdated,
    this.restrictedUsers,
    this.suspiciousUsers,
    this.expiredAds,
    this.usersByMonth,
    this.adsByCategory,
    this.bidsByStatus,
  });

  factory AdminStatsModel.fromJson(String docId, Map<String, dynamic> json) {
    return AdminStatsModel(
      id: docId,
      totalUsers: json['total_users'] ?? 0,
      totalAds: json['total_ads'] ?? 0,
      totalBids: json['total_bids'] ?? 0,
      totalEvents: json['total_events'] ?? 0,
      activeAds: json['active_ads'] ?? 0,
      pendingAds: json['pending_ads'] ?? 0,
      todayNewUsers: json['today_new_users'] ?? 0,
      todayNewAds: json['today_new_ads'] ?? 0,
      lastUpdated: json['last_updated'] ?? Timestamp.now(),
      restrictedUsers: json['restricted_users'],
      suspiciousUsers: json['suspicious_users'],
      expiredAds: json['expired_ads'],
      usersByMonth: json['users_by_month'] != null 
          ? Map<String, int>.from(json['users_by_month']) 
          : null,
      adsByCategory: json['ads_by_category'] != null 
          ? Map<String, int>.from(json['ads_by_category']) 
          : null,
      bidsByStatus: json['bids_by_status'] != null 
          ? Map<String, int>.from(json['bids_by_status']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'total_ads': totalAds,
      'total_bids': totalBids,
      'total_events': totalEvents,
      'active_ads': activeAds,
      'pending_ads': pendingAds,
      'today_new_users': todayNewUsers,
      'today_new_ads': todayNewAds,
      'last_updated': lastUpdated,
      'restricted_users': restrictedUsers,
      'suspicious_users': suspiciousUsers,
      'expired_ads': expiredAds,
      'users_by_month': usersByMonth,
      'ads_by_category': adsByCategory,
      'bids_by_status': bidsByStatus,
    };
  }
}
