import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance
        .collection('User')
        .orderBy('username');

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Utilisateurs'),
        backgroundColor: Color(0xFFB3D9FF),
      ),
      body: Column(
        children: [
          // 🔍 Recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: TextStyle(color: Colors.black), // ✅ Texte saisi en noir
              decoration: InputDecoration(
                hintText: 'Rechercher par username...',
                hintStyle: TextStyle(color: Colors.grey), // ✅ Placeholder en gris
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.search, color: Colors.black), // ✅ Icône noire
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),


          // 👥 Liste utilisateurs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  final username = (doc['username'] ?? '').toString().toLowerCase();
                  return username.contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return Center(child: Text('Aucun utilisateur trouvé.'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFE8AAB4),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text("${user['prenom']} ${user['nom']}"),
                        subtitle: Text("Username: ${user['username']}"),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailsScreen(user: user),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class UserDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot user;

  UserDetailsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    final data = user.data() as Map<String, dynamic>;

    Widget infoTile(String title, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueGrey),
            SizedBox(width: 10),
            Text(
              "$title : ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(value.isNotEmpty ? value : 'N/A'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Détails de l'utilisateur"),
        backgroundColor: Color(0xFFB3D9FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            infoTile("Nom", data['nom'] ?? '', Icons.person),
            infoTile("Prénom", data['prenom'] ?? '', Icons.person_outline),
            infoTile("Email", data['email'] ?? '', Icons.email),
            infoTile("Username", data['username'] ?? '', Icons.account_circle),
            infoTile("Sexe", data['sexe'] ?? '', Icons.wc),
            infoTile("Emploi", data['emploi'] ?? '', Icons.work),
            infoTile("Mot de passe", "••••••••", Icons.lock_outline),


          SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text("Supprimer l'utilisateur"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Confirmation"),
                      content: Text("Voulez-vous vraiment supprimer cet utilisateur ?"),
                      actions: [
                        TextButton(
                          child: Text("Annuler"),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        ElevatedButton(
                          child: Text("Supprimer"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  );

                  if (confirm) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('User')
                          .doc(user.id)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Utilisateur supprimé avec succès.')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors de la suppression.')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
