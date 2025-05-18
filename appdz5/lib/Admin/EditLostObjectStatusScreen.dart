import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditLostObjectStatusScreen extends StatefulWidget {
  final String objectId;

  EditLostObjectStatusScreen({required this.objectId});

  @override
  _EditLostObjectStatusScreenState createState() => _EditLostObjectStatusScreenState();
}

class _EditLostObjectStatusScreenState extends State<EditLostObjectStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedStatus;
  bool isLoading = true;

  final List<String> statuses = ['En cours de traitement', 'Trouvé', 'Non trouvé'];

  @override
  void initState() {
    super.initState();
    _fetchObjectData();
  }

  Future<void> _fetchObjectData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lost_objects')
          .doc(widget.objectId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        String rawStatus = data['status'] ?? '';

        // Normalisation du statut pour éviter les erreurs
        String normalizedStatus = statuses.firstWhere(
              (status) => status.toLowerCase() == rawStatus.toLowerCase(),
          orElse: () => statuses[0],
        );

        setState(() {
          selectedStatus = normalizedStatus;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Objet introuvable.")));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _updateStatus() async {
    if (_formKey.currentState!.validate() && selectedStatus != null) {
      await FirebaseFirestore.instance
          .collection('lost_objects')
          .doc(widget.objectId)
          .update({'status': selectedStatus});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Statut mis à jour.")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modifier le statut", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF353C67),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Statut de l'objet :", style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (value) => value == null ? "Veuillez sélectionner un statut" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateStatus,
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF353C67)),
                child: Text("Mettre à jour", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
