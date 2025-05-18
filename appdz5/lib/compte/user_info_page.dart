import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserInfoPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserInfoPage({required this.userData, Key? key}) : super(key: key);

  final Color primaryColor = const Color(0x998BB1FF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          loc.userProfile,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, isDark, loc),
          const SizedBox(height: 20),
          _buildInfoTile(Icons.person, loc.name, userData['nom'] ?? loc.notProvided, isDark),
          _buildInfoTile(Icons.badge, loc.surname, userData['prenom'] ?? loc.notProvided, isDark),
          _buildInfoTile(Icons.account_circle, loc.username, userData['username'] ?? loc.notProvided, isDark),
          _buildInfoTile(Icons.email, loc.email, userData['email'] ?? loc.notProvided, isDark),
          _buildInfoTile(Icons.wc, loc.gender, getLocalizedGender(userData['sexe'], context), isDark),
          _buildInfoTile(Icons.work, loc.job, userData['emploi'] ?? loc.notProvided, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalizations loc) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor.withOpacity(0.2),
          child: Icon(Icons.person, size: 50, color: isDark ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 12),
        Text(
          (userData['nom'] != null && userData['prenom'] != null)
              ? "${userData['prenom']} ${userData['nom']}"
              : loc.unknownUser,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, bool isDark) {
    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: isDark ? Colors.white : Colors.black),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  String getLocalizedGender(String? sexe, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (sexe?.toUpperCase()) {
      case 'M':
        return loc.male;
      case 'F':
        return loc.female;
      default:
        return loc.unknown;
    }
  }
}
