import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminListScreen extends StatelessWidget {
  final CollectionReference adminsRef = FirebaseFirestore.instance.collection('Admin');

  void _showAdminDetailsDialog(BuildContext context, DocumentSnapshot adminDoc) {
    final data = adminDoc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Informations de l'admin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom : ${data['Nom']}"),
            Text("Prénom : ${data['Prénom']}"),
            Text("Nom d'utilisateur : ${data['Username']}"),
            Text("Email : ${data['Email']}"),
            Text("Mot de passe : ${data['Password']}"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, adminDoc.id);
              },
              icon: Icon(Icons.delete),
              label: Text("Supprimer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
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

  void _showDeleteConfirmation(BuildContext context, String adminId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment supprimer cet admin ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              await adminsRef.doc(adminId).delete();
              Navigator.pop(context);
            },
            child: Text("Supprimer"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Liste des Admins',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFB3D9FF),
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: adminsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final admins = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final data = admin.data() as Map<String, dynamic>;
              final nom = data['Nom'] ?? '';
              final prenom = data['Prénom'] ?? '';

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFE8AAB4),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text("$nom $prenom", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Icon(Icons.info_outline),
                  onTap: () => _showAdminDetailsDialog(context, admin),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFE8AAB4),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddAdminScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}




//add admin
class AddAdminScreen extends StatefulWidget {
  @override
  _AddAdminScreenState createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _addAdmin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Admin').add({
          'Prénom': _prenomController.text.trim(),
          'Nom': _nomController.text.trim(),
          'Username': _usernameController.text.trim(),
          'Email': _emailController.text.trim(),
          'Password': _passwordController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Administrateur ajouté avec succès')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextFormField(
          style: TextStyle(color: Colors.black),
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
              labelStyle: TextStyle(color: Colors.black)

          ),
          validator: validator,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ajouter un admin",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFB3D9FF),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _prenomController,
                label: 'Prénom',
                validator: (value) =>
                value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              _buildTextField(
                controller: _nomController,
                label: 'Nom',
                validator: (value) =>
                value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              _buildTextField(
                controller: _usernameController,
                label: 'Nom d\'utilisateur',
                validator: (value) =>
                value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Champ obligatoire';
                  } else if (!value.endsWith('@gmail.com')) {
                    return 'Email doit se terminer par @gmail.com';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                obscureText: true,
                validator: (value) =>
                value!.isEmpty ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addAdmin,
                icon: Icon(Icons.save),
                label: Text("Ajouter l'admin"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE8AAB4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
