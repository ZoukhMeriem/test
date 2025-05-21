import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'lost_object_status_screen.dart';

const Color mainColor = Color(0x998BB1FF);

class LostObjectFormScreen extends StatefulWidget {
  @override
  _LostObjectFormScreenState createState() => _LostObjectFormScreenState();
}

class _LostObjectFormScreenState extends State<LostObjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _objectNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _trainLineController = TextEditingController();
  final TextEditingController _stationController = TextEditingController();
  DateTime? _selectedDateTime;

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
        initialTime: _selectedDateTime != null
            ? TimeOfDay.fromDateTime(_selectedDateTime!)
            : TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    final loc = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('lost_objects').add({
          'name': _objectNameController.text.trim(),
          'trainLine': _trainLineController.text.trim(),
          'description': _descriptionController.text.trim(),
          'station': _stationController.text.trim(),
          'date': _selectedDateTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'status': 'En cours de traitement',
          'createdAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.lostObjectForm_successMessage),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LostObjectStatusScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.lostObjectForm_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

              GestureDetector(
                onTap: _pickDateTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    style: const TextStyle(color: Colors.black87), // <-- couleur texte forcée
                    decoration: InputDecoration(
                      labelText: loc.lostObjectForm_dateLabel,
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.black87),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      labelStyle: const TextStyle(color: Colors.black54),
                    ),
                    validator: (value) {
                      if (_selectedDateTime == null) {
                        return loc.lostObjectForm_requiredField;
                      }
                      return null;
                    },
                    controller: TextEditingController(
                      text: _selectedDateTime == null
                          ? ''
                          : '${_selectedDateTime!.day.toString().padLeft(2, '0')}/'
                          '${_selectedDateTime!.month.toString().padLeft(2, '0')}/'
                          '${_selectedDateTime!.year} '
                          '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:'
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
                  child: Text(
                    loc.lostObjectForm_consultLostObjects,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool required, {int maxLines = 1}) {
    final loc = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87), // <-- couleur texte forcée
      validator: required
          ? (value) {
        if (value == null || value.isEmpty) {
          return loc.lostObjectForm_requiredField;
        }
        return null;
      }
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
