import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  // Singleton — only one instance exists in the whole app
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convenience getter: who is logged in right now?
  String get currentUserId => _auth.currentUser!.uid;

  // ─────────────────────────────────────────────
  // 1. Get or create a chat between two users
  //    Call this when starting a conversation
  // ─────────────────────────────────────────────
  Future<String> getOrCreateChat({
    required String otherUserId,
    String? createdFrom,  // pass "job_application" or "saved_profile" later
    String? sourceId,     // pass jobId or savedProfileId later
  }) async {
    // Check if a chat already exists between these two users
    final existing = await _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id; // Chat already exists, return its ID
      }
    }

    // No existing chat — create a new one
    final newChat = await _db.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdFrom': createdFrom,   // null for now, filled later
      'sourceId': sourceId,         // null for now, filled later
    });

    return newChat.id;
  }

  // ─────────────────────────────────────────────
  // 2. Send a message
  // ─────────────────────────────────────────────
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String type = 'text',
  }) async {
    final message = MessageModel(
      id: '',
      senderId: currentUserId,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      deleted: false,
    );

    // Add message to subcollection
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    // Update the chat's last message preview
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': type == 'text' ? text : '📎 Attachment',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // 3. Real-time stream of messages in a chat
  //    UI listens to this — auto-updates on new messages
  // ─────────────────────────────────────────────
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromDoc(doc)).toList());
  }

  // ─────────────────────────────────────────────
  // 4. Real-time stream of all chats for current user
  //    ChatScreen listens to this
  // ─────────────────────────────────────────────
  Stream<List<ChatModel>> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatModel.fromDoc(doc)).toList());
  }

  // ─────────────────────────────────────────────
  // 5. Mark messages as read
  // ─────────────────────────────────────────────
  Future<void> markMessagesAsRead(String chatId) async {
    final unread = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    final batch = _db.batch(); // batch = do multiple writes at once efficiently
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // 6. Soft-delete a message (just marks deleted: true)
  // ─────────────────────────────────────────────
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'deleted': true});
  }
}