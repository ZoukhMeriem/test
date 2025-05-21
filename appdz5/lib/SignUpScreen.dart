import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dztrainfay/HomePage.dart';
import 'package:dztrainfay/SignUpScreen.dart';
import 'package:dztrainfay/ForgotPasswordScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'Admin/AdminHomePage.dart';

// Import localisation
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  void handleGoogleSignIn() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user != null) {
        final userName = user.displayName ?? 'Utilisateur';
        final userEmail = user.email;
      }
    } catch (error) {
      print('Erreur de connexion Google : $error');
    }
  }
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> sendWelcomeEmailWithSendGrid(String email) async {
    const String sendGridApiKey = '';
    const String senderEmail = 'dztrains@gmail.com';

    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');

    final emailContent = {
      "personalizations": [
        {
          "to": [
            {"email": email}
          ],
          "subject": "Bienvenue sur DzTrain 🚄"
        }
      ],
      "from": {
        "email": senderEmail,
        "name": "DzTrain"
      },
      "content": [
        {
          "type": "text/html",
          "value": """
  <div style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
    <h2 style="color: #1976d2;">Bienvenue à bord de DzTrain 🚆</h2>
    <p>Bonjour,</p>
    <p>Merci de vous être inscrit sur <strong>DzTrain</strong> — votre compagnon pour voyager intelligemment à travers le réseau ferroviaire algérien.</p>
    <p>Avec notre application, vous pouvez :</p>
    <ul>
      <li>Rechercher des trajets et visualiser les horaires</li>
      <li>Suivre les trains en temps réel</li>
      <li>Recevoir des notifications sur les retards et annulations</li>
      <li>Discuter avec d'autres voyageurs</li>
    </ul>
    <p>Nous sommes ravis de vous compter parmi nous !</p>
    <hr style="border: none; border-top: 1px solid #ccc;">
    <p style="font-size: 12px; color: #888;">
      Cet e-mail vous a été envoyé suite à votre inscription sur DzTrain.<br>
      Si vous pensez avoir reçu ce message par erreur, veuillez l’ignorer ou contacter notre support.
    </p>
  </div>
"""

        }
      ]
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $sendGridApiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode(emailContent),
    );

    if (response.statusCode == 202) {
      print('✅ Email de bienvenue envoyé à $email');
    } else {
      print('❌ Erreur lors de l\'envoi: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        Navigator.of(context).pop();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.additionalUserInfo!.isNewUser) {
        print('🆕 Nouvel utilisateur détecté, envoi du mail...');
        final email = userCredential.user!.email!;
        await sendWelcomeEmailWithSendGrid(email);
      } else {
        print('👤 Utilisateur existant, pas de mail envoyé');
      }

      final username = userCredential.user?.displayName ?? 'Utilisateur';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);

      Navigator.of(context).pop();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(username: username),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      print("Erreur de connexion Google : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFA4C6A8),
                Color(0xFFF4D9DE),
                Color(0xFFDDD7E8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.23,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/signIn.jpg'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      _buildTextField(usernameController, loc.usernameHint, Icons.person),
                      SizedBox(height: 16.0),
                      _buildTextField(passwordController, loc.passwordHint, Icons.lock, isPassword: true),
                      SizedBox(height: 10.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            loc.forgotPassword,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () async {
                          final username = usernameController.text.trim();
                          final password = hashPassword(passwordController.text.trim());

                          try {
                            QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
                                .collection('Admin')
                                .where('Username', isEqualTo: username)
                                .where('Password', isEqualTo: password)
                                .get();

                            if (adminSnapshot.docs.isNotEmpty) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => AdminHomePage(adminUsername: username)),
                              );
                              return;
                            }

                            QuerySnapshot userSnapshot = await FirebaseFirestore.instance
                                .collection('User')
                                .where('username', isEqualTo: username)
                                .where('password', isEqualTo: password)
                                .get();

                            if (userSnapshot.docs.isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('CompteUser')
                                  .doc(username)
                                  .set({'loggedIn': true}, SetOptions(merge: true));

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isLoggedIn', true);
                              await prefs.setString('username', username);

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => HomePage(username: username)),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.invalidCredentials)),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${loc.loginError}: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0x998BB1FF),
                          padding: EdgeInsets.symmetric(horizontal: 110.0, vertical: 12.0),
                        ),
                        child: Text(
                          loc.signInButton,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      ElevatedButton.icon(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(child: CircularProgressIndicator()),
                          );

                          await signInWithGoogle(context);
                        },
                        icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                        label: Text(
                          loc.signInGoogle,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E1E1E),
                          padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0),
                        ),
                      ),
                      SizedBox(height: 30.0),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterPage()),
                          );
                        },
                        child: Text(
                          loc.noAccountSignUp,
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon,
      {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
        ),
      ),
    );
  }
}
