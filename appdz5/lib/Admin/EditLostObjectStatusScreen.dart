import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LostObjectDetailsScreen extends StatelessWidget {
  final String objectId;

  LostObjectDetailsScreen({required this.objectId});

  Future<void> sendPushNotification(String token, String title, String body) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=VOTRE_CLE_FCM_SERVEUR', // <== Remplace par ta clé serveur FCM
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'priority': 'high',
        }),
      );
    } catch (e) {
      print('Erreur en envoyant la notification : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Détails de l'objet perdu"),
        backgroundColor: Color(0xFF353C67),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('lost_objects')
            .doc(objectId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Objet introuvable."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          Future<void> updateStatusAndNotify(String newStatus) async {
            await FirebaseFirestore.instance
                .collection('lost_objects')
                .doc(objectId)
                .update({'status': newStatus});

            final String usernameProprietaire = data['username'];

            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(usernameProprietaire)
                .collection('user_notifications')
                .add({
              'title': 'Mise à jour de votre objet perdu',
              'body': 'Le statut de votre objet a été changé à : $newStatus.',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });

            final userDoc = await FirebaseFirestore.instance
                .collection('User')
                .doc(usernameProprietaire)
                .get();

            final userToken = userDoc.data()?['fcmToken'];
            if (userToken != null) {
              await sendPushNotification(
                userToken,
                'Mise à jour de votre objet perdu',
                'Le statut a été changé à : $newStatus.',
              );
            }
          }

          return Padding(
            padding: EdgeInsets.all(20),
            child: ListView(
              children: [
                if (data['imageUrl'] != null)
                  Image.network(data['imageUrl'], height: 200, fit: BoxFit.cover),
                SizedBox(height: 20),
                _buildDetail("Nom", data['name']),
                _buildDetail("Description", data['description']),
                _buildDetail("Ligne de train", data['trainLine']),
                _buildDetail("Numéro du train", data['trainNumber']),
                _buildDetail("Date", data['date']),
                _buildDetail("Statut", data['status']),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    await updateStatusAndNotify('Trouvé');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Statut mis à jour à "Trouvé" et notification envoyée')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF353C67),
                  ),
                  child: Text("Marquer comme trouvé"),
                ),

                SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    await updateStatusAndNotify('Non trouvé');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Statut mis à jour à "Non trouvé" et notification envoyée')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  child: Text("Marquer comme non trouvé"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetail(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title : ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "Non précisé")),
        ],
      ),
    );
  }
}
