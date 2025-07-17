import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Create or get existing chat between buyer and seller for a car
  Future<String> createOrGetChat({
    required String carId,
    required String sellerId,
    required String carTitle,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (user.uid == sellerId) {
        throw Exception('You cannot chat with yourself');
      }

      // Check if chat already exists
      final existingChatsQuery = await _firestore
          .collection('chats')
          .where('carId', isEqualTo: carId)
          .where('buyerId', isEqualTo: user.uid)
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (existingChatsQuery.docs.isNotEmpty) {
        return existingChatsQuery.docs.first.id;
      }

      // Get user details
      final buyerDoc = await _firestore.collection('users').doc(user.uid).get();
      final sellerDoc = await _firestore.collection('users').doc(sellerId).get();

      if (!buyerDoc.exists || !sellerDoc.exists) {
        throw Exception('User details not found');
      }

      final buyerData = buyerDoc.data()!;
      final sellerData = sellerDoc.data()!;

      // Create new chat
      final chatData = ChatModel(
        id: '',
        carId: carId,
        buyerId: user.uid,
        sellerId: sellerId,
        buyerName: buyerData['fullName'] ?? '',
        sellerName: sellerData['fullName'] ?? '',
        carTitle: carTitle,
        lastMessage: '',
        lastMessageSender: '',
        lastMessageTime: Timestamp.now(),
        createdAt: Timestamp.now(),
        isActive: true,
        unreadBy: [],
      );

      final docRef = await _firestore.collection('chats').add(chatData.toJson());
      return docRef.id;

    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats() {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      return _firestore
          .collection('chats')
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatModel.fromJson(doc.id, doc.data()))
            .where((chat) => chat.buyerId == user.uid || chat.sellerId == user.uid)
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get user chats: $e');
    }
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;

      return ChatModel.fromJson(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  // Get messages for a chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.id, doc.data()))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get chat messages: $e');
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    String? imageUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User details not found');

      final userData = userDoc.data()!;
      final senderName = userData['fullName'] ?? '';

      // Get chat details to determine recipient
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) throw Exception('Chat not found');

      final chat = ChatModel.fromJson(chatDoc.id, chatDoc.data()!);

      // Verify user is part of this chat
      if (chat.buyerId != user.uid && chat.sellerId != user.uid) {
        throw Exception('You are not part of this chat');
      }

      final recipientId = chat.buyerId == user.uid ? chat.sellerId : chat.buyerId;

      // Create message
      final messageData = MessageModel(
        id: '',
        chatId: chatId,
        senderId: user.uid,
        senderName: senderName,
        message: message.trim(),
        messageType: imageUrl != null ? MessageType.image : MessageType.text,
        sentAt: Timestamp.now(),
        isRead: false,
        imageUrl: imageUrl,
      );

      // Use batch to update both message and chat
      final batch = _firestore.batch();

      // Add message
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      batch.set(messageRef, messageData.toJson());

      // Update chat last message info
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': imageUrl != null ? '📷 Image' : message.trim(),
        'lastMessageSender': user.uid,
        'lastMessageTime': Timestamp.now(),
        'unreadBy': [recipientId],
      });

      await batch.commit();

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update chat to remove current user from unreadBy list
      await _firestore.collection('chats').doc(chatId).update({
        'unreadBy': FieldValue.arrayRemove([user.uid]),
      });

      // Get recent messages and mark unread ones as read
      // Using timestamp ordering which has a proper index
      final recentMessagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(100) // Process recent 100 messages
          .get();

      if (recentMessagesQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        bool hasUpdates = false;
        
        for (final doc in recentMessagesQuery.docs) {
          final messageData = doc.data();
          // Only mark as read if it's not from the current user and is currently unread
          if (messageData['senderId'] != user.uid && messageData['isRead'] == false) {
            batch.update(doc.reference, {'isRead': true});
            hasUpdates = true;
          }
        }
        
        if (hasUpdates) {
          await batch.commit();
        }
      }

    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get unread chats count
  Stream<int> getUnreadChatsCount() {
    try {
      final user = currentUser;
      if (user == null) return Stream.value(0);

      return _firestore
          .collection('chats')
          .where('unreadBy', arrayContains: user.uid)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  // Delete a message (only for sender)
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get message details
      final messageDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) throw Exception('Message not found');

      final message = MessageModel.fromJson(messageDoc.id, messageDoc.data()!);

      // Verify sender
      if (message.senderId != user.uid) {
        throw Exception('You can only delete your own messages');
      }

      // Delete the message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Archive/deactivate a chat
  Future<void> archiveChat(String chatId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get chat details
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) throw Exception('Chat not found');

      final chat = ChatModel.fromJson(chatDoc.id, chatDoc.data()!);

      // Verify user is part of this chat
      if (chat.buyerId != user.uid && chat.sellerId != user.uid) {
        throw Exception('You are not part of this chat');
      }

      // Deactivate the chat
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
      });

    } catch (e) {
      throw Exception('Failed to archive chat: $e');
    }
  }

  // Get chat for specific car and users
  Future<ChatModel?> getChatForCar({
    required String carId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('carId', isEqualTo: carId)
          .where('buyerId', isEqualTo: buyerId)
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return ChatModel.fromJson(query.docs.first.id, query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get chat for car: $e');
    }
  }

  // Send system message (for bid updates, etc.)
  Future<void> sendSystemMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      // Create system message
      final messageData = MessageModel(
        id: '',
        chatId: chatId,
        senderId: 'system',
        senderName: 'System',
        message: message,
        messageType: MessageType.system,
        sentAt: Timestamp.now(),
        isRead: false,
      );

      // Add message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData.toJson());

      // Update chat last message info
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageSender': 'system',
        'lastMessageTime': Timestamp.now(),
      });

    } catch (e) {
      throw Exception('Failed to send system message: $e');
    }
  }
}
