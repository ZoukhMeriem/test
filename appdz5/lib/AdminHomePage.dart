import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  final String adminUsername;

  const AdminHomePage({required this.adminUsername});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Administrateur'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Text(
          'Bienvenue admin : $adminUsername',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
