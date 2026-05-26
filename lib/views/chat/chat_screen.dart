import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/controllers/auth_controller.dart';

class ChatScreen extends StatefulWidget {
  final UserModel contact;
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatController = Get.find<ChatController>();
    chatController.sendMessage(
      contactId: widget.contact.uid,
      content: text,
      type: MessageType.text,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendImageAttachment() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        if (mounted) {
          final chatController = Get.find<ChatController>();
          // Simulate sending a visual attachment
          chatController.sendMessage(
            contactId: widget.contact.uid,
            content: picked.path, // In demo mode, FileImage(picked.path) is rendered
            type: MessageType.image,
          );
          _scrollToBottom();
        }
      }
    } catch (e) {
      Get.snackbar("Error Picking Attachment", e.toString());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Since list is reversed, 0.0 is the bottom!
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            // Contact image
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: widget.contact.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.contact.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.contact.photoUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Name & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.contact.isOnline 
                              ? theme.colorScheme.secondary 
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.contact.isOnline ? "Online" : "Offline",
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {
              chatController.makeCall(contact: widget.contact, isVideo: true);
              Get.snackbar(
                "Video Call",
                "Calling ${widget.contact.name}... 🎥",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Theme.of(context).colorScheme.primary,
                colorText: Colors.white,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded),
            onPressed: () {
              chatController.makeCall(contact: widget.contact, isVideo: false);
              Get.snackbar(
                "Voice Call",
                "Calling ${widget.contact.name}... 📞",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Theme.of(context).colorScheme.primary,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message Thread
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? theme.colorScheme.background 
                    : const Color(0xFFF1F5F9), // Custom light backdrop color
              ),
              child: StreamBuilder<List<MessageModel>>(
                stream: chatController.getMessagesStream(widget.contact.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];
                  
                  // Sort descending so the latest message is index 0 for inverted ListView
                  final reversedMessages = messages.reversed.toList();

                  if (reversedMessages.isEmpty) {
                    return Center(
                      child: Text(
                        "No messages yet. Say hello! 👋",
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Auto handles anchor-to-bottom and new bubble entries
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: reversedMessages.length,
                    itemBuilder: (context, index) {
                      final message = reversedMessages[index];
                      final isSender = message.senderId == authController.currentUser?.uid;
                      
                      return _buildMessageBubble(context, message, isSender, theme);
                    },
                  );
                },
              ),
            ),
          ),
          
          // Custom Bottom Send Bar
          _buildInputBar(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, 
    MessageModel message, 
    bool isSender, 
    ThemeData theme,
  ) {
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);
    final borderRad = isSender 
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isSender 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surface,
          borderRadius: borderRad,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bubble Content
            if (message.type == MessageType.text)
              Text(
                message.content,
                style: TextStyle(
                  color: isSender ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.3,
                ),
              )
            else if (message.type == MessageType.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: message.content.startsWith('http')
                    ? Image.network(message.content)
                    : Image.file(
                        File(message.content),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_rounded, size: 40),
                          );
                        },
                      ),
              ),
            
            const SizedBox(height: 6),
            
            // Meta Row (Time & Receipts)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isSender ? Colors.white60 : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                if (isSender) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.isRead ? theme.colorScheme.secondary : Colors.white60,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji trigger
            IconButton(
              icon: Icon(Icons.emoji_emotions_outlined, color: theme.colorScheme.primary),
              onPressed: () {
                Get.snackbar(
                  "Emoji Keyboard",
                  "Simulating Emoji keyboard picker popup! 😊🚀",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: theme.colorScheme.primary,
                  colorText: Colors.white,
                );
              },
            ),
            
            // Text Input field
            Expanded(
              child: TextFormField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            // Attachment trigger
            IconButton(
              icon: Icon(Icons.attach_file_rounded, color: theme.colorScheme.primary),
              onPressed: _sendImageAttachment,
            ),
            
            const SizedBox(width: 4),
            
            // Send / Mic button
            AnimatedRotation(
              turns: _isTyping ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton.small(
                heroTag: "chat_send_fab",
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 0,
                onPressed: _sendMessage,
                child: Icon(_isTyping ? Icons.send_rounded : Icons.mic_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
