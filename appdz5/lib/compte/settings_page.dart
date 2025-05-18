import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'delete_account_page.dart';
import 'package:dztrainfay/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(bool) toggleTheme;
  final Function(bool) toggleNotifications;
  final String selectedLanguage;
  final Function(String) changeLanguage;
  final bool isDarkMode;

  const SettingsPage({
    super.key,
    required this.userData,
    required this.toggleTheme,
    required this.toggleNotifications,
    required this.selectedLanguage,
    required this.changeLanguage,
    required this.isDarkMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool isDarkMode;
  bool areNotificationsEnabled = true;

  final Color primaryColor = const Color(0xFF998BB1FF);

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localizations.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserCard(user),
            const SizedBox(height: 24),
            _buildSettingsSection(localizations.account, [
              _buildTile(Icons.edit, localizations.editProfile, onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EditProfilePage(userData: widget.userData),
                ));
              }),
              _buildTile(Icons.lock, localizations.changePassword, onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChangePasswordPage(userId: user['id']),
                ));
              }),
              _buildTile(Icons.delete_forever, localizations.deleteAccount, onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DeleteAccountPage(userId: user['id']),
                ));
              }),
            ]),
            const SizedBox(height: 24),
            _buildSettingsSection(localizations.preferences, [
              _buildTile(Icons.language, localizations.changeLanguage,
                  subtitle: widget.selectedLanguage.toUpperCase(), onTap: () {
                    _showLanguageDialog(context);
                  }),


              SwitchListTile(
                secondary: Icon(Icons.notifications_active, color: Colors.black87),
                title: Text(localizations.notifications, style: const TextStyle(fontWeight: FontWeight.w500)),
                value: areNotificationsEnabled,
                activeColor: primaryColor,
                onChanged: (value) {
                  setState(() => areNotificationsEnabled = value);
                  widget.toggleNotifications(value);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangTile("Français", const Locale('fr')),
            _buildLangTile("English", const Locale('en')),
            _buildLangTile("العربية", const Locale('ar')),
          ],
        ),
      ),
    );
  }

  Widget _buildLangTile(String label, Locale locale) {
    return ListTile(
      title: Text(label),
      onTap: () async {
        Provider.of<LocaleProvider>(context, listen: false).setLocale(locale.languageCode);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language', locale.languageCode);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: primaryColor,
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        title: Text(
          "${user['prenom'] ?? ''} ${user['nom'] ?? ''}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        )),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          color: Theme.of(context).cardColor,
          child: Column(
            children: tiles.map((tile) => Column(
              children: [
                tile,
                if (tile != tiles.last) const Divider(height: 1),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
}
