import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? createdFrom;
  final String? sourceId;
  final Map<String, dynamic> unreadCounts;
  final List<String> acceptedBy;
  // ✅ Per-user display info — each uid maps to the OTHER
  // person's name/image as seen by that uid
  // displayNames[myUid] = "the other person's name I see"
  final Map<String, dynamic> displayNames;
  final Map<String, dynamic> displayImages;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastMessageTime,
    this.createdFrom,
    this.sourceId,
    this.unreadCounts = const {},
    this.acceptedBy = const [],
    this.displayNames = const {},
    this.displayImages = const {},
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
      unreadCounts:
          data['unreadCounts'] as Map<String, dynamic>? ?? {},
      acceptedBy:
          List<String>.from(data['acceptedBy'] ?? []),
      displayNames:
          data['displayNames'] as Map<String, dynamic>? ?? {},
      displayImages:
          data['displayImages'] as Map<String, dynamic>? ?? {},
    );
  }

  int unreadFor(String uid) =>
      (unreadCounts[uid] as int?) ?? 0;

  // Get the name THIS uid should see
  // displayNames[myUid] = other person's name
  String nameFor(String uid) =>
      (displayNames[uid] as String?) ?? '';

  //  Get the image THIS uid should see
  String? imageFor(String uid) =>
      displayImages[uid] as String?;

  // Simple and correct — if uid not in acceptedBy = request
  bool isRequestFor(String uid) => !acceptedBy.contains(uid);

  bool get isAccepted => acceptedBy.length >= 2;

  //  Keep backward compat for old docs that
  // still have otherUserName — fallback only
  String get otherUserName => '';
  String? get otherUserImage => null;
}