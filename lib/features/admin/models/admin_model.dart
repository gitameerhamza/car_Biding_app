import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String email;
  final String role; // 'admin' - single admin role with full access
  final List<String> permissions;
  final Timestamp createdAt;
  final Timestamp? lastLoginAt;
  final bool isActive;

  const AdminModel({
    required this.id,
    required this.email,
    required this.role,
    required this.permissions,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
  });

  factory AdminModel.fromJson(String docId, Map<String, dynamic> json) {
    return AdminModel(
      id: docId,
      email: json['email'] ?? '',
      role: json['role'] ?? 'admin',
      permissions: List<String>.from(json['permissions'] ?? []),
      createdAt: json['created_at'] ?? Timestamp.now(),
      lastLoginAt: json['last_login_at'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
      'permissions': permissions,
      'created_at': createdAt,
      'last_login_at': lastLoginAt,
      'is_active': isActive,
    };
  }

  AdminModel copyWith({
    String? id,
    String? email,
    String? role,
    List<String>? permissions,
    Timestamp? createdAt,
    Timestamp? lastLoginAt,
    bool? isActive,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
