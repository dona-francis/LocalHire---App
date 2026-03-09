import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String type; // "text", "image", "document", "location"
  final DateTime timestamp;
  final bool isRead;
  final bool deleted;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.deleted,
  });

  // Convert Firestore document → Dart object
  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'text',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      deleted: data['deleted'] ?? false,
    );
  }

  // Convert Dart object → Map to save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(), // Firebase sets the time, not your phone clock
      'isRead': isRead,
      'deleted': deleted,
    };
  }
}