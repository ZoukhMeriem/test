import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LogoutHelper {
  static Future<void> showLogoutDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.logout), // ex: "Déconnexion"
        content: Text(loc.confirmLogout), // ex: "Voulez-vous vraiment vous déconnecter ?"
        actions: [
          TextButton(
            child: Text(loc.cancel), // ex: "Annuler"
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(loc.logout), // ex: "Déconnexion"
            onPressed: () {
              Navigator.of(context).pop(); // Ferme la boîte de dialogue
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  static void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
