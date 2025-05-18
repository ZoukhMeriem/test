import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LigneManagementScreen extends StatefulWidget {
  @override
  State<LigneManagementScreen> createState() => _LigneManagementScreenState();
}

class _LigneManagementScreenState extends State<LigneManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showAddOrEditDialog({DocumentSnapshot? ligne}) async {
    final TextEditingController nameController =
    TextEditingController(text: ligne != null ? ligne['nom'] : '');
    final TextEditingController codeController =
    TextEditingController(text: ligne != null ? ligne['code'] : '');
    List<String> selectedGares =
    ligne != null ? List<String>.from(ligne['gares'] ?? []) : [];

    final gareSnapshot =
    await FirebaseFirestore.instance.collection('Gare').get();
    final gares = gareSnapshot.docs;

    showModalBottomSheet(
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  ligne == null ? "Ajouter une ligne" : "Modifier la ligne",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Nom",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.train),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: codeController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Code",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Sélectionner les gares",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: gares.map((gare) {
                    String nom = gare['name'];
                    String id = gare.id;
                    return CheckboxListTile(
                      title: Text(nom),
                      value: selectedGares.contains(id),
                      onChanged: (val) {
                        setState(() {
                          if (val!) {
                            selectedGares.add(id);
                          } else {
                            selectedGares.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE8AAB4),
                    padding: EdgeInsets.symmetric(horizontal: 90, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        codeController.text.isEmpty ||
                        selectedGares.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text("Veuillez remplir tous les champs")),
                      );
                      return;
                    }

                    final ligneData = {
                      'nom': nameController.text,
                      'code': codeController.text,
                      'gares': selectedGares,
                    };

                    if (ligne == null) {
                      await FirebaseFirestore.instance
                          .collection('LIGNE')
                          .add(ligneData);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('LIGNE')
                          .doc(ligne.id)
                          .update(ligneData);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(ligne == null
                              ? "Ligne ajoutée avec succès"
                              : "Ligne modifiée avec succès")),
                    );
                  },
                  icon: Icon(ligne == null ? Icons.add : Icons.edit),
                  label: Text(ligne == null ? "Ajouter" : "Modifier"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ligneRef = FirebaseFirestore.instance.collection('LIGNE');

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Lignes'),
        backgroundColor: Color(0xFFB3CDE0),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: "Rechercher une ligne",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ligneRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final lignes = snapshot.data!.docs.where((ligne) {
                  final nom = ligne['nom']?.toString().toLowerCase() ?? '';
                  return nom.contains(_searchQuery);
                }).toList();

                if (lignes.isEmpty) {
                  return Center(child: Text("Aucune ligne trouvée."));
                }

                return ListView.builder(
                  itemCount: lignes.length,
                  itemBuilder: (context, index) {
                    final ligne = lignes[index];
                    final data = ligne.data() as Map<String, dynamic>;

                    final nom = data['nom'] ?? 'Sans nom';
                    final code = data['code'] ?? 'Aucun code';
                    final List gares = data['gares'] ?? [];

                    return Card(
                      margin:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ExpansionTile(
                        title: Text(nom),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Code : $code", style: TextStyle(fontSize: 16)),
                                SizedBox(height: 6),
                                Text("Gares :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ...gares.map<Widget>((gare) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text("- $gare"),
                                )),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.orange),
                                      onPressed: () {
                                        _showAddOrEditDialog(ligne: ligne);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text("Confirmer la suppression"),
                                            content: Text("Voulez-vous supprimer cette ligne ?"),
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
                                          await ligneRef.doc(ligne.id).delete();
                                        }
                                      },
                                    ),
                                  ],
                                )
                              ],
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(),
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFE8AAB4),
      ),
    );
  }
}
