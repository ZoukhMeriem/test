import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // <-- import localisation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'lost_object_status_screen.dart';

const Color mainColor = Color(0x998BB1FF);

class LostObjectFormScreen extends StatefulWidget {
  @override
  _LostObjectFormScreenState createState() => _LostObjectFormScreenState();
}

class _LostObjectFormScreenState extends State<LostObjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _trainLineController = TextEditingController();
  final TextEditingController _trainNumberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  File? _image;
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child("lost_objects/$fileName.jpg");
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("❌ Erreur lors de l'upload de l'image : $e");
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final selectedDate = DateTime.parse(_dateController.text);
        final now = DateTime.now();

        if (selectedDate.isAfter(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ La date ne peut pas être dans le futur.")),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Date invalide.")),
        );
        return;
      }

      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      await FirebaseFirestore.instance.collection('lost_objects').add({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'trainLine': _trainLineController.text,
        'trainNumber': _trainNumberController.text,
        'date': _dateController.text,
        'imageUrl': imageUrl,
        'status': 'En cours de traitement',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.lostObjectForm_successMessage)),
      );
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.lostObjectForm_title),
        backgroundColor: mainColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(loc.lostObjectForm_nameLabel, Icons.business, _nameController, true),
              SizedBox(height: 15),
              _buildTextField(loc.lostObjectForm_descriptionLabel, Icons.description, _descriptionController, true),
              SizedBox(height: 15),
              _buildTextField(loc.lostObjectForm_trainLineLabel, Icons.train, _trainLineController, false),
              SizedBox(height: 15),
              _buildTextField(loc.lostObjectForm_trainNumberLabel, Icons.confirmation_number, _trainNumberController, false),
              SizedBox(height: 15),

              TextFormField(
                controller: _dateController,
                style: TextStyle(color: Colors.black), // Pour affichage en noir
                decoration: InputDecoration(
                  labelText: loc.lostObjectForm_dateLabel,
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.black87),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2030),
                  );

                  if (pickedDate != null) {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      final DateTime fullDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );

                      _dateController.text =
                      "${fullDateTime.year}-${_twoDigits(fullDateTime.month)}-${_twoDigits(fullDateTime.day)} "
                          "${_twoDigits(fullDateTime.hour)}:${_twoDigits(fullDateTime.minute)}";
                    }
                  }
                },
              ),


              SizedBox(height: 20),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black87.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(loc.lostObjectForm_addPhoto, style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ),

              if (_image != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Image.file(_image!, height: 150, fit: BoxFit.cover),
                ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(loc.lostObjectForm_sendButton, style: TextStyle(fontSize: 16, color: Colors.white)),
              ),

              SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LostObjectStatusScreen()));
                  },
                  child: Text(loc.lostObjectForm_consultLostObjects, style: TextStyle(color: Colors.black87, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool required) {
    final loc = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black), // ✅ label en noir
        prefixIcon: Icon(icon, color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: required
          ? (value) {
        if (value == null || value.isEmpty) {
          return loc.lostObjectForm_requiredField;
        }
        return null;
      }
          : null,
    );
  }
}
