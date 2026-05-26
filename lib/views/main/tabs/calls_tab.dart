import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat/controllers/chat_controller.dart';
import 'package:chat/models/call_model.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calls"),
      ),
      body: StreamBuilder<List<CallModel>>(
        stream: _callsStream,
        builder: (context, snapshot) {
          // Loading State
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

          // Empty State
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
                      image: DecorationImage(
                        image: NetworkImage(call.hasDialed ? call.receiverPhotoUrl : call.callerPhotoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
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
                      Get.snackbar(
                        "Placing Call",
                        "Calling ${call.hasDialed ? call.receiverName : call.callerName}... 📞",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: theme.colorScheme.primary,
                        colorText: Colors.white,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
