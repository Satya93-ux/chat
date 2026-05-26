import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String statusId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String? imageUrl;
  final String text;
  final DateTime createdAt;
  final String? bgColor; // For text-only statuses

  StatusModel({
    required this.statusId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    this.imageUrl,
    required this.text,
    required this.createdAt,
    this.bgColor,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      imageUrl: map['imageUrl'],
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      bgColor: map['bgColor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'imageUrl': imageUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'bgColor': bgColor,
    };
  }
}
