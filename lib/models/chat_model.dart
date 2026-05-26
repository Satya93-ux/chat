import 'user_model.dart';

class ChatModel {
  final UserModel contactUser;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatModel({
    required this.contactUser,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  ChatModel copyWith({
    UserModel? contactUser,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatModel(
      contactUser: contactUser ?? this.contactUser,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
