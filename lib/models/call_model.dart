class CallModel {
  final String callId;
  final String callerName;
  final String callerPhotoUrl;
  final String receiverName;
  final String receiverPhotoUrl;
  final DateTime timestamp;
  final bool hasDialed; // Outgoing call
  final bool isMissed;
  final bool isVideo;

  CallModel({
    required this.callId,
    required this.callerName,
    required this.callerPhotoUrl,
    required this.receiverName,
    required this.receiverPhotoUrl,
    required this.timestamp,
    required this.hasDialed,
    required this.isMissed,
    required this.isVideo,
  });
}
