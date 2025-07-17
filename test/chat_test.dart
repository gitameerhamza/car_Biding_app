import 'package:flutter_test/flutter_test.dart';
import 'package:cbazaar/features/user/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Chat Feature Tests', () {
    test('ChatModel creation and serialization', () {
      final chat = ChatModel(
        id: 'test_chat_id',
        carId: 'test_car_id',
        buyerId: 'buyer_123',
        sellerId: 'seller_456',
        buyerName: 'John Buyer',
        sellerName: 'Jane Seller',
        carTitle: 'Toyota Camry 2020',
        lastMessage: 'Hello, is this car still available?',
        lastMessageSender: 'buyer_123',
        lastMessageTime: Timestamp.now(),
        createdAt: Timestamp.now(),
        isActive: true,
        unreadBy: ['seller_456'],
      );

      expect(chat.id, 'test_chat_id');
      expect(chat.buyerName, 'John Buyer');
      expect(chat.isActive, true);
      expect(chat.unreadBy.contains('seller_456'), true);

      // Test JSON serialization
      final json = chat.toJson();
      expect(json['buyerId'], 'buyer_123');
      expect(json['carTitle'], 'Toyota Camry 2020');
    });

    test('MessageModel creation and serialization', () {
      final message = MessageModel(
        id: 'test_message_id',
        chatId: 'test_chat_id',
        senderId: 'buyer_123',
        senderName: 'John Buyer',
        message: 'Hello, is this car still available?',
        messageType: MessageType.text,
        sentAt: Timestamp.now(),
        isRead: false,
      );

      expect(message.id, 'test_message_id');
      expect(message.messageType, MessageType.text);
      expect(message.isRead, false);

      // Test JSON serialization
      final json = message.toJson();
      expect(json['senderId'], 'buyer_123');
      expect(json['messageType'], 'text');
    });

    test('MessageType enum conversion', () {
      expect(MessageType.fromString('text'), MessageType.text);
      expect(MessageType.fromString('image'), MessageType.image);
      expect(MessageType.fromString('system'), MessageType.system);
      expect(MessageType.fromString('unknown'), MessageType.text); // fallback

      expect(MessageType.text.toString(), 'text');
      expect(MessageType.image.toString(), 'image');
      expect(MessageType.system.toString(), 'system');
    });

    test('ChatModel copyWith functionality', () {
      final originalChat = ChatModel(
        id: 'test_chat_id',
        carId: 'test_car_id',
        buyerId: 'buyer_123',
        sellerId: 'seller_456',
        buyerName: 'John Buyer',
        sellerName: 'Jane Seller',
        carTitle: 'Toyota Camry 2020',
        lastMessage: 'Hello',
        lastMessageSender: 'buyer_123',
        lastMessageTime: Timestamp.now(),
        createdAt: Timestamp.now(),
        isActive: true,
        unreadBy: ['seller_456'],
      );

      final updatedChat = originalChat.copyWith(
        lastMessage: 'New message',
        unreadBy: [],
      );

      expect(updatedChat.lastMessage, 'New message');
      expect(updatedChat.unreadBy.isEmpty, true);
      expect(updatedChat.buyerName, 'John Buyer'); // unchanged
      expect(updatedChat.id, 'test_chat_id'); // unchanged
    });

    test('MessageModel copyWith functionality', () {
      final originalMessage = MessageModel(
        id: 'test_message_id',
        chatId: 'test_chat_id',
        senderId: 'buyer_123',
        senderName: 'John Buyer',
        message: 'Hello',
        messageType: MessageType.text,
        sentAt: Timestamp.now(),
        isRead: false,
      );

      final updatedMessage = originalMessage.copyWith(
        isRead: true,
        message: 'Updated message',
      );

      expect(updatedMessage.isRead, true);
      expect(updatedMessage.message, 'Updated message');
      expect(updatedMessage.senderId, 'buyer_123'); // unchanged
      expect(updatedMessage.messageType, MessageType.text); // unchanged
    });
  });
}
