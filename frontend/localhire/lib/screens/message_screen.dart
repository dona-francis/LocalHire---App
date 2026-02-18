import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MessageScreen extends StatefulWidget {
  final String userName;

  const MessageScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> messages = [
    {
      "text": "Hi there! I'm interested in the plumbing job you posted.",
      "isMe": false,
      "time": "10:15 AM",
      "read": true,
      "deleted": false
    },
    {
      "text": "Great! Are you available tomorrow morning?",
      "isMe": true,
      "time": "10:18 AM",
      "read": true,
      "deleted": false
    },
  ];

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      messages.add({
        "text": _controller.text.trim(),
        "isMe": true,
        "time": TimeOfDay.now().format(context),
        "read": false,
        "deleted": false,
      });
    });
    _controller.clear();
    scrollToBottom();
  }

  Future<void> attachPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        messages.add({
          "text": "Photo: ${image.name}",
          "isMe": true,
          "time": TimeOfDay.now().format(context),
          "read": true,
          "deleted": false,
          "isPhoto": true,
        });
      });
      scrollToBottom();
    }
  }

  void sendLocation() {
    setState(() {
      messages.add({
        "text": "Greenwood Residency, Block B",
        "isMe": true,
        "time": TimeOfDay.now().format(context),
        "read": true,
        "deleted": false,
        "isLocation": true,
      });
    });
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Attach Photo"),
            onTap: () {
              Navigator.pop(context);
              attachPhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: const Text("Attach Document"),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Document picker")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text("Share Location"),
            onTap: () {
              Navigator.pop(context);
              sendLocation();
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm")),
        ],
      ),
    );
  }

  void showReportDialog() {
    final TextEditingController reasonController = TextEditingController();
    String? selectedOption;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Profile"),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                hint: const Text("Select reason"),
                items: [
                  "Spam",
                  "Harassment",
                  "Fake Profile",
                  "Other",
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                value: selectedOption,
                onChanged: (val) => setStateDialog(() => selectedOption = val),
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                    hintText: "Additional reason (optional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Reported: ${selectedOption ?? 'No reason'} ${reasonController.text}")));
              },
              child: const Text("Submit")),
        ],
      ),
    );
  }

  void handleTopMenuAction(String value) async {
    if (value == 'favourites') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Added to Favourites")));
    } else if (value == 'clear_chat') {
      bool? confirm = await showConfirmationDialog(
          "Clear Chat", "Are you sure you want to clear all messages?");
      if (confirm == true) setState(() => messages.clear());
    } else if (value == 'report_profile') {
      showReportDialog();
    }
  }

  void deleteMessage(int index) {
    setState(() {
      messages[index]["deleted"] = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  TextSpan parseMessage(String text) {
    // Simple tagging: highlight words starting with '@'
    final words = text.split(' ');
    return TextSpan(
      children: words.map((word) {
        if (word.startsWith('@')) {
          return TextSpan(
              text: '$word ',
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.bold));
        }
        return TextSpan(text: '$word ');
      }).toList(),
      style: const TextStyle(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECE6D8),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: Text(widget.userName,
            style: const TextStyle(color: Colors.black)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: handleTopMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'favourites', child: Text('Favourites')),
              PopupMenuItem(value: 'clear_chat', child: Text('Clear Chat')),
              PopupMenuItem(value: 'report_profile', child: Text('Report Profile')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg["isMe"];
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () => deleteMessage(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFFE6D2AA)
                            : const Color(0xFFECECEC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: msg["deleted"] == true
                          ? const Text("You deleted this message",
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg["isLocation"] == true)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          size: 40,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      RichText(
                                          text: parseMessage(msg["text"])),
                                    ],
                                  )
                                else if (msg["isPhoto"] == true)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      RichText(
                                          text: parseMessage(msg["text"])),
                                    ],
                                  )
                                else
                                  RichText(text: parseMessage(msg["text"])),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(msg["time"],
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                    const SizedBox(width: 4),
                                    if (isMe)
                                      Icon(
                                        Icons.done_all,
                                        size: 16,
                                        color: msg["read"]
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
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: showAttachmentOptions),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4A825),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
