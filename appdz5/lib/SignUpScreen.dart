import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:dztrainfay/SuccessPage.dart';

// Couleurs personnalisées avec le nouveau design pastel
const LinearGradient backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFA4C6A8), // Vert doux
    Color(0xFFF4D9DE), // Rose pâle
    Color(0xFFDDD7E8), // Violet clair
  ],
);

const Color primaryColor = Color(0x998BB1FF); // Indigo clair semi-transparent
const Color cardColor = Colors.white; // Fond des champs de texte
const Color textColor = Colors.black87; // Texte principal
const Color subtitleColor = Colors.grey; // Texte secondaire

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController autreEmploiController = TextEditingController();

  // Valeurs internes, utilisées pour enregistrer dans Firestore
  String selectedEmploi = "student";
  String selectedSexe = "male";
  bool _isPasswordVisible = false;

  // Méthodes pour récupérer les labels traduits selon la clé
  String getGenderLabel(String genderKey, AppLocalizations local) {
    switch (genderKey) {
      case 'male':
        return local.male;
      case 'female':
        return local.female;
      default:
        return '';
    }
  }

  String getEmploiLabel(String emploiKey, AppLocalizations local) {
    switch (emploiKey) {
      case 'student':
        return local.student;
      case 'employee':
        return local.employee;
      case 'other':
        return local.other;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      local.createAccount,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5), // Indigo
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      local.welcomeMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(prenomController, local.firstName)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(nomController, local.lastName)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(emailController, local.email, isEmail: true),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    local.gender,
                    selectedSexe,
                    [
                      {'value': 'male', 'label': local.male},
                      {'value': 'female', 'label': local.female},
                    ],
                        (val) => setState(() => selectedSexe = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    local.jobType,
                    selectedEmploi,
                    [
                      {'value': 'student', 'label': local.student},
                      {'value': 'employee', 'label': local.employee},
                      {'value': 'other', 'label': local.other},
                    ],
                        (val) => setState(() => selectedEmploi = val!),
                  ),
                  if (selectedEmploi == "other")
                    _buildTextField(autreEmploiController, local.specifyJob),
                  const SizedBox(height: 16),
                  _buildTextField(usernameController, local.username),
                  _buildTextField(passwordController, local.password, isPassword: true),
                  _buildTextField(confirmPasswordController, local.confirmPassword, isPassword: true, isConfirmPassword: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4,
                      ),
                      child: Text(local.createAccount, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false, bool isConfirmPassword = false, bool isEmail = false}) {
    final local = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textColor),
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: subtitleColor),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: subtitleColor,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "${local.enter} $label";
        }
        if (isEmail && !value.endsWith("@gmail.com")) {
          return local.validGmail;
        }
        if (isPassword && value.length < 6) {
          return local.passwordLength;
        }
        if (isConfirmPassword && value != passwordController.text) {
          return local.passwordMismatch;
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<Map<String, String>> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white,
      style: const TextStyle(color: textColor),
      items: items
          .map((item) => DropdownMenuItem(
        value: item['value'],
        child: Text(item['label']!, style: const TextStyle(color: textColor)),
      ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: subtitleColor),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }

  Future<void> _register() async {
    final local = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      try {
        String username = usernameController.text.trim();
        String emploiFinal = selectedEmploi == "other" ? autreEmploiController.text.trim() : selectedEmploi;

        await FirebaseFirestore.instance.collection('User').add({
          'prenom': prenomController.text.trim(),
          'nom': nomController.text.trim(),
          'email': emailController.text.trim(),
          'sexe': selectedSexe,
          'emploi': emploiFinal,
          'username': username,
          'password': passwordController.text.trim(),
        });

        await FirebaseFirestore.instance.collection('CompteUser').doc(username).set({
          'username': username,
          'password': passwordController.text.trim(),
          'loggedIn': true,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SuccessPage(username: username)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${local.creationError}: $e")),
        );
      }
    }
  }
}
