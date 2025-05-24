import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lost_object_status_screen.dart';

const Color mainColor = Color(0x998BB1FF);

class LostObjectFormScreen extends StatefulWidget {
  @override
  _LostObjectFormScreenState createState() => _LostObjectFormScreenState();
}

class _LostObjectFormScreenState extends State<LostObjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _objectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _trainLineController = TextEditingController();
  final _stationController = TextEditingController();
  DateTime? _selectedDateTime;
  File? _pickedImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String docId) async {
    if (_pickedImage == null) return null;
    final ref = FirebaseStorage.instance.ref().child('lost_objects/$docId.jpg');
    await ref.putFile(_pickedImage!);
    return await ref.getDownloadURL();
  }

  Future<String?> getUsernameLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> _submitForm() async {
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final username = await getUsernameLocally();
      if (username == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Utilisateur non connecté.'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        // Ajout initial sans image
        final docRef = await FirebaseFirestore.instance.collection('lost_objects').add({
          'name': _objectNameController.text.trim(),
          'trainLine': _trainLineController.text.trim(),
          'description': _descriptionController.text.trim(),
          'station': _stationController.text.trim(),
          'date': _selectedDateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'status': 'En cours de traitement',
          'createdAt': Timestamp.now(),
          'username': username,
          'imageUrl': null, // sera mis à jour ensuite
        });

        // Upload image si présente
        final imageUrl = await _uploadImage(docRef.id);
        if (imageUrl != null) {
          await docRef.update({'imageUrl': imageUrl});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.lostObjectForm_successMessage), backgroundColor: Colors.green),
        );

        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LostObjectStatusScreen()));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.lostObjectForm_errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool required, {int maxLines = 1}) {
    final loc = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      validator: required
          ? (value) => value == null || value.isEmpty ? loc.lostObjectForm_requiredField : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black87),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(loc.lostObjectForm_objectName, Icons.business, _objectNameController, true),
              const SizedBox(height: 15),
              _buildTextField(loc.lostObjectForm_description, Icons.description, _descriptionController, true, maxLines: 3),
              const SizedBox(height: 15),
              _buildTextField(loc.lostObjectForm_trainLine, Icons.train, _trainLineController, true),
              const SizedBox(height: 15),
              _buildTextField(loc.lostObjectForm_station, Icons.location_on, _stationController, true),
              const SizedBox(height: 15),

              // Champ image
              Text(loc.lostObjectForm_imageLabel, style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 8),
              _pickedImage != null
                  ? Image.file(_pickedImage!, height: 150)
                  : Text(loc.lostObjectForm_noImageSelected),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: Text(loc.lostObjectForm_pickImage),
              ),
              const SizedBox(height: 15),

              // Date
              GestureDetector(
                onTap: _pickDateTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: loc.lostObjectForm_dateLabel,
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.black87),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      labelStyle: const TextStyle(color: Colors.black54),
                    ),
                    validator: (value) => _selectedDateTime == null ? loc.lostObjectForm_requiredField : null,
                    controller: TextEditingController(
                      text: _selectedDateTime == null
                          ? ''
                          : '${_selectedDateTime!.day.toString().padLeft(2, '0')}/'
                          '${_selectedDateTime!.month.toString().padLeft(2, '0')}/'
                          '${_selectedDateTime!.year} ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:'
                          '${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send),
                label: Text(loc.lostObjectForm_sendButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LostObjectStatusScreen()));
                  },
                  child: Text(loc.lostObjectForm_consultLostObjects, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
