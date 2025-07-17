import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.put(ChatController());

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.grey.shade200,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.userChats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start browsing cars to chat with sellers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewPadding.bottom + 70,
          ),
          itemCount: controller.userChats.length,
          itemBuilder: (context, index) {
            final chat = controller.userChats[index];
            final isUnread = chat.unreadBy.contains(controller.currentUser.value?.id);
            final otherUserName = controller.currentUser.value?.id == chat.buyerId 
                ? chat.sellerName 
                : chat.buyerName;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue,
                  child: Text(
                    otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUserName,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.carTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessage.isNotEmpty ? chat.lastMessage : 'No messages',
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Text(
                  _formatTimestamp(chat.lastMessageTime.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                onTap: () async {
                  try {
                    await Get.to(() => ChatScreen(
                      chatId: chat.id,
                      sellerName: otherUserName,
                    ));
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Failed to open chat: ${e.toString()}',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
            );
          },
        );
      }),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
