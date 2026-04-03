import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import 'worker_profile_screen.dart';
import 'location_picker_screen.dart';

class MessageScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String userName;
  final String? userProfileImage;
  final bool isRequest;

  const MessageScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.userName,
    this.userProfileImage,
    this.isRequest = false,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final ChatService _chatService = ChatService();
  bool _isSending = false;

  final Set<String> _selectedMessageIds = {};
  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!widget.isRequest) {
      _chatService.markMessagesAsRead(widget.chatId);
    }
  }

  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();
    await _chatService.sendMessage(
      chatId: widget.chatId,
      text: text,
      type: 'text',
    );
  }

  Future<void> attachPhoto() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isSending = true);
    try {
      final url = await _chatService.uploadChatFile(
        file: File(image.path),
        chatId: widget.chatId,
        type: 'image',
      );
      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: '📷 Photo',
        type: 'image',
        fileUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send photo: $e")));
      }
    }
    setState(() => _isSending = false);
  }

  Future<void> attachDocument() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    setState(() => _isSending = true);
    try {
      final file = File(result.files.single.path!);
      final url = await _chatService.uploadChatFile(
        file: file,
        chatId: widget.chatId,
        type: 'document',
      );
      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: '📄 ${result.files.single.name}',
        type: 'document',
        fileUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send file: $e")));
      }
    }
    setState(() => _isSending = false);
  }

  Future<void> sendLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
          builder: (_) => const LocationPickerScreen()),
    );
    if (result == null) return;

    final address = result['address'] as String;
    final lat = result['lat'] as double;
    final lng = result['lng'] as double;

    await _chatService.sendMessage(
      chatId: widget.chatId,
      text: address,
      type: 'location',
      fileUrl: 'https://maps.google.com/?q=$lat,$lng',
    );
  }

  Future<void> clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear Chat"),
        content: const Text(
            "All messages will be cleared. This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Clear",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _chatService.clearChat(widget.chatId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Chat cleared")));
      }
    }
  }

  void onMessageLongPress(MessageModel msg) {
    if (msg.senderId != _chatService.currentUserId) return;
    setState(() => _selectedMessageIds.add(msg.id));
  }

  void onMessageTap(MessageModel msg) {
    if (!_isSelectionMode) return;
    if (msg.senderId != _chatService.currentUserId) return;
    setState(() {
      _selectedMessageIds.contains(msg.id)
          ? _selectedMessageIds.remove(msg.id)
          : _selectedMessageIds.add(msg.id);
    });
  }

  void cancelSelection() =>
      setState(() => _selectedMessageIds.clear());

  Future<void> deleteSelectedMessages() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Messages"),
        content: Text(
            "Delete ${_selectedMessageIds.length} message(s)?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      for (final msgId in _selectedMessageIds) {
        await _chatService.deleteMessage(widget.chatId, msgId);
      }
      setState(() => _selectedMessageIds.clear());
    }
  }

  Future<void> showReportDialog() async {
    String? selectedReason;
    final detailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Report User"),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration:
                      const InputDecoration(labelText: "Reason"),
                  items: const [
                    DropdownMenuItem(
                        value: "Harassment",
                        child: Text("Harassment")),
                    DropdownMenuItem(
                        value: "Offensive Content",
                        child: Text("Offensive Content")),
                    DropdownMenuItem(
                        value: "Spam", child: Text("Spam")),
                    DropdownMenuItem(
                        value: "Fake Profile",
                        child: Text("Fake Profile")),
                    DropdownMenuItem(
                        value: "Other", child: Text("Other")),
                  ],
                  onChanged: (v) =>
                      setState(() => selectedReason = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Details (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Report submitted")));
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void handleTopMenuAction(String value) async {
    if (value == "view_profile") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WorkerProfileScreen(userId: widget.otherUserId),
        ),
      );
    } else if (value == "add_favourite") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to Favourites")));
    } else if (value == "clear_chat") {
      clearChat();
    } else if (value == "report") {
      showReportDialog();
    }
  }

  Widget _buildMessageContent(MessageModel msg, bool isMe) {

    if (msg.type == 'image' && msg.fileUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _FullScreenImage(url: msg.fileUrl!),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                msg.fileUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                                child:
                                    CircularProgressIndicator()),
                          ),
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 60),
              ),
            ),
          ),
          _timeRow(msg, isMe),
        ],
      );
    }

    if (msg.type == 'document' && msg.fileUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(msg.fileUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file,
                    color: Colors.orange, size: 32),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          _timeRow(msg, isMe),
        ],
      );
    }

    if (msg.type == 'location' && msg.fileUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(msg.fileUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        color: Colors.red, size: 20),
                    SizedBox(width: 4),
                    Text("Location",
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  msg.text,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
          _timeRow(msg, isMe),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(msg.text),
        _timeRow(msg, isMe),
      ],
    );
  }

  // ── Time + read receipt row ────────────────────────────
  // ✅ Single tick only — no double tick (done_all removed)
  //    Grey  = sent but not yet read by receiver
  //    Orange = receiver has read the message
  //    No tick shown for request chats (isRequest = true)
  Widget _timeRow(MessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TimeOfDay.fromDateTime(msg.timestamp).format(context),
            style: const TextStyle(
                fontSize: 11, color: Colors.grey),
          ),
          // ✅ Only show for my outgoing messages in accepted chats
          if (isMe && !widget.isRequest) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.done, // ✅ Single tick — done_all removed
              size: 16,
              color: msg.isRead
                  ? Colors.orange  // receiver has read it
                  : Colors.grey,   // sent, not yet read
            ),
          ],
        ],
      ),
    );
  }

  // ── Accept/Decline bar ────────────────────────────────
  Widget _buildRequestBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom:
              MediaQuery.of(context).viewPadding.bottom + 12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${widget.userName} sent you a message request.",
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [

              // Decline
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _chatService
                        .declineChatRequest(widget.chatId);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text("Decline",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Accept — immediately replaces screen with full chat
              // No confirmation dialog; the request bar itself is the decision UI
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _chatService
                        .acceptChatRequest(widget.chatId);
                    await _chatService
                        .markMessagesAsRead(widget.chatId);
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessageScreen(
                            chatId: widget.chatId,
                            otherUserId: widget.otherUserId,
                            userName: widget.userName,
                            userProfileImage:
                                widget.userProfileImage,
                            isRequest: false,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A825),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text("Accept",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: 8,
          bottom:
              MediaQuery.of(context).viewPadding.bottom + 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                builder: (_) => Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        MediaQuery.of(context).viewPadding.bottom +
                            20,
                  ),
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo),
                        title: const Text("Photo"),
                        onTap: () {
                          Navigator.pop(context);
                          attachPhoto();
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                            Icons.insert_drive_file),
                        title: const Text("Document"),
                        onTap: () {
                          Navigator.pop(context);
                          attachDocument();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text("Live Location"),
                        onTap: () {
                          Navigator.pop(context);
                          sendLocation();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF4A825),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [

            // ── Top Bar ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              color: widget.isRequest
                  ? const Color(0xFFEDE8F5)
                  : const Color(0xFFECE6D8),
              child: _isSelectionMode
                  ? Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: cancelSelection),
                        Expanded(
                          child: Text(
                            "${_selectedMessageIds.length} selected",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: deleteSelectedMessages,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () =>
                                Navigator.pop(context)),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              widget.userProfileImage != null
                                  ? NetworkImage(
                                      widget.userProfileImage!)
                                  : null,
                          child: widget.userProfileImage == null
                              ? Text(
                                  widget.userName.isNotEmpty
                                      ? widget.userName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              if (widget.isRequest)
                                const Text(
                                  "Message Request",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.deepPurple),
                                ),
                            ],
                          ),
                        ),
                        if (!widget.isRequest)
                          PopupMenuButton<String>(
                            onSelected: handleTopMenuAction,
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: "view_profile",
                                  child: Text("View Profile")),
                              PopupMenuItem(
                                  value: "add_favourite",
                                  child:
                                      Text("Add to Favourite")),
                              PopupMenuItem(
                                  value: "clear_chat",
                                  child: Text("Clear Chat")),
                              PopupMenuItem(
                                  value: "report",
                                  child: Text("Report")),
                            ],
                          ),
                      ],
                    ),
            ),

            if (_isSending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.orange.withOpacity(0.1),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text("Sending...",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange)),
                  ],
                ),
              ),

            // ── Messages ──
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Say hello! 👋",
                          style:
                              TextStyle(color: Colors.grey)),
                    );
                  }

                  final messages =
                      snapshot.data!.reversed.toList();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId ==
                          _chatService.currentUserId;
                      final isSelected =
                          _selectedMessageIds.contains(msg.id);

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () =>
                              onMessageLongPress(msg),
                          onTap: () => onMessageTap(msg),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 150),
                            margin: const EdgeInsets.symmetric(
                                vertical: 6),
                            padding: const EdgeInsets.all(14),
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context)
                                            .size
                                            .width *
                                        0.75),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange
                                      .withOpacity(0.3)
                                  : isMe
                                      ? const Color(0xFFE6D2AA)
                                      : const Color(0xFFECECEC),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.orange,
                                      width: 1.5)
                                  : null,
                            ),
                            child: _buildMessageContent(
                                msg, isMe),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            widget.isRequest
                ? _buildRequestBar()
                : _buildInputBar(),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) =>
                progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white)),
            errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 60),
          ),
        ),
      ),
    );
  }
}
