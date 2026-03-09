import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;  // [uid1, uid2]
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? createdFrom;  // "job_application", "saved_profile", or null
  final String? sourceId;     // jobId or savedProfileId — null for now

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageTime,
    this.createdFrom,
    this.sourceId,
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      createdFrom: data['createdFrom'],
      sourceId: data['sourceId'],
    );
  }
}