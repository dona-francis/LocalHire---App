import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

class MessageScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String userName;

  const MessageScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.userName,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final ChatService _chatService = ChatService();

  // Track selected messages for deletion
  final Set<String> _selectedMessageIds = {};
  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.chatId);
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    _chatService.sendMessage(
      chatId: widget.chatId,
      text: _controller.text.trim(),
      type: 'text',
    );
    _controller.clear();
    scrollToBottom();
  }

  Future<void> attachPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _chatService.sendMessage(
        chatId: widget.chatId,
        text: image.name,
        type: 'image',
      );
      scrollToBottom();
    }
  }

  Future<void> attachDocument() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      _chatService.sendMessage(
        chatId: widget.chatId,
        text: result.files.single.name,
        type: 'document',
      );
      scrollToBottom();
    }
  }

  Future<void> sendLocation() async {
    _chatService.sendMessage(
      chatId: widget.chatId,
      text: 'Live Location Shared',
      type: 'location',
    );
    scrollToBottom();
  }

  // ── Selection logic ──
  void onMessageLongPress(MessageModel msg) {
    // Only sender can select their own messages
    if (msg.senderId != _chatService.currentUserId) return;
    if (msg.deleted) return;
    setState(() => _selectedMessageIds.add(msg.id));
  }

  void onMessageTap(MessageModel msg) {
    if (!_isSelectionMode) return;
    if (msg.senderId != _chatService.currentUserId) return;
    setState(() {
      if (_selectedMessageIds.contains(msg.id)) {
        _selectedMessageIds.remove(msg.id);
      } else {
        _selectedMessageIds.add(msg.id);
      }
    });
  }

  void cancelSelection() {
    setState(() => _selectedMessageIds.clear());
  }

  Future<void> deleteSelectedMessages() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Messages"),
        content: Text(
            "Delete ${_selectedMessageIds.length} message(s)? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
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

  Future<bool?> simpleConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<void> showReportDialog() async {
    String? selectedReason;
    TextEditingController detailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text("Report User"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
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
                      onChanged: (value) =>
                          setState(() => selectedReason = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Write in detail (optional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Report submitted successfully")),
                );
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void handleTopMenuAction(String value) async {
    if (value == "view_profile") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("View Profile clicked")));
    } else if (value == "add_favourite") {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to Favourites")));
    } else if (value == "clear_chat") {
      bool? confirm = await simpleConfirmDialog(
          "Clear Chat", "Are you sure you want to clear chat?");
      if (confirm == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Clear chat coming soon")));
      }
    } else if (value == "report") {
      showReportDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [

            // ── Top Bar ──
            // Shows delete button when in selection mode, normal bar otherwise
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              color: const Color(0xFFECE6D8),
              child: _isSelectionMode
                  ? Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: cancelSelection,
                        ),
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
                            onPressed: () => Navigator.pop(context)),
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          child:
                              Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.userName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: handleTopMenuAction,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: "view_profile",
                                child: Text("View Profile")),
                            PopupMenuItem(
                                value: "add_favourite",
                                child: Text("Add to Favourite")),
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

            // ── Messages List ──
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Say hello! 👋",
                          style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final messages = snapshot.data!;
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe =
                          msg.senderId == _chatService.currentUserId;
                      final isSelected =
                          _selectedMessageIds.contains(msg.id);

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () => onMessageLongPress(msg),
                          onTap: () => onMessageTap(msg),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(
                                vertical: 6),
                            padding: const EdgeInsets.all(14),
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width *
                                        0.75),
                            decoration: BoxDecoration(
                              // Highlight selected messages
                              color: isSelected
                                  ? Colors.orange.withOpacity(0.3)
                                  : isMe
                                      ? const Color(0xFFE6D2AA)
                                      : const Color(0xFFECECEC),
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.orange, width: 1.5)
                                  : null,
                            ),
                            child: msg.deleted
                                ? const Text(
                                    "You deleted this message",
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (msg.type == 'image')
                                        const Icon(Icons.image,
                                            size: 40)
                                      else if (msg.type == 'document')
                                        const Icon(
                                            Icons.insert_drive_file,
                                            size: 40)
                                      else if (msg.type == 'location')
                                        const Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                color: Colors.red),
                                            SizedBox(width: 6),
                                            Text("Live Location"),
                                          ],
                                        )
                                      else
                                        Text(msg.text),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            TimeOfDay.fromDateTime(
                                                    msg.timestamp)
                                                .format(context),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                          const SizedBox(width: 4),
                                          if (isMe)
                                            Icon(
                                              Icons.done_all,
                                              size: 16,
                                              color: msg.isRead
                                                  ? Colors.orange
                                                  : Colors.grey,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Input Bar (identical to original) ──
            Container(
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
                            bottom: MediaQuery.of(context)
                                    .viewPadding
                                    .bottom +
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
                                leading:
                                    const Icon(Icons.location_on),
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
            ),
          ],
        ),
      ),
    );
  }
}