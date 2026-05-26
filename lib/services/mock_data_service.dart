import 'dart:async';
import 'package:chat/models/user_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/chat_model.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/models/call_model.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    _initMockData();
  }

  late UserModel currentUser;
  final List<UserModel> mockUsers = [];
  final Map<String, List<MessageModel>> mockChats = {};
  final List<StatusModel> mockStatuses = [];
  final List<CallModel> mockCalls = [];

  final _chatStreamControllers = <String, StreamController<List<MessageModel>>>{};
  final _chatsListStreamController = StreamController<List<ChatModel>>.broadcast();
  final _callsListStreamController = StreamController<List<CallModel>>.broadcast();
  final _statusesListStreamController = StreamController<List<StatusModel>>.broadcast();

  Stream<List<MessageModel>> getChatStream(String contactId) {
    if (!_chatStreamControllers.containsKey(contactId)) {
      _chatStreamControllers[contactId] = StreamController<List<MessageModel>>.broadcast();
    }
    // Seed initial state
    _chatStreamControllers[contactId]!.add(mockChats[contactId] ?? []);
    return _chatStreamControllers[contactId]!.stream;
  }

  Stream<List<ChatModel>> getChatsListStream() {
    _emitChatsList();
    return _chatsListStreamController.stream;
  }

  Stream<List<CallModel>> getCallsListStream() {
    _emitCallsList();
    return _callsListStreamController.stream;
  }

  Stream<List<StatusModel>> getStatusesListStream() {
    _emitStatusesList();
    return _statusesListStreamController.stream;
  }

  void _emitChatsList() {
    final list = mockUsers.map((user) {
      final messages = mockChats[user.uid] ?? [];
      final lastMsg = messages.isNotEmpty ? messages.last.content : "Tap to start chatting";
      final lastTime = messages.isNotEmpty ? messages.last.timestamp : DateTime.now().subtract(const Duration(hours: 1));
      
      // Count unread
      final unread = messages.where((m) => !m.isRead && m.senderId == user.uid).length;

      return ChatModel(
        contactUser: user,
        lastMessage: lastMsg,
        lastMessageTime: lastTime,
        unreadCount: unread,
      );
    }).toList();
    
    // Sort by last message time
    list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    _chatsListStreamController.add(list);
  }

  void _emitCallsList() {
    _callsListStreamController.add(List.from(mockCalls));
  }

  void _emitStatusesList() {
    _statusesListStreamController.add(List.from(mockStatuses));
  }

  void addMockUser(UserModel user) {
    if (!mockUsers.any((u) => u.uid == user.uid)) {
      mockUsers.add(user);
      _emitChatsList();
    }
  }

  void sendMessage(String contactId, String content, MessageType type) {
    final newMsg = MessageModel(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser.uid,
      receiverId: contactId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: true,
    );

    if (!mockChats.containsKey(contactId)) {
      mockChats[contactId] = [];
    }
    
    mockChats[contactId]!.add(newMsg);
    _chatStreamControllers[contactId]?.add(mockChats[contactId]!);
    _emitChatsList();

    // Trigger an elegant auto-response simulation
    _triggerAutoReply(contactId);
  }

  void _triggerAutoReply(String contactId) {
    final contactIndex = mockUsers.indexWhere((u) => u.uid == contactId);
    if (contactIndex == -1) return;
    final contact = mockUsers[contactIndex];
    
    // Simulate active typing delay
    Future.delayed(const Duration(seconds: 2), () {
      final responses = [
        "That sounds amazing! Tell me more about it.",
        "Hey! Got your message. I'm a bit busy right now, but I'll catch up with you later tonight! 🙌🏼",
        "Absolutely! Let's schedule a call tomorrow.",
        "Wow, that's really clean. I love the smooth Material 3 animations here! 😍",
        "Did you build this using Provider? It feels incredibly fast!",
        "Thanks for the update! Talk to you soon.",
      ];
      
      final replyContent = responses[DateTime.now().millisecondsSinceEpoch % responses.length];
      
      final replyMsg = MessageModel(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: contactId,
        receiverId: currentUser.uid,
        content: replyContent,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
      );

      mockChats[contactId]!.add(replyMsg);
      _chatStreamControllers[contactId]?.add(mockChats[contactId]!);
      _emitChatsList();
    });
  }

  void addStatus(String text, String? imageUrl, String? bgColor) {
    final newStatus = StatusModel(
      statusId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser.uid,
      userName: currentUser.name,
      userPhotoUrl: currentUser.photoUrl,
      text: text,
      imageUrl: imageUrl,
      bgColor: bgColor,
      createdAt: DateTime.now(),
    );
    mockStatuses.insert(0, newStatus);
    _emitStatusesList();
  }

  void addCallLog({
    required UserModel caller,
    required UserModel receiver,
    required bool isVideo,
  }) {
    final newCall = CallModel(
      callId: DateTime.now().millisecondsSinceEpoch.toString(),
      callerName: caller.name,
      callerPhotoUrl: caller.photoUrl,
      receiverName: receiver.name,
      receiverPhotoUrl: receiver.photoUrl,
      timestamp: DateTime.now(),
      hasDialed: caller.uid == currentUser.uid,
      isMissed: false,
      isVideo: isVideo,
    );
    mockCalls.insert(0, newCall);
    _emitCallsList();
  }

  void markAsRead(String contactId) {
    final messages = mockChats[contactId] ?? [];
    bool changed = false;
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].senderId == contactId && !messages[i].isRead) {
        messages[i] = MessageModel(
          messageId: messages[i].messageId,
          senderId: messages[i].senderId,
          receiverId: messages[i].receiverId,
          content: messages[i].content,
          type: messages[i].type,
          timestamp: messages[i].timestamp,
          isRead: true,
        );
        changed = true;
      }
    }
    if (changed) {
      _chatStreamControllers[contactId]?.add(messages);
      _emitChatsList();
    }
  }

  void _initMockData() {
    currentUser = UserModel(
      uid: "current_user_123",
      name: "Alex Mercer",
      email: "alex.mercer@example.com",
      photoUrl: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
      bio: "Crafting beautiful interactive experiences. ✨",
      isOnline: true,
      lastSeen: DateTime.now(),
    );
  }
}
