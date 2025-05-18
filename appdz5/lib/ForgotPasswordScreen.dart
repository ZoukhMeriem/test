import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'VerifyEmailScreen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  String generateResetCode() {
    Random random = Random();
    int code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  Future<void> sendResetCodeByEmail(String email, String code) async {
    const String sendGridApiKey = '';
    const String senderEmail = 'dztrains@gmail.com';

    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');

    final emailContent = {
      "personalizations": [
        {
          "to": [
            {"email": email}
          ],
          "subject": AppLocalizations.of(context)!.resetCodeEmailSubject,
        }
      ],
      "from": {
        "email": senderEmail,
      },
      "content": [
        {
          "type": "text/plain",
          "value": AppLocalizations.of(context)!.resetCodeEmailBody(code),
        }
      ],
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
      print(AppLocalizations.of(context)!.sendSuccess(email));
    } else {
      print(AppLocalizations.of(context)!.sendFailure('${response.statusCode} ${response.body}'));
    }
  }

  Future<void> sendResetCode() async {
    final email = emailController.text.trim();
    final loc = AppLocalizations.of(context)!;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.emptyEmailError)),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String code = generateResetCode();

      await FirebaseFirestore.instance.collection('PasswordResetCodes').doc(email).set({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await sendResetCodeByEmail(email, code);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(
            verificationCode: code,
            email: email,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.genericError(e.toString()))),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.forgotPasswordTitle,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0x998BB1FF),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x998BB1FF),
              Color(0xFFF4D9DE),
              Color(0xFFDDD7E8),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Icon(Icons.lock_reset_rounded, size: 80, color: Colors.black87),
              const SizedBox(height: 20),
              Text(
                loc.resetPasswordHeader,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                loc.enterEmailInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: loc.emailLabel,
                  labelStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.email, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0x998BB1FF)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: sendResetCode,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  loc.sendCodeButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0x998BB1FF),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
