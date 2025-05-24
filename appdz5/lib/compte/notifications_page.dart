import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsScreen extends StatelessWidget {
  final String username;

  NotificationsScreen({required this.username});

  final List<Color> gradientColors = [
    Color(0xFFF0F4F8),
    Color(0xFFD1D9E6),
    Color(0xFFA3BED8),
  ];

  @override
  Widget build(BuildContext context) {
    final RemoteMessage? message =
    ModalRoute.of(context)?.settings.arguments as RemoteMessage?;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF353C67),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF353C67)),
            actionsIconTheme: IconThemeData(color: Color(0xFF353C67)),
            actions: [
              IconButton(
                icon: Icon(Icons.done_all),
                tooltip: 'Tout marquer comme lu',
                onPressed: () async {
                  final query = await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(username)
                      .collection('user_notifications')
                      .where('isRead', isEqualTo: false)
                      .get();

                  for (var doc in query.docs) {
                    await doc.reference.update({'isRead': true});
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Toutes les notifications marquées comme lues')),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep),
                tooltip: 'Tout supprimer',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmer la suppression'),
                      content: const Text('Voulez-vous vraiment supprimer toutes les notifications ?'),
                      actions: [
                        TextButton(
                          child: const Text('Annuler'),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Supprimer tout'),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final query = await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(username)
                        .collection('user_notifications')
                        .get();

                    for (var doc in query.docs) {
                      await doc.reference.delete();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Toutes les notifications ont été supprimées')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .doc(username)
              .collection('user_notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!.docs;

            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune notification',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['isRead'] ?? false;
                final title = notif['title'] ?? '';
                final body = notif['body'] ?? '';
                final timestamp = notif['timestamp'] as Timestamp?;
                final timeText = timestamp != null
                    ? timeago.format(timestamp.toDate(), locale: 'fr')
                    : '';

                return GestureDetector(
                  onTap: () {
                    if (!isRead) {
                      notif.reference.update({'isRead': true});
                    }
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.white : const Color(0xFFEFF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF353C67),
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              body,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            if (timeText.isNotEmpty)
                              Text(
                                timeText,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isRead)
                            const Icon(Icons.circle, color: Colors.red, size: 12),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.grey[600], size: 20),
                            tooltip: 'Supprimer',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmer la suppression'),
                                  content: const Text('Voulez-vous vraiment supprimer cette notification ?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Annuler'),
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Supprimer'),
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await notif.reference.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notification supprimée')),
                                );
                              }
                            },
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
    );
  }
}
