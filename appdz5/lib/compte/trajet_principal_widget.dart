import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrajetPrincipalWidget extends StatelessWidget {
  final Color primaryColor = const Color(0xFF353C67);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('TRAJET1')
          .doc('trajet_01')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoTile(Icons.train, "Départ", data['Depart']),
                  _infoTile(Icons.location_on, "Arrêt", data['Aret']),
                  _infoTile(Icons.schedule, "Heure de départ", data['Heure_de_Départ']),
                  _infoTile(Icons.access_time, "Heure d'arrivée", data["Heure_d'Arrivée"]),
                  _infoTile(Icons.route, "Ligne", data['lineId']),
                  _infoTile(Icons.calendar_today, "Jours de circulation", data['Jour_de_Circulation']),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          SizedBox(width: 10),
          Text(
            "$label : ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
