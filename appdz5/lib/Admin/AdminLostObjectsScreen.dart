import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lost_object_details_screen.dart';  // Assure-toi que ce fichier existe

class AdminLostObjectsScreen extends StatefulWidget {
  @override
  _AdminLostObjectsScreenState createState() => _AdminLostObjectsScreenState();
}

class _AdminLostObjectsScreenState extends State<AdminLostObjectsScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> lostObjectsStream =
    FirebaseFirestore.instance.collection('lost_objects').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion des Objets Perdus", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xBFABDFFF),
      ),
      body: Column(
        children: [
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: TextStyle(color: Colors.black), // ✅ Texte tapé en noir
              decoration: InputDecoration(
                hintText: "Rechercher un objet...",
                hintStyle: TextStyle(color: Colors.grey), // ✅ Texte d'indice en gris
                prefixIcon: Icon(Icons.search, color: Colors.black), // ✅ Icône noire si souhaité
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Liste des objets
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: lostObjectsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final description = data['description']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery) || description.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text("Aucun objet trouvé."));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                      child: ListTile(
                        leading: Icon(Icons.inventory, color: Color(0xFF353C67)),
                        title: Text(data['name'] ?? "Nom inconnu"),
                        subtitle: Text(data['description'] ?? "Aucune description"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LostObjectDetailsScreen(objectId: doc.id),
                                  ),
                                );
                              },
                            ),

                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text("Confirmer la suppression"),
                                    content: Text("Voulez-vous vraiment supprimer cet objet ?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Annuler")),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Supprimer")),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('lost_objects')
                                      .doc(doc.id)
                                      .delete();
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF353C67),
        child: Icon(Icons.add),
        onPressed: () {
          // TODO: Aller à l’écran d’ajout d’objet
        },
      ),
    );
  }
}
