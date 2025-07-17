import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? profileImageUrl;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool isActive;
  final int totalAds;
  final int activeAds;
  final int totalBids;
  final int activeBids;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.totalAds = 0,
    this.activeAds = 0,
    this.totalBids = 0,
    this.activeBids = 0,
  });

  factory UserModel.fromJson(String docId, Map<String, dynamic> json) {
    return UserModel(
      id: docId,
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'] ?? Timestamp.now(),
      isActive: json['isActive'] ?? true,
      totalAds: json['totalAds'] ?? 0,
      activeAds: json['activeAds'] ?? 0,
      totalBids: json['totalBids'] ?? 0,
      activeBids: json['activeBids'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'totalAds': totalAds,
      'activeAds': activeAds,
      'totalBids': totalBids,
      'activeBids': activeBids,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? profileImageUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isActive,
    int? totalAds,
    int? activeAds,
    int? totalBids,
    int? activeBids,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      totalAds: totalAds ?? this.totalAds,
      activeAds: activeAds ?? this.activeAds,
      totalBids: totalBids ?? this.totalBids,
      activeBids: activeBids ?? this.activeBids,
    );
  }
}
