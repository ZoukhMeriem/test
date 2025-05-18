import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrainManagementScreen extends StatefulWidget {
  @override
  _TrainManagementScreenState createState() => _TrainManagementScreenState();
}

class _TrainManagementScreenState extends State<TrainManagementScreen> {
  final trainRef = FirebaseFirestore.instance.collection('TRAIN');

  void showTrainDetails(Map<String, dynamic> data) {
    final lat = data['position']?['lat'];
    final lng = data['position']?['lng'];
    final lastUpdated = data['lastUpdated'] != null
        ? DateFormat('dd MMM yyyy à HH:mm').format((data['lastUpdated'] as Timestamp).toDate())
        : 'Non défini';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Détails du Train"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Numéro du train : ${data['numtrain']}"),
            Text("ID de la ligne : ${data['lineId']}"),
            Text("Statut : ${data['status']}"),
            Text("Latitude : ${lat ?? '---'}"),
            Text("Longitude : ${lng ?? '---'}"),
            Text("Mis à jour : $lastUpdated"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void showTrainForm({DocumentSnapshot? train}) {
    final numController = TextEditingController(text: train?['numtrain'] ?? '');
    final lineController = TextEditingController(text: train?['lineId'] ?? '');
    final latController = TextEditingController(
        text: train?['position']?['lat']?.toString() ?? '');
    final lngController = TextEditingController(
        text: train?['position']?['lng']?.toString() ?? '');

    String selectedStatus = train?['status'] ?? 'en_service';
    final List<String> statusOptions = ['en_service', 'hors_service', 'maintenance'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          train == null ? 'Ajouter un Train' : 'Modifier le Train',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // ✅ Titre en noir
          ),
        ),

        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numController,
                style: TextStyle(color: Colors.black), // ✅ Texte tapé en noir
                decoration: InputDecoration(
                  labelText: 'Numéro du train',
                  labelStyle: TextStyle(color: Colors.black), // ✅ Label en noir
                  prefixIcon: Icon(Icons.train, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: lineController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'ID de la ligne',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.line_weight, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                style: TextStyle(color: Colors.black), // ✅ Texte sélectionné en noir
                dropdownColor: Colors.white,
                items: statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status, style: TextStyle(color: Colors.black)), // ✅ Items en noir
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedStatus = value;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Statut',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.info, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: latController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.my_location, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12),
              TextField(
                controller: lngController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.location_on, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton.icon(
            icon: Icon(train == null ? Icons.add : Icons.edit),
            label: Text(train == null ? 'Ajouter' : 'Modifier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE8AAB4),
            ),
            onPressed: () async {
              if (numController.text.isEmpty ||
                  lineController.text.isEmpty ||
                  latController.text.isEmpty ||
                  lngController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez remplir tous les champs')),
                );
                return;
              }

              final data = {
                'numtrain': numController.text.trim(),
                'lineId': lineController.text.trim(),
                'status': selectedStatus,
                'lastUpdated': FieldValue.serverTimestamp(),
                'position': {
                  'lat': double.tryParse(latController.text) ?? 0.0,
                  'lng': double.tryParse(lngController.text) ?? 0.0,
                }
              };

              if (train == null) {
                await trainRef.add(data);
              } else {
                await trainRef.doc(train.id).update(data);
              }

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gestion des Trains'), backgroundColor: Color(0xFFB3CDE0),),
      body: StreamBuilder<QuerySnapshot>(
        stream: trainRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final trains = snapshot.data!.docs;

          if (trains.isEmpty) {
            return Center(child: Text("Aucun train trouvé."));
          }

          return ListView.builder(
            itemCount: trains.length,
            itemBuilder: (context, index) {
              final train = trains[index];
              final data = train.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${data['numtrain'] ?? 'Train inconnu'}'),
                  onTap: () => showTrainDetails(data),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => showTrainForm(train: train),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Confirmer la suppression"),
                              content: Text("Supprimer ce train ?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text("Annuler"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Supprimer"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await trainRef.doc(train.id).delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTrainForm(),
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFE8AAB4),
      ),
    );
  }
}
