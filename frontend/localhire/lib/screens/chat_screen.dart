import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import 'message_screen.dart';

class ChatScreen extends StatefulWidget {
  final int initialTab;

  const ChatScreen({super.key, this.initialTab = 0});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();

  late int _tabIndex;
  String searchQuery = "";
  final int maxPinned = 3;
  final Set<String> pinnedChats = {};
  List<ChatModel> _lastKnownChats = [];

  @override
  void initState() {
    super.initState();
    // Honour initialTab passed from notification navigation
    // Tab 0 = All, Tab 1 = Requests (Unread tab removed)
    _tabIndex = widget.initialTab.clamp(0, 1);
  }

  String getOtherUserId(List<String> participants) {
    final currentUid = _chatService.currentUserId;
    return participants.firstWhere(
        (id) => id != currentUid, orElse: () => '');
  }

  void togglePin(String chatId) {
    if (!pinnedChats.contains(chatId) &&
        pinnedChats.length >= maxPinned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You can only pin up to 3 chats.")),
      );
      return;
    }
    setState(() {
      pinnedChats.contains(chatId)
          ? pinnedChats.remove(chatId)
          : pinnedChats.add(chatId);
    });
  }

  void showPinDialog(String chatId) {
    final isPinned = pinnedChats.contains(chatId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPinned ? "Unpin Chat" : "Pin Chat"),
        content: Text(isPinned
            ? "Do you want to unpin this chat?"
            : "Do you want to pin this chat?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              togglePin(chatId);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      // Show HH:MM for today, like WhatsApp
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  List<ChatModel> _sortChats(List<ChatModel> chats) {
    final sorted = [...chats];
    sorted.sort((a, b) {
      final aPinned = pinnedChats.contains(a.id);
      final bPinned = pinnedChats.contains(b.id);
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      final aTime = a.lastMessageTime ?? DateTime(2000);
      final bTime = b.lastMessageTime ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "LocalHire",
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
      ),
      body: Column(
        children: [

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) =>
                  setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search messages...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFE9E9E9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 2-tab toggle: All / Requests ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getUserChats(),
              builder: (context, snapshot) {
                final currentUid = _chatService.currentUserId;
                final allChats =
                    snapshot.data ?? _lastKnownChats;
                final requestCount = allChats
                    .where((c) => c.isRequestFor(currentUid))
                    .length;

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // ── All tab ──
                      _tabButton("All", 0),

                      // ── Requests tab with badge ──
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _tabIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: _tabIndex == 1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Requests",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.w600)),
                                  if (requestCount > 0) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 6,
                                          vertical: 2),
                                      decoration:
                                          const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$requestCount',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Chat list ──
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getUserChats(),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data!.isNotEmpty) {
                  _lastKnownChats = snapshot.data!;
                }

                final allChats = _lastKnownChats;

                if (allChats.isEmpty &&
                    snapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final currentUid = _chatService.currentUserId;

                final requests = allChats
                    .where((c) => c.isRequestFor(currentUid))
                    .toList();
                final accepted = allChats
                    .where((c) => !c.isRequestFor(currentUid))
                    .toList();

                List<ChatModel> displayList;
                String emptyMessage;

                if (_tabIndex == 0) {
                  displayList = accepted;
                  emptyMessage = "No chats yet";
                } else {
                  displayList = requests;
                  emptyMessage = "No chat requests";
                }

                if (displayList.isEmpty &&
                    snapshot.connectionState ==
                        ConnectionState.active) {
                  return Center(
                    child: Text(emptyMessage,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 16)),
                  );
                }

                final sorted = _sortChats(displayList);

                return ListView.builder(
                  key: PageStorageKey('chat_list_$_tabIndex'),
                  itemCount: sorted.length,
                  addAutomaticKeepAlives: true,
                  itemBuilder: (context, index) {
                    final chat = sorted[index];
                    final otherUserId =
                        getOtherUserId(chat.participants);
                    final isPinned =
                        pinnedChats.contains(chat.id);
                    final unreadCount =
                        chat.unreadFor(currentUid);
                    final isRequest =
                        chat.isRequestFor(currentUid);

                    return _ChatItem(
                      key: ValueKey(chat.id),
                      chat: chat,
                      otherUserId: otherUserId,
                      currentUid: currentUid,
                      isPinned: isPinned,
                      searchQuery: searchQuery,
                      formatTime: _formatTime,
                      unreadCount: unreadCount,
                      isRequest: isRequest,
                      onLongPress: () =>
                          showPinDialog(chat.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _tabIndex == index
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ChatItem — individual chat row
// ─────────────────────────────────────────────
class _ChatItem extends StatefulWidget {
  final ChatModel chat;
  final String otherUserId;
  final String currentUid;
  final bool isPinned;
  final String searchQuery;
  final String Function(DateTime?) formatTime;
  final VoidCallback onLongPress;
  final int unreadCount;
  final bool isRequest;

  const _ChatItem({
    super.key,
    required this.chat,
    required this.otherUserId,
    required this.currentUid,
    required this.isPinned,
    required this.searchQuery,
    required this.formatTime,
    required this.onLongPress,
    required this.unreadCount,
    required this.isRequest,
  });

  @override
  State<_ChatItem> createState() => _ChatItemState();
}

class _ChatItemState extends State<_ChatItem>
    with AutomaticKeepAliveClientMixin {

  static final Map<String, Map<String, String?>> _userCache = {};

  @override
  bool get wantKeepAlive => true;

  late String _name;
  late String? _image;
  bool _needsFetch = false;

  @override
  void initState() {
    super.initState();
    _resolveUser();
  }

  @override
  void didUpdateWidget(covariant _ChatItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newName = widget.chat.nameFor(widget.currentUid);
    final oldName = oldWidget.chat.nameFor(widget.currentUid);
    if (oldName.isEmpty && newName.isNotEmpty) {
      setState(() {
        _name = newName;
        _image = widget.chat.imageFor(widget.currentUid);
        _needsFetch = false;
        _userCache[widget.otherUserId] = {
          'name': _name,
          'profileImage': _image,
        };
      });
    }
  }

  void _resolveUser() {
    final name = widget.chat.nameFor(widget.currentUid);
    final image = widget.chat.imageFor(widget.currentUid);

    if (name.isNotEmpty) {
      _name = name;
      _image = image;
      _userCache[widget.otherUserId] = {
        'name': _name,
        'profileImage': _image,
      };
      return;
    }

    if (_userCache.containsKey(widget.otherUserId)) {
      final c = _userCache[widget.otherUserId]!;
      _name = c['name'] ?? '';
      _image = c['profileImage'];
      return;
    }

    _name = '';
    _image = null;
    _needsFetch = true;
    _fetchAndBackfill();
  }

  Future<void> _fetchAndBackfill() async {
    if (widget.otherUserId.isEmpty) return;
    try {
      final otherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      final otherName =
          otherDoc.data()?['name'] as String? ?? '';
      final otherImage =
          otherDoc.data()?['profileImage'] as String?;

      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUid)
          .get();

      final myName = myDoc.data()?['name'] as String? ?? '';
      final myImage = myDoc.data()?['profileImage'] as String?;

      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .set(
            {
              'displayNames': {
                widget.currentUid: otherName,
                widget.otherUserId: myName,
              },
              'displayImages': {
                widget.currentUid: otherImage,
                widget.otherUserId: myImage,
              },
            },
            SetOptions(merge: true),
          )
          .catchError((_) {});

      _userCache[widget.otherUserId] = {
        'name': otherName,
        'profileImage': otherImage,
      };

      if (mounted) {
        setState(() {
          _name = otherName;
          _image = otherImage;
          _needsFetch = false;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.searchQuery.isNotEmpty &&
        !_needsFetch &&
        !_name
            .toLowerCase()
            .contains(widget.searchQuery.toLowerCase())) {
      return const SizedBox.shrink();
    }

    final initial =
        _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    final hasUnread = widget.unreadCount > 0 && !widget.isRequest;

    return GestureDetector(
      onLongPress:
          widget.isRequest ? null : widget.onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageScreen(
              chatId: widget.chat.id,
              otherUserId: widget.otherUserId,
              userName: _name.isEmpty ? 'User' : _name,
              userProfileImage: _image,
              isRequest: widget.isRequest,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isRequest
              ? const Color(0xFFEDE8F5)
              : const Color(0xFFECE6D8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [

            // ── Avatar ──
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _image != null
                      ? NetworkImage(_image!)
                      : null,
                  child: _image == null
                      ? Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                if (widget.isRequest)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade300,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // ── Name + last message ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      if (widget.isPinned && !widget.isRequest) ...[
                        const Icon(Icons.push_pin,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          _name.isEmpty ? '' : _name,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 16,
                            color: widget.isRequest
                                ? Colors.deepPurple.shade400
                                : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Last message / request label
                  widget.isRequest
                      ? Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 12,
                                color: Colors.deepPurple),
                            const SizedBox(width: 4),
                            const Text(
                              "New message request",
                              style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        )
                      : Text(
                          widget.chat.lastMessage.isEmpty
                              ? "No messages yet"
                              : widget.chat.lastMessage,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey,
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Time + unread badge (right column, like WhatsApp) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timestamp — green/amber when unread
                Text(
                  widget.formatTime(widget.chat.lastMessageTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isRequest
                        ? Colors.deepPurple.shade300
                        : hasUnread
                            ? const Color(0xFFF4A825)
                            : Colors.grey,
                    fontWeight: hasUnread
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 5),

                // Unread count bubble (WhatsApp style)
                if (hasUnread)
                  Container(
                    constraints: const BoxConstraints(
                        minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4A825),
                      borderRadius:
                          BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      widget.unreadCount > 99
                          ? '99+'
                          : '${widget.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  // Reserve consistent height so rows don't shift
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}