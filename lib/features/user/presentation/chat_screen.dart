import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String sellerName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.sellerName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChatController());
    
    // Open chat after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.openChat(widget.chatId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    controller.closeCurrentChat();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Wait for messages to load then scroll
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // In a reversed ListView, 0 is the bottom (newest messages)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.sellerName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.currentChatMessages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a conversation!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: controller.currentChatMessages.length,
                itemBuilder: (context, index) {
                  final message = controller.currentChatMessages[index];
                  final isCurrentUser = controller.isMessageFromCurrentUser(message);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isCurrentUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isCurrentUser) ...[
                          CircleAvatar(
                            backgroundColor: Colors.blue[300],
                            child: Text(
                              message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.blue[500] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: message.messageType == MessageType.text
                                ? Text(
                                    message.message,
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.white : Colors.black87,
                                    ),
                                  )
                                : message.messageType == MessageType.image
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (message.imageUrl != null)
                                            GestureDetector(
                                              onTap: () {
                                                // Show full image preview
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => Scaffold(
                                                      backgroundColor: Colors.black87,
                                                      appBar: AppBar(
                                                        backgroundColor: Colors.black,
                                                        foregroundColor: Colors.white,
                                                        title: const Text('Image Preview'),
                                                      ),
                                                      body: Center(
                                                        child: InteractiveViewer(
                                                          minScale: 0.5,
                                                          maxScale: 4.0,
                                                          child: Image.network(
                                                            message.imageUrl!,
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  message.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  width: 200,
                                                  loadingBuilder: (context, child, progress) {
                                                    if (progress == null) return child;
                                                    return Container(
                                                      width: 200,
                                                      height: 150,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 200,
                                                      height: 150,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.error_outline,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      )
                                    : Text(
                                        message.message,
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.blue[700],
                            child: Text(
                              controller.currentUser.value?.fullName.isNotEmpty == true 
                                  ? controller.currentUser.value!.fullName[0].toUpperCase() 
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image picker button
                IconButton(
                  onPressed: controller.isSendingMessage.value
                      ? null
                      : () => controller.sendImageMessage(),
                  icon: const Icon(Icons.image, color: Colors.grey),
                ),
                Expanded(
                  child: TextField(
                    controller: controller.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        controller.sendMessage();
                        _scrollToBottom();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => FloatingActionButton(
                  onPressed: controller.isSendingMessage.value
                      ? null
                      : () {
                          controller.sendMessage();
                          _scrollToBottom();
                        },
                  backgroundColor: Colors.blue,
                  mini: true,
                  child: controller.isSendingMessage.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
