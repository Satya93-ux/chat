import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chat/models/call_model.dart';
import 'package:chat/models/user_model.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/controllers/auth_controller.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  late final Stream<List<CallModel>> _callsStream;

  @override
  void initState() {
    super.initState();
    _callsStream = Get.find<ChatController>().getCallLogsStream();
  }

  Future<void> _handlePlaceCall(UserModel contact, bool isVideo, ChatController chatController) async {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser;
    if (currentUser == null) return;

    // Request permissions dynamically
    final micPermission = await Permission.microphone.request();
    final cameraPermission = isVideo ? await Permission.camera.request() : PermissionStatus.granted;
    final phonePermission = await Permission.phone.request();

    if (!micPermission.isGranted || !cameraPermission.isGranted || !phonePermission.isGranted) {
      Get.snackbar(
        "Permissions Required",
        "Camera, Microphone, and Phone permissions are necessary to place dynamic audio/video calls! 🎙️📸",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Capture exact phone number
    final number = contact.phoneNumber.isNotEmpty ? contact.phoneNumber : "+1 (555) 019-2834";
    final cleanNumber = number.replaceAll(RegExp(r'\s+'), '');

    // 1. Create a real backend call log entry instantly!
    await chatController.makeCall(
      contact: contact,
      isVideo: isVideo,
    );

    // 2. Launch system dialer natively
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar("Call Error", "Could not invoke native dialer for $number");
      }
    } catch (e) {
      Get.snackbar("Call Error", "Unable to trigger call: $e");
    }
  }

  void _showCallContactSheet(ChatController chatController, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "New Call",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: chatController.getAvailableContactsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final contacts = snapshot.data ?? [];
                    if (contacts.isEmpty) {
                      return const Center(
                        child: Text("No contacts available to call."),
                      );
                    }
                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            backgroundImage: contact.photoUrl.isNotEmpty
                                ? NetworkImage(contact.photoUrl)
                                : null,
                            child: contact.photoUrl.isEmpty
                                ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                                : null,
                          ),
                          title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(contact.phoneNumber.isNotEmpty ? contact.phoneNumber : "No number"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.phone_rounded, color: theme.colorScheme.primary),
                                onPressed: () {
                                  Get.back();
                                  _handlePlaceCall(contact, false, chatController);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.videocam_rounded, color: theme.colorScheme.primary),
                                onPressed: () {
                                  Get.back();
                                  _handlePlaceCall(contact, true, chatController);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calls"),
      ),
      body: StreamBuilder<List<CallModel>>(
        stream: _callsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final calls = snapshot.data ?? [];

          if (calls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_missed_rounded,
                    size: 72,
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No call history",
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your dynamic voice and video call logs will appear here.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      image: (call.hasDialed ? call.receiverPhotoUrl : call.callerPhotoUrl).isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(call.hasDialed ? call.receiverPhotoUrl : call.callerPhotoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (call.hasDialed ? call.receiverPhotoUrl : call.callerPhotoUrl).isEmpty
                        ? Icon(Icons.person_rounded, color: theme.colorScheme.primary)
                        : null,
                  ),
                  title: Text(
                    call.hasDialed ? call.receiverName : call.callerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          call.hasDialed 
                              ? Icons.call_made_rounded 
                              : (call.isMissed ? Icons.call_missed_rounded : Icons.call_received_rounded),
                          size: 16,
                          color: call.isMissed 
                              ? theme.colorScheme.error 
                              : theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(call.timestamp),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      call.isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      final fallbackUser = UserModel(
                        uid: call.hasDialed ? 'receiver' : 'caller',
                        name: call.hasDialed ? call.receiverName : call.callerName,
                        email: '',
                        photoUrl: call.hasDialed ? call.receiverPhotoUrl : call.callerPhotoUrl,
                        lastSeen: DateTime.now(),
                      );
                      _handlePlaceCall(fallbackUser, call.isVideo, chatController);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          heroTag: "fab_calls",
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: () => _showCallContactSheet(chatController, theme),
          child: const Icon(Icons.add_call),
        ),
      ),
    );
  }
}
