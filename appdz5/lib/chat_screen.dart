import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'chatbot_welcome_screen.dart';
import 'lost_object_screen.dart';
import 'chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedIndex = 0;
  bool _isAscending = true;

  final List<Color> gradientColors = [
    Color(0xFFA4C6A8),
    Color(0xFFF4D9DE),
    Color(0xFFDDD7E8),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent, // pour voir le dégradé
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF0F4F8),
                  Color(0xFFD1D9E6) ,
                  Color(0xFFA3BED8),
                ],
              ),
            ),
          ),
          title: Text(
            loc.discussionsDesLignes,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDark ? Colors.white70 : Color(0x8C000000),
              ),
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                });
              },
            )
          ],
        ),
      ),

      backgroundColor: isDark ? Colors.black : Color(0xCBE9EBF3),
      body: Column(
        children: [
          Container(
            color: isDark ? Colors.grey[900] : Color(0xCBE9EBF3),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildTopButton(loc.salons, 0, isDark),
                _buildTopButton(loc.assistant, 1, isDark),
                _buildTopButton(loc.objetsPerdus, 2, isDark),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? _buildChatList(isDark, loc)
                : _selectedIndex == 1
                ? ChatbotWelcomeScreen()
                : LostObjectFormScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton(String label, int index, bool isDark) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? Color(0xFF7986CB) :
            Theme.of(context).cardColor,

            foregroundColor: isSelected
                ? Colors.white
                : isDark
                ? Colors.white70
                : Theme.of(context).textTheme.bodyMedium?.color,
            side: BorderSide(color: Theme.of(context).dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildChatList(bool isDark, AppLocalizations loc) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildPlaceholder(isDark, loc);
        }

        var chats = snapshot.data!.docs
            .where((chat) => chat.id != "chat_ligne2")
            .toList();

        if (!_isAscending) chats = chats.reversed.toList();

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];
            String chatId = chat.id;

            // Traduction manuelle sans map
            String ligne;
            switch (chatId) {
              case "chat_ligne1":
                ligne = loc.chatLigne1;
                break;
              case "chat_ligne3":
                ligne = loc.chatLigne3;
                break;
              case "chat_ligne4":
                ligne = loc.chatLigne4;
                break;
              case "chat_ligne5":
                ligne = loc.chatLigne5;
                break;
              default:
                ligne = loc.chatInconnu;
            }

            return StreamBuilder(
              stream: chat.reference
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> messageSnapshot) {
                if (!messageSnapshot.hasData ||
                    messageSnapshot.data!.docs.isEmpty) {
                  return _buildChatCard(
                      ligne, loc.aucunMessage, "--:--", chatId, index, isDark);
                }

                var lastMessage = messageSnapshot.data!.docs.first;
                String message = lastMessage["text"] ?? loc.aucunMessage;
                String time = lastMessage["timestamp"] != null
                    ? DateFormat('HH:mm')
                    .format(lastMessage["timestamp"].toDate())
                    : "--:--";

                return _buildChatCard(
                    ligne, message, time, chatId, index, isDark);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatCard(String ligne, String message, String time,
      String chatId, int index, bool isDark) {
    Color cardColor = isDark
        ? Colors.grey[850]!
        : (index % 2 == 0 ? Color(0xFFE8ECEAFF) : Color(0xFFDDD7E8FF));

    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            'assets/images/ligne${chatId.substring(chatId.length - 1)}.png',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          ligne,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        trailing: Text(
          time,
          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
        ),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final username = prefs.getString('username') ?? 'Inconnu';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(
                chatId: chatId,
                username: username,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark, AppLocalizations loc) {
    return Center(
      child: Text(
        loc.aucuneDiscussionDisponible,
        style: TextStyle(
            fontSize: 16, color: isDark ? Colors.white54 : Colors.black54),
      ),
    );
  }
}
