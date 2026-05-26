import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:chat/models/user_model.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/models/chat_model.dart';
import 'package:chat/models/call_model.dart';
import 'package:chat/firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isFirebaseConfigured = false;
  bool get isFirebaseConfigured => _isFirebaseConfigured;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseConfigured = true;
      print("Firebase successfully initialized! 🎉");
    } catch (e) {
      _isFirebaseConfigured = false;
      print("Firebase initialization failed/skipped: $e");
      print("Using high-fidelity Mock fallback mode. Add google-services.json/GoogleService-Info.plist to enable live Firebase.");
    }
  }

  // --- AUTH OPERATIONS ---
  
  User? get currentFirebaseUser => _isFirebaseConfigured ? _auth.currentUser : null;

  Future<UserCredential?> signUp(String email, String password, String name) async {
    if (!_isFirebaseConfigured) return null;
    
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Create user doc in Firestore
        final newUser = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          photoUrl: '', // Will be updated if user uploads one
          lastSeen: DateTime.now(),
          isOnline: true,
        );
        await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    if (!_isFirebaseConfigured) return null;
    
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await setUserOnlineStatus(credential.user!.uid, true);
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_isFirebaseConfigured) return;
    
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await setUserOnlineStatus(uid, false);
      }
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isFirebaseConfigured) return;
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // --- USER PROFILE & STATUS ---

  Future<UserModel?> getUserDetails(String uid) async {
    if (!_isFirebaseConfigured) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
    return null;
  }

  Future<void> updateBio(String uid, String newBio) async {
    if (!_isFirebaseConfigured) return;
    try {
      await _firestore.collection('users').doc(uid).update({'bio': newBio});
    } catch (e) {
      print("Error updating bio: $e");
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    if (!_isFirebaseConfigured) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': user.name,
        'bio': user.bio,
        'photoUrl': user.photoUrl,
      });
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }

  Future<void> setUserOnlineStatus(String uid, bool isOnline) async {
    if (!_isFirebaseConfigured) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating online status: $e");
    }
  }

  // --- STORAGE OPERATIONS ---

  Future<String> uploadImage(File file, String path) async {
    if (!_isFirebaseConfigured) return '';
    final bucketName = 'media';
    try {
      final client = sb.Supabase.instance.client;
      final cleanPath = path.replaceAll(' ', '_');
      
      // Upload using Supabase Storage
      await client.storage.from(bucketName).upload(
        cleanPath,
        file,
        fileOptions: const sb.FileOptions(cacheControl: '3600', upsert: true),
      );
      
      // Get and return the public URL
      final publicUrl = client.storage.from(bucketName).getPublicUrl(cleanPath);
      return publicUrl;
    } catch (e) {
      print("Error uploading to Supabase Storage: $e");
      rethrow;
    }
  }

  // --- FIRESTORE REAL-TIME CHAT ---

  Stream<List<UserModel>> getAvailableContacts() {
    if (!_isFirebaseConfigured) return const Stream.empty();
    
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => user.uid != _auth.currentUser?.uid)
          .toList();
    });
  }

  Stream<List<ChatModel>> getActiveChatsStream() {
    if (!_isFirebaseConfigured || _auth.currentUser == null) return const Stream.empty();
    
    final currentUid = _auth.currentUser!.uid;
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ChatModel> activeChats = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            final contactId = participants.firstWhere((id) => id != currentUid, orElse: () => '');
            if (contactId.isEmpty) continue;
            
            final contactUser = await getUserDetails(contactId);
            if (contactUser == null) continue;
            
            final lastMessage = data['lastMessage'] ?? '';
            final timestampVal = data['lastMessageTime'];
            DateTime lastMessageTime = DateTime.now();
            if (timestampVal is Timestamp) {
              lastMessageTime = timestampVal.toDate();
            }
            
            final unreadSnapshot = await _firestore
                .collection('chats')
                .doc(doc.id)
                .collection('messages')
                .where('senderId', isEqualTo: contactId)
                .where('isRead', isEqualTo: false)
                .get();
            final unreadCount = unreadSnapshot.docs.length;

            activeChats.add(
              ChatModel(
                contactUser: contactUser,
                lastMessage: lastMessage,
                lastMessageTime: lastMessageTime,
                unreadCount: unreadCount,
              ),
            );
          }
          activeChats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return activeChats;
        });
  }

  Stream<List<MessageModel>> getMessagesStream(String contactId) {
    if (!_isFirebaseConfigured) return const Stream.empty();
    
    final currentUid = _auth.currentUser!.uid;
    final chatRoomId = getChatRoomId(currentUid, contactId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> sendChatMessage(String contactId, String content, MessageType type) async {
    if (!_isFirebaseConfigured) return;
    
    final currentUid = _auth.currentUser!.uid;
    final chatRoomId = getChatRoomId(currentUid, contactId);
    
    final messageId = _firestore.collection('chats').doc(chatRoomId).collection('messages').doc().id;
    
    String finalContent = content;
    if (type == MessageType.image && !content.startsWith('http')) {
      try {
        final file = File(content);
        final path = 'chats/${chatRoomId}_$messageId.jpg';
        finalContent = await uploadImage(file, path);
      } catch (e) {
        print("Chat attachment upload failed, sending local path: $e");
      }
    }

    final newMessage = MessageModel(
      messageId: messageId,
      senderId: currentUid,
      receiverId: contactId,
      content: finalContent,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Save message
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .set(newMessage.toMap());

    // Update conversation metadata for both users
    final conversationMeta = {
      'lastMessage': type == MessageType.text ? finalContent : '[Media Attachment]',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'senderId': currentUid,
      'participants': [currentUid, contactId],
    };
    
    await _firestore.collection('chats').doc(chatRoomId).set(conversationMeta, SetOptions(merge: true));
  }

  String getChatRoomId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }

  // --- SOCIAL STORIES / STATUS ---

  Stream<List<StatusModel>> getStatusesStream() {
    if (!_isFirebaseConfigured) return const Stream.empty();
    
    return _firestore
        .collection('statuses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StatusModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> postStatus(String text, String? imageUrl, String? bgColor) async {
    if (!_isFirebaseConfigured || _auth.currentUser == null) return;

    final currentUid = _auth.currentUser!.uid;
    final fbUser = _auth.currentUser!;
    
    // Fetch details; if blocked or empty, fallback gracefully
    final userDetails = await getUserDetails(currentUid);
    final String userName = userDetails?.name ?? fbUser.displayName ?? fbUser.email?.split('@')[0].toUpperCase() ?? 'USER';
    final String userPhotoUrl = userDetails?.photoUrl ?? fbUser.photoURL ?? '';

    final statusId = _firestore.collection('statuses').doc().id;
    final newStatus = StatusModel(
      statusId: statusId,
      userId: currentUid,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: text,
      imageUrl: imageUrl,
      bgColor: bgColor,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.collection('statuses').doc(statusId).set(newStatus.toMap());
    } catch (e) {
      print("Error posting status update to Firestore: $e");
      if (e.toString().contains("permission-denied")) {
        print("Firestore rules blocked writing to /statuses. Please update rules to allow authenticated writes.");
      } else {
        rethrow;
      }
    }
  }

  // --- CALL LOGS ---

  Stream<List<CallModel>> getCallLogsStream() {
    if (!_isFirebaseConfigured || _auth.currentUser == null) return const Stream.empty();
    
    final currentUid = _auth.currentUser!.uid;
    return _firestore
        .collection('calls')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
          final callsList = snapshot.docs.map((doc) {
            final data = doc.data();
            final timestampVal = data['timestamp'];
            DateTime timestamp = DateTime.now();
            if (timestampVal is Timestamp) {
              timestamp = timestampVal.toDate();
            }
            return CallModel(
              callId: doc.id,
              callerName: data['callerName'] ?? '',
              callerPhotoUrl: data['callerPhotoUrl'] ?? '',
              receiverName: data['receiverName'] ?? '',
              receiverPhotoUrl: data['receiverPhotoUrl'] ?? '',
              timestamp: timestamp,
              hasDialed: data['callerId'] == currentUid,
              isMissed: data['isMissed'] ?? false,
              isVideo: data['isVideo'] ?? false,
            );
          }).toList();
          callsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return callsList;
        });
  }

  Future<void> createCallLog({
    required UserModel caller,
    required UserModel receiver,
    required bool isVideo,
  }) async {
    if (!_isFirebaseConfigured) return;
    
    final callId = _firestore.collection('calls').doc().id;
    await _firestore.collection('calls').doc(callId).set({
      'callerId': caller.uid,
      'callerName': caller.name,
      'callerPhotoUrl': caller.photoUrl,
      'receiverId': receiver.uid,
      'receiverName': receiver.name,
      'receiverPhotoUrl': receiver.photoUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'participants': [caller.uid, receiver.uid],
      'isMissed': false,
      'isVideo': isVideo,
    });
  }

  Future<void> saveNewContactToFirestore(UserModel user) async {
    if (!_isFirebaseConfigured) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set(user.toMap());
      }
    } catch (e) {
      print("Error saving new contact to Firestore: $e");
      if (e.toString().contains("permission-denied")) {
        // Log gracefully and proceed: allows chat thread to start instantly 
        // even if the Firebase rule has not been updated yet.
        print("Firestore rules blocked writing contact profile to /users. Proceeding to chat room.");
      } else {
        rethrow;
      }
    }
  }
}
