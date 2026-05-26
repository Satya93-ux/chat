import 'dart:io';
import 'package:get/get.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/chat_model.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/models/call_model.dart';
import 'package:chat/services/firebase_service.dart';
import 'package:chat/services/mock_data_service.dart';
import 'package:chat/controllers/auth_controller.dart';

class ChatController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final MockDataService _mockDataService = MockDataService();

  final RxBool _isDemoMode = true.obs;
  bool get isDemoMode => _isDemoMode.value;

  void updateMode(bool demoMode) {
    _isDemoMode.value = demoMode;
  }

  // --- CHATS LIST ---
  
  Stream<List<ChatModel>> getChatsStream() {
    if (isDemoMode) {
      return _mockDataService.getChatsListStream();
    } else {
      return _firebaseService.getActiveChatsStream();
    }
  }

  // --- MESSAGES STREAM ---

  Stream<List<MessageModel>> getMessagesStream(String contactId) {
    if (isDemoMode) {
      return _mockDataService.getChatStream(contactId);
    } else {
      return _firebaseService.getMessagesStream(contactId);
    }
  }

  // --- SEND MESSAGE ---

  Future<void> sendMessage({
    required String contactId,
    required String content,
    required MessageType type,
  }) async {
    if (isDemoMode) {
      _mockDataService.sendMessage(contactId, content, type);
    } else {
      await _firebaseService.sendChatMessage(contactId, content, type);
    }
  }

  // --- MARK AS READ ---

  void markAsRead(String contactId) {
    if (isDemoMode) {
      _mockDataService.markAsRead(contactId);
    }
  }

  // --- STORIES / STATUS ---

  Stream<List<StatusModel>> getStatusesStream() {
    if (isDemoMode) {
      return _mockDataService.getStatusesListStream();
    } else {
      return _firebaseService.getStatusesStream();
    }
  }

  Future<void> postStatus({
    required String text,
    String? imageUrl,
    String? bgColor,
  }) async {
    if (isDemoMode) {
      _mockDataService.addStatus(text, imageUrl, bgColor);
      update(); 
    } else {
      await _firebaseService.postStatus(text, imageUrl, bgColor);
    }
  }

  Future<void> postImageStatus({
    required String localImagePath,
    required String text,
  }) async {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser;
    if (currentUser == null) return;

    if (isDemoMode) {
      _mockDataService.addStatus(text, localImagePath, null);
      update();
    } else {
      final file = File(localImagePath);
      final path = 'statuses/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageUrl = await _firebaseService.uploadImage(file, path);
      await _firebaseService.postStatus(text, imageUrl, null);
    }
  }

  // --- CONTACTS LIST ---

  Stream<List<UserModel>> getAvailableContactsStream() {
    if (isDemoMode) {
      // In demo mode, return list of mock users excluding current user
      final currentUid = Get.find<AuthController>().currentUser?.uid;
      return Stream.value(_mockDataService.mockUsers.where((u) => u.uid != currentUid).toList());
    } else {
      return _firebaseService.getAvailableContacts();
    }
  }

  // --- CALL LOGS ---

  Stream<List<CallModel>> getCallLogsStream() {
    if (isDemoMode) {
      return _mockDataService.getCallsListStream();
    } else {
      return _firebaseService.getCallLogsStream();
    }
  }

  Future<void> makeCall({
    required UserModel contact,
    required bool isVideo,
  }) async {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser;
    if (currentUser == null) return;

    if (isDemoMode) {
      _mockDataService.addCallLog(
        caller: currentUser,
        receiver: contact,
        isVideo: isVideo,
      );
    } else {
      await _firebaseService.createCallLog(
        caller: currentUser,
        receiver: contact,
        isVideo: isVideo,
      );
    }
  }
}

// Helper extension to seed initial values to dynamic streams
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initialValue) async* {
    yield initialValue;
    yield* this;
  }
}
