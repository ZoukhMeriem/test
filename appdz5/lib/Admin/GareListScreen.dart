import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GareManagementScreen extends StatefulWidget {
  @override
  _GareManagementScreenState createState() => _GareManagementScreenState();
}

class _GareManagementScreenState extends State<GareManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _gares = [];
  List<DocumentSnapshot> _filteredGares = [];
  List<DocumentSnapshot> _lignes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final gareSnapshot =
    await FirebaseFirestore.instance.collection('Gare').get();
    final ligneSnapshot =
    await FirebaseFirestore.instance.collection('LIGNE').get();

    setState(() {
      _gares = gareSnapshot.docs;
      _filteredGares = _gares;
      _lignes = ligneSnapshot.docs;
    });
  }

  void _filterGares(String query) {
    setState(() {
      _filteredGares = _gares
          .where((gare) => gare['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  String _getLigneName(String id) {
    try {
      final ligne = _lignes.firstWhere((ligne) => ligne.id == id);
      return ligne['nom'];
    } catch (e) {
      return id; // ou "Inconnue"
    }
  }


  void _showGareDetails(DocumentSnapshot gare) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(gare['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${gare['id']}'),
            Text(
                'Lignes: ${(gare['lineId'] as List).map((id) => _getLigneName(id)).join(', ')}'),
            Text('Latitude: ${gare['location']['lat']}'),
            Text('Longitude: ${gare['location']['lng']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showEditGareDialog(DocumentSnapshot gare) {
    final nameController = TextEditingController(text: gare['name']);
    final _latController =
    TextEditingController(text: gare['location']['lat'].toString());
    final _lngController =
    TextEditingController(text: gare['location']['lng'].toString());
    List<String> selectedLines = List<String>.from(gare['lineId']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  "✏️ Modifier la gare",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Informations de la gare", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),

              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Nom de la gare',
                  prefixIcon: Icon(Icons.train),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _latController,
                style: TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _lngController,
                style: TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),
              const Text("📍 Sélectionnez les lignes associées",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),

              ..._lignes.map((ligne) {
                final id = ligne.id;
                final nom = ligne['nom'];
                return CheckboxListTile(
                  title: Text(nom),
                  value: selectedLines.contains(id),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        selectedLines.add(id);
                      } else {
                        selectedLines.remove(id);
                      }
                    });
                  },
                );
              }).toList(),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        _latController.text.isEmpty ||
                        _lngController.text.isEmpty ||
                        selectedLines.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Veuillez remplir tous les champs")),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('Gare')
                        .doc(gare.id)
                        .update({
                      'name': nameController.text,
                      'location': {
                        'lat': double.tryParse(_latController.text) ?? 0,
                        'lng': double.tryParse(_lngController.text) ?? 0
                      },
                      'lineId': selectedLines
                    });
                    Navigator.pop(context);
                    _fetchData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("✅ Gare modifiée avec succès")),
                    );
                  },
                  icon: const Icon(Icons.save),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE8AAB4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text("Enregistrer les modifications",
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGareDialog() {
    final nameController = TextEditingController();
    final _latController = TextEditingController();
    final _lngController = TextEditingController();
    List<String> selectedLines = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  "Ajouter une nouvelle gare",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.train),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _latController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _lngController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              Text("Sélectionnez les lignes :", style: TextStyle(fontWeight: FontWeight.w600)),
              ..._lignes.map((ligne) {
                final id = ligne.id;
                final nom = ligne['nom'];
                return CheckboxListTile(
                  title: Text(nom),
                  value: selectedLines.contains(id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedLines.add(id);
                      } else {
                        selectedLines.remove(id);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      _latController.text.isEmpty ||
                      _lngController.text.isEmpty ||
                      selectedLines.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Veuillez remplir tous les champs")),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance.collection('Gare').add({
                    'id': DateTime.now().millisecondsSinceEpoch,
                    'name': nameController.text.trim(),
                    'location': {
                      'lat': double.tryParse(_latController.text) ?? 0,
                      'lng': double.tryParse(_lngController.text) ?? 0
                    },
                    'lineId': selectedLines
                  });

                  Navigator.pop(context);
                  _fetchData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gare ajoutée avec succès")),
                  );
                },
                icon: Icon(Icons.add_location_alt),
                label: Text("Ajouter la gare"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE8AAB4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _deleteGare(DocumentSnapshot gare) async {
    await FirebaseFirestore.instance.collection('Gare').doc(gare.id).delete();
    _fetchData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gare supprimée")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Gestion des Gares'),
          backgroundColor: Color(0xFFA7C7E7)
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Rechercher une gare',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterGares,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredGares.length,
              itemBuilder: (context, index) {
                final gare = _filteredGares[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(gare['name']),

                    onTap: () => _showGareDetails(gare),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            _showEditGareDialog(gare);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(gare);


                          },
                        ),
                      ],
                    ),

                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGareDialog,
        child: const Icon(Icons.add),
        backgroundColor: Color(0xFFE8AAB4), // Bleu pastel
      ),
    );
  }
  void _showDeleteConfirmationDialog(DocumentSnapshot gare) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation de suppression"),
          content: Text("Voulez-vous vraiment supprimer la gare '${gare['name']}' ?"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
              },
            ),
            TextButton(
              child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
                await FirebaseFirestore.instance.collection('Gare').doc(gare.id).delete();
                _fetchData(); // Actualise la liste
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gare supprimée")),
                );
              },
            ),
          ],
        );
      },
    );
  }

}
