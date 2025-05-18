import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeleteAccountPage extends StatelessWidget {
  final String userId;

  const DeleteAccountPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0x998BB1FF);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.delete_account_icon_label),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              localizations.delete_account_confirmation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: Text(localizations.delete_account_button),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () => _supprimerCompte(context),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimerCompte(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      await FirebaseFirestore.instance.collection('User').doc(userId).delete();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.delete_account_error)),
      );
    }
  }
}
