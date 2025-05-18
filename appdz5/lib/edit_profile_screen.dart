import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'SignInScreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController prenomController;
  late TextEditingController nomController;
  late TextEditingController emailController;
  late TextEditingController emploiController;
  late TextEditingController passwordController;
  late TextEditingController usernameController;
  String selectedSexe = "Homme";
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    prenomController = TextEditingController(text: widget.userData['prenom']);
    nomController = TextEditingController(text: widget.userData['nom']);
    emailController = TextEditingController(text: widget.userData['email']);
    emploiController = TextEditingController(text: widget.userData['emploi']);
    passwordController = TextEditingController(text: widget.userData['password']);
    usernameController = TextEditingController(text: widget.userData['username']);
    selectedSexe = widget.userData['sexe'] ?? "Homme";
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('User').doc(widget.userData['email']).update({
          'prenom': prenomController.text.trim(),
          'nom': nomController.text.trim(),
          'email': emailController.text.trim(),
          'sexe': selectedSexe,
          'emploi': emploiController.text.trim(),
          'username': usernameController.text.trim(),
          'password': passwordController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.updateError}: $e')),
        );
      }
    }
  }

  void deleteAccount() async {
    try {
      String email = widget.userData['email'];
      await FirebaseFirestore.instance.collection('User').doc(email).delete();
      await FirebaseAuth.instance.currentUser?.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.accountDeleted)),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.deleteError}: $e')),
      );
    }
  }

  void _showEditDialog(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(local.editProfileTitle),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nomController, local.lastName, Icons.person),
                  _buildTextField(prenomController, local.firstName, Icons.person),
                  _buildTextField(emailController, local.email, Icons.email),
                  _buildTextField(emploiController, local.job, Icons.work),
                  DropdownButtonFormField<String>(
                    value: selectedSexe,
                    items: [local.male, local.female]
                        .map((label) => DropdownMenuItem(
                      child: Text(label),
                      value: label,
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSexe = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: local.gender),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text(local.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(local.save),
              onPressed: () {
                updateProfile();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredField : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(local.editProfile),
        backgroundColor: const Color(0x998BB1FF),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showEditDialog(context),
          child: Text(local.editProfile),
        ),
      ),
    );
  }
}
