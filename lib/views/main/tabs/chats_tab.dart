import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:chat/models/chat_model.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/views/chat/chat_screen.dart';
import 'package:chat/views/chat/contacts_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (today.difference(messageDate).inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatController.getChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No conversations yet",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a friend to start chatting!",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatItem(context, chat, chatController);
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Padding to make it hover beautifully above bottom bar
        child: FloatingActionButton(
          heroTag: "fab_chats",
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: () => Get.to(() => const ContactsScreen()),
          child: const Icon(Icons.chat_rounded),
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, ChatModel chat, ChatController chatController) {
    final theme = Theme.of(context);
    final user = chat.contactUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          // Mark as read in mock mode
          chatController.markAsRead(user.uid);
          Get.to(() => ChatScreen(contact: user));
        },
        leading: Stack(
          children: [
            // User photo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
                image: user.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(user.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.photoUrl.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    )
                  : null,
            ),
            
            // Online status indicator ring
            if (user.isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary, // Emerald green
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: chat.unreadCount > 0 
                  ? theme.colorScheme.onBackground
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Time Stamp
            Text(
              _formatTimestamp(chat.lastMessageTime),
              style: theme.textTheme.labelLarge?.copyWith(
                color: chat.unreadCount > 0 
                    ? theme.colorScheme.primary 
                    : theme.textTheme.labelLarge?.color?.withOpacity(0.6),
                fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 8),
            
            // Unread messages count badge
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: chat.unreadCount > 0
                  ? Container(
                      key: ValueKey("badge_${chat.unreadCount}"),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox(width: 20, height: 20),
            ),
          ],
        ),
      ),
    );
  }
}
