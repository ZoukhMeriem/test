import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'EditLostObjectStatusScreen.dart';

class LostObjectDetailsScreen extends StatelessWidget {
  final String objectId;

  LostObjectDetailsScreen({required this.objectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Détails de l'objet perdu"),
        backgroundColor: Color(0xFF353C67),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('lost_objects').doc(objectId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Objet introuvable."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditLostObjectStatusScreen(objectId: objectId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF353C67),
                  ),
                  child: Text("Modifier le statut"),
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
        children: [
          Text("$title : ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "Non précisé")),
        ],
      ),
    );
  }
}
