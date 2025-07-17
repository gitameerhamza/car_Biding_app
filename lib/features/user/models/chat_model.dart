import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String carId;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final String carTitle;
  final String lastMessage;
  final String lastMessageSender;
  final Timestamp lastMessageTime;
  final Timestamp createdAt;
  final bool isActive;
  final List<String> unreadBy;

  const ChatModel({
    required this.id,
    required this.carId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    required this.carTitle,
    required this.lastMessage,
    required this.lastMessageSender,
    required this.lastMessageTime,
    required this.createdAt,
    required this.isActive,
    required this.unreadBy,
  });

  factory ChatModel.fromJson(String docId, Map<String, dynamic> json) {
    return ChatModel(
      id: docId,
      carId: json['carId'] ?? '',
      buyerId: json['buyerId'] ?? '',
      sellerId: json['sellerId'] ?? '',
      buyerName: json['buyerName'] ?? '',
      sellerName: json['sellerName'] ?? '',
      carTitle: json['carTitle'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageSender: json['lastMessageSender'] ?? '',
      lastMessageTime: json['lastMessageTime'] ?? Timestamp.now(),
      createdAt: json['createdAt'] ?? Timestamp.now(),
      isActive: json['isActive'] ?? true,
      unreadBy: List<String>.from(json['unreadBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carId': carId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'sellerName': sellerName,
      'carTitle': carTitle,
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageTime': lastMessageTime,
      'createdAt': createdAt,
      'isActive': isActive,
      'unreadBy': unreadBy,
    };
  }

  ChatModel copyWith({
    String? id,
    String? carId,
    String? buyerId,
    String? sellerId,
    String? buyerName,
    String? sellerName,
    String? carTitle,
    String? lastMessage,
    String? lastMessageSender,
    Timestamp? lastMessageTime,
    Timestamp? createdAt,
    bool? isActive,
    List<String>? unreadBy,
  }) {
    return ChatModel(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      buyerName: buyerName ?? this.buyerName,
      sellerName: sellerName ?? this.sellerName,
      carTitle: carTitle ?? this.carTitle,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      unreadBy: unreadBy ?? this.unreadBy,
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType messageType;
  final Timestamp sentAt;
  final bool isRead;
  final String? imageUrl;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    required this.sentAt,
    required this.isRead,
    this.imageUrl,
  });

  factory MessageModel.fromJson(String docId, Map<String, dynamic> json) {
    return MessageModel(
      id: docId,
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      messageType: MessageType.fromString(json['messageType'] ?? 'text'),
      sentAt: json['sentAt'] ?? Timestamp.now(),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'messageType': messageType.toString(),
      'sentAt': sentAt,
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? message,
    MessageType? messageType,
    Timestamp? sentAt,
    bool? isRead,
    String? imageUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

enum MessageType {
  text,
  image,
  system;

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  @override
  String toString() {
    return name;
  }
}
