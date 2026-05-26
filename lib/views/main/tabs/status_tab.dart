import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/controllers/auth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class StatusTab extends StatefulWidget {
  const StatusTab({super.key});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  final _textStatusController = TextEditingController();
  final List<String> _bgGradients = [
    "0xFF6366F1", // Indigo
    "0xFF10B981", // Emerald
    "0xFFEC4899", // Pink
    "0xFFF59E0B", // Amber
    "0xFF8B5CF6", // Purple
  ];
  int _selectedBgIndex = 0;
  late final Stream<List<StatusModel>> _statusesStream;

  @override
  void initState() {
    super.initState();
    _statusesStream = Get.find<ChatController>().getStatusesStream();
  }

  @override
  void dispose() {
    _textStatusController.dispose();
    super.dispose();
  }

  void _showTextStatusDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeColor = Color(int.parse(_bgGradients[_selectedBgIndex]));
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Get.back(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.color_lens_rounded, color: Colors.white, size: 28),
                        onPressed: () {
                          setModalState(() {
                            _selectedBgIndex = (_selectedBgIndex + 1) % _bgGradients.length;
                          });
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextField(
                     controller: _textStatusController,
                    maxLines: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Type a status...",
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      foregroundColor: activeColor,
                      child: const Icon(Icons.send_rounded),
                      onPressed: () {
                        if (_textStatusController.text.trim().isNotEmpty) {
                          Get.find<ChatController>().postStatus(
                            text: _textStatusController.text.trim(),
                            bgColor: _bgGradients[_selectedBgIndex],
                          );
                          _textStatusController.clear();
                          Get.back();
                          Get.snackbar(
                            "Status Posted",
                            "Status posted successfully! ✨",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: activeColor,
                            colorText: Colors.white,
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndPostImageStatus() async {
    try {
      final cameraStatus = await Permission.camera.request();
      final photosStatus = await Permission.photos.request();
      
      if (!cameraStatus.isGranted || !photosStatus.isGranted) {
        Get.snackbar(
          "Permissions Required",
          "Camera and Photo Gallery permissions are necessary to capture and upload your status update! 📸✨",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (picked != null) {
        final captionController = TextEditingController();
        final chatController = Get.find<ChatController>();
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Post Status Update"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(picked.path),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: captionController,
                    decoration: const InputDecoration(
                      labelText: "Add a caption...",
                      hintText: "What's on your mind?",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    Get.showOverlay(
                      asyncFunction: () => chatController.postImageStatus(
                        localImagePath: picked.path,
                        text: captionController.text.trim().isEmpty 
                            ? "Status Update ✨" 
                            : captionController.text.trim(),
                      ),
                      loadingWidget: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  child: const Text("Post"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      Get.snackbar("Error Posting Status", e.toString());
    }
  }

  void _viewStatus(StatusModel status) {
    Get.to(
      () => StatusViewerScreen(status: status),
      opaque: false,
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Status updates"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Status card
          StreamBuilder<List<StatusModel>>(
            stream: _statusesStream,
            builder: (context, snapshot) {
              final statuses = snapshot.data ?? [];
              final myStatuses = statuses.where((s) => s.userId == authController.currentUser?.uid).toList();
              final hasStatus = myStatuses.isNotEmpty;
              final latestMyStatus = hasStatus ? myStatuses.first : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: InkWell(
                  onTap: () {
                    if (hasStatus) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.remove_red_eye_rounded),
                                title: const Text("View my status"),
                                onTap: () {
                                  Get.back();
                                  _viewStatus(latestMyStatus!);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.add_photo_alternate_rounded),
                                title: const Text("Post new status update"),
                                onTap: () {
                                  Get.back();
                                  _pickAndPostImageStatus();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      _pickAndPostImageStatus();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: hasStatus ? const EdgeInsets.all(2.5) : null,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: hasStatus
                                  ? Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 2.5,
                                    )
                                  : null,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                image: authController.currentUser?.photoUrl != null && authController.currentUser!.photoUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(authController.currentUser!.photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: authController.currentUser?.photoUrl == null || authController.currentUser!.photoUrl.isEmpty
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 32,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My status",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasStatus ? "Tap to view or add update" : "Tap to add a status update",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              "Recent updates",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<StatusModel>>(
              stream: _statusesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final statuses = snapshot.data ?? [];
                // Filter out current user's statuses from the general feed
                final externalStatuses = statuses.where((s) => s.userId != authController.currentUser?.uid).toList();
                
                if (externalStatuses.isEmpty) {
                  return Center(
                    child: Text(
                      "No recent updates",
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: externalStatuses.length,
                  itemBuilder: (context, index) {
                    final status = externalStatuses[index];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        onTap: () => _viewStatus(status),
                        leading: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: status.userPhotoUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(status.userPhotoUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: status.userPhotoUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                        ),
                        title: Text(
                          status.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('hh:mm a').format(status.createdAt),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "btn_text_status",
            backgroundColor: theme.colorScheme.surfaceVariant,
            foregroundColor: theme.colorScheme.primary,
            onPressed: _showTextStatusDialog,
            child: const Icon(Icons.edit_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "btn_image_status",
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            onPressed: _pickAndPostImageStatus,
            child: const Icon(Icons.camera_alt_rounded),
          ),
        ],
      ),
    );
  }
}

// FULLSCREEN STATUS VIEWER WITH PROGRESS BARS
class StatusViewerScreen extends StatefulWidget {
  final StatusModel status;
  const StatusViewerScreen({super.key, required this.status});

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressController.forward();
    _progressController.addStatusListener((state) {
      if (state == AnimationStatus.completed) {
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final isTextStatus = status.imageUrl == null;
    final textBgColor = status.bgColor != null 
        ? Color(int.parse(status.bgColor!)) 
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background content
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (_) => _progressController.stop(),
              onTapUp: (_) => _progressController.forward(),
              onTapCancel: () => _progressController.forward(),
              onTap: () => Get.back(),
              child: isTextStatus 
                  ? Container(
                      color: textBgColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      alignment: Alignment.center,
                      child: Text(
                        status.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        status.imageUrl!.startsWith('http')
                            ? Image.network(
                                status.imageUrl!,
                                fit: BoxFit.contain,
                              )
                            : Image.file(
                                File(status.imageUrl!),
                                fit: BoxFit.contain,
                              ),
                        // Soft overlay gradient at the bottom for caption readability
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 150,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Caption
                        Positioned(
                          bottom: 48,
                          left: 24,
                          right: 24,
                          child: Text(
                            status.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Header details & Progress indicator
          SafeArea(
            child: Column(
              children: [
                // Animated progress line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(2),
                        minHeight: 3.5,
                      );
                    },
                  ),
                ),
                
                // Profile header info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: status.userPhotoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(status.userPhotoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: status.userPhotoUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            DateFormat('hh:mm a').format(status.createdAt),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
