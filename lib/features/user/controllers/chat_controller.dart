import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final TextEditingController messageController = TextEditingController();

  // Observable variables
  final RxList<ChatModel> userChats = <ChatModel>[].obs;
  final RxList<MessageModel> currentChatMessages = <MessageModel>[].obs;
  final Rx<ChatModel?> currentChat = Rx<ChatModel?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxInt unreadChatsCount = 0.obs;
  final RxBool autoRefreshEnabled = true.obs;

  // Auto-refresh timer
  Timer? _autoRefreshTimer;

  // Stream subscriptions
  StreamSubscription<List<ChatModel>>? _chatsSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
    loadUserChats();
    loadUnreadChatsCount();
    _startAutoRefresh(); // Start auto-refresh on initialization
  }

  @override
  void onClose() {
    messageController.dispose();
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  // Load current user
  Future<void> loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserProfile();
      currentUser.value = user;
    } catch (e) {
      _showErrorSnackbar('Failed to load user profile: ${e.toString()}');
    }
  }

  // Load user's chats
  void loadUserChats() {
    try {
      _chatsSubscription?.cancel();
      _chatsSubscription = _chatService.getUserChats().listen((chats) {
        userChats.assignAll(chats);
      }, onError: (e) {
        _showErrorSnackbar('Failed to load chats: ${e.toString()}');
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load chats: ${e.toString()}');
    }
  }

  // Load unread chats count
  void loadUnreadChatsCount() {
    try {
      _unreadCountSubscription?.cancel();
      _unreadCountSubscription = _chatService.getUnreadChatsCount().listen((count) {
        unreadChatsCount.value = count;
      }, onError: (e) {
        // Silent fail for unread count
      });
    } catch (e) {
      // Silent fail for unread count
    }
  }

  // Create or get chat
  Future<String?> createOrGetChat({
    required String carId,
    required String sellerId,
    required String carTitle,
  }) async {
    try {
      final chatId = await _chatService.createOrGetChat(
        carId: carId,
        sellerId: sellerId,
        carTitle: carTitle,
      );
      return chatId;
    } catch (e) {
      _showErrorSnackbar('Failed to create chat: ${e.toString()}');
      return null;
    }
  }

  // Open chat
  Future<void> openChat(String chatId) async {
    try {
      isLoading.value = true;
      
      // Get chat details
      final chat = await _chatService.getChatById(chatId);
      currentChat.value = chat;
      
      // Load messages
      _messagesSubscription?.cancel();
      _messagesSubscription = _chatService.getChatMessages(chatId).listen((messages) {
        currentChatMessages.assignAll(messages);
      }, onError: (e) {
        _showErrorSnackbar('Failed to load messages: ${e.toString()}');
      });
      
      // Mark messages as read
      await _chatService.markMessagesAsRead(chatId);
      
    } catch (e) {
      _showErrorSnackbar('Failed to open chat: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Send text message
  Future<void> sendMessage() async {
    try {
      if (messageController.text.trim().isEmpty || currentChat.value == null) return;

      isSendingMessage.value = true;
      
      await _chatService.sendMessage(
        chatId: currentChat.value!.id,
        message: messageController.text.trim(),
      );
      
      messageController.clear();
      
    } catch (e) {
      _showErrorSnackbar('Failed to send message: ${e.toString()}');
    } finally {
      isSendingMessage.value = false;
    }
  }

  // Send image message
  Future<void> sendImageMessage() async {
    try {
      if (currentChat.value == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      isSendingMessage.value = true;

      // Upload image
      final imageUrl = await _uploadImage(File(pickedFile.path));
      
      // Send message with image
      await _chatService.sendMessage(
        chatId: currentChat.value!.id,
        message: '📷 Image',
        imageUrl: imageUrl,
      );
      
    } catch (e) {
      _showErrorSnackbar('Failed to send image: ${e.toString()}');
    } finally {
      isSendingMessage.value = false;
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile) async {
    try {
      final user = _chatService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fileName = 'chat_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      if (currentChat.value == null) return;

      // Show confirmation dialog
      final bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await _chatService.deleteMessage(currentChat.value!.id, messageId);
      
      _showSuccessSnackbar('Message deleted');
      
    } catch (e) {
      _showErrorSnackbar('Failed to delete message: ${e.toString()}');
    }
  }

  // Archive chat
  Future<void> archiveChat(String chatId) async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Archive Chat'),
          content: const Text('Are you sure you want to archive this chat?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Archive'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await _chatService.archiveChat(chatId);
      
      _showSuccessSnackbar('Chat archived');
      
      // If this is the current chat, close it
      if (currentChat.value?.id == chatId) {
        currentChat.value = null;
        currentChatMessages.clear();
        Get.back();
      }
      
    } catch (e) {
      _showErrorSnackbar('Failed to archive chat: ${e.toString()}');
    }
  }

  // Get other user in chat
  String getOtherUserName(ChatModel chat) {
    if (currentUser.value?.id == chat.buyerId) {
      return chat.sellerName;
    } else {
      return chat.buyerName;
    }
  }

  // Check if current user is sender of message
  bool isMessageFromCurrentUser(MessageModel message) {
    return message.senderId == currentUser.value?.id;
  }

  // Format message time
  String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  // Format chat last message time
  String formatChatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  // Check if chat has unread messages
  bool hasUnreadMessages(ChatModel chat) {
    return chat.unreadBy.contains(currentUser.value?.id);
  }

  // Get chat subtitle (last message preview)
  String getChatSubtitle(ChatModel chat) {
    if (chat.lastMessage.isEmpty) {
      return 'No messages yet';
    }
    
    String prefix = '';
    if (chat.lastMessageSender == currentUser.value?.id) {
      prefix = 'You: ';
    } else if (chat.lastMessageSender == 'system') {
      prefix = '';
    }
    
    return '$prefix${chat.lastMessage}';
  }

  // Search chats
  List<ChatModel> searchChats(String query) {
    if (query.trim().isEmpty) return userChats;
    
    return userChats.where((chat) {
      final otherUserName = getOtherUserName(chat).toLowerCase();
      final carTitle = chat.carTitle.toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return otherUserName.contains(searchQuery) || 
             carTitle.contains(searchQuery);
    }).toList();
  }

  // Close current chat
  void closeCurrentChat() {
    currentChat.value = null;
    currentChatMessages.clear();
    _messagesSubscription?.cancel();
  }

  // Toggle auto-refresh functionality
  void toggleAutoRefresh() {
    autoRefreshEnabled.value = !autoRefreshEnabled.value;
    
    if (autoRefreshEnabled.value) {
      _startAutoRefresh();
    } else {
      _autoRefreshTimer?.cancel();
    }
  }
  
  // Start auto-refresh timer
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refreshCurrentChat();
    });
  }
  
  // Refresh current chat automatically
  void refreshCurrentChat() {
    if (currentChat.value != null) {
      // Mark messages as read
      _chatService.markMessagesAsRead(currentChat.value!.id);
      
      // No need to manually refresh messages as they are already being streamed
      // through the _messagesSubscription in openChat() method
    }
  }
  
  // Helper methods
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}
