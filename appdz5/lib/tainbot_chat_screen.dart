import 'package:flutter/material.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart' as df;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AnimatedBackground.dart'; // ✅ Seulement le fond animé

class TrainbotChatScreen extends StatefulWidget {
  @override
  _TrainbotChatScreenState createState() => _TrainbotChatScreenState();
}

class _TrainbotChatScreenState extends State<TrainbotChatScreen> {
  late df.DialogFlowtter dialogFlowtter;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isReady = false;
  String? username;

  String get chatId => FirebaseAuth.instance.currentUser?.uid ?? "invité";

  @override
  void initState() {
    super.initState();
    initDialogFlowtter();
    loadUsername();
    _ensureUserDocument();
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Utilisateur';
    });
  }

  Future<void> _ensureUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('User').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('username')) {
        await FirebaseFirestore.instance
            .collection('TrainbotPrivateChats')
            .doc(user.uid)
            .set({'username': docSnapshot['username']}, SetOptions(merge: true));
      }
    }
  }

  Future<void> initDialogFlowtter() async {
    debugPrint("🔄 Initialisation de Dialogflow...");
    try {
      final instance = await df.DialogFlowtter.fromFile(
        path: 'assets/dialogflow-auth.json',
      );
      debugPrint("✅ Dialogflow initialisé !");
      setState(() {
        dialogFlowtter = instance;
        isReady = true;
      });
    } catch (e) {
      debugPrint("❌ Erreur d'initialisation Dialogflow: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (!isReady || _controller.text.trim().isEmpty) return;

    String userMessage = _controller.text.trim();
    _controller.clear();

    await FirebaseFirestore.instance
        .collection('TrainbotPrivateChats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': userMessage,
      'sender': username,
      'owner': username,
      'timestamp': FieldValue.serverTimestamp(),
    });

    try {
      final response = await dialogFlowtter.detectIntent(
        queryInput: df.QueryInput(text: df.TextInput(text: userMessage)),
      );

      String botResponse = "Désolée, je n'ai pas compris.";
      if (response.message != null &&
          response.message!.text != null &&
          response.message!.text!.text!.isNotEmpty) {
        botResponse = response.message!.text!.text![0];
      }

      await FirebaseFirestore.instance
          .collection('TrainbotPrivateChats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': botResponse,
        'sender': 'bot',
        'owner': username,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint("❌ Erreur avec Dialogflow : $e");
    }
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('TrainbotPrivateChats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        var messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          return Center(
            child: Text("Aucun message pour l'instant",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var messageData = messages[index].data() as Map<String, dynamic>;
            final msgText = messageData['text'] ?? '';
            final sender = messageData['sender'] ?? '';
            final owner = messageData['owner'] ?? '';

            if (owner != username) return SizedBox.shrink();

            return ChatMessage(
              text: msgText,
              isUser: sender == username,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TrainBot"),
        backgroundColor: Color(0x998BB1FF),
      ),
      body: Stack(
        children: [
          // ✅ Fond animé uniquement
          Positioned.fill(child: AnimatedBackground()),

          // 💬 Contenu du chat
          Column(
            children: [
              Expanded(child: _buildMessages()),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: "Écrire un message...",
                          hintStyle: TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.85),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Color(0x998BB1FF),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.indigo : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: isUser ? Radius.circular(18) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
