import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String username;

  ChatRoomScreen({required this.chatId, required this.username});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with SingleTickerProviderStateMixin {
  TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startAutoDelete();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _sendMessage({String? imageUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': imageUrl ?? _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isImage': imageUrl != null,
      'sender': widget.username,
    });

    _messageController.clear();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('chat_images/$fileName');
      await ref.putFile(file);
      String imageUrl = await ref.getDownloadURL();
      _sendMessage(imageUrl: imageUrl);
    }
  }

  void _deleteOldMessages() async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(hours: 24));
    final querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
        DateTime messageTime = (data['timestamp'] as Timestamp).toDate();
        if (messageTime.isBefore(cutoff)) {
          await doc.reference.delete();
        }
      }
    }
  }

  void _startAutoDelete() {
    Timer.periodic(Duration(hours: 1), (timer) {
      _deleteOldMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLightMode = Theme.of(context).brightness == Brightness.light;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.chatTitle,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0x998BB1FF),
        elevation: 5,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    bool isMe = message['sender'] == widget.username;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                message['sender'] ?? loc.unknownUser,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isLightMode ? Colors.black87 : Colors.white70,
                                ),
                              ),
                            ),
                          Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isMe ? Color(0x998BB1FF) : Color(0xFFF4D9DE),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 18),
                                ),
                              ),
                              child: message['isImage']
                                  ? Image.network(message['text'], width: 200)
                                  : Text(
                                message['text'],
                                style: TextStyle(
                                  color: isMe ? Colors.black87 : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isLightMode ? Colors.white : Colors.grey.shade900,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Color(0xFD0B0000)),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: isLightMode ? Colors.black : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.writeMessage,
                      hintStyle: TextStyle(
                        color: isLightMode ? Colors.grey : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFD0B0000)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFD0B0000)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
