import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'user_info_page.dart';
import 'settings_page.dart';
import 'support_page.dart';
import 'HoraireTrainPage.dart';
import 'logout_helper.dart';
import 'historique_trajets_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final Function(bool) toggleTheme;
  final Function(String) changeLanguage;
  final Function(bool) toggleNotifications;

  const ProfilePage({
    required this.username,
    required this.toggleTheme,
    required this.changeLanguage,
    required this.toggleNotifications,
    Key? key,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, String>? userData;
  String _language = 'fr';
  bool _isDark = false;

  final Color primaryColor = const Color(0xFF1E1E1E);

  final List<Color> gradientColors = [
    Color(0xFFF0F4F8),
    Color(0xFFD1D9E6),
    Color(0xFFA3BED8),
  ];

  final Color iconColor = Colors.black;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    loadThemePreference();
  }

  void loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void fetchUserData() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        setState(() {
          userData = {
            'id': doc.id,
            'username': doc['username'] ?? '',
            'email': doc['email'] ?? '',
            'nom': doc['nom'] ?? '',
            'prenom': doc['prenom'] ?? '',
            'emploi': doc['emploi'] ?? '',
            'sexe': doc['sexe'] ?? '',
          };
        });
      }
    } catch (e) {
      print("Erreur Firestore : $e");
    }
  }

  void changeLanguage(String language) {
    setState(() {
      _language = language;
    });
    widget.changeLanguage(language);
  }

  void toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);

    setState(() {
      _isDark = isDark;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MyApp(
          onboardingSeen: true,
          isLoggedIn: true,
          username: widget.username,
          isDarkMode: isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter, // ← Verticale
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        toolbarHeight: 150,
        title: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/logo3.png'),
            ),
            const SizedBox(height: 10),
            Text(
              userData?['username'] ?? local.unknownName,
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userData?['email'] ?? local.unknownEmail,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black87, Colors.black54]
                : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildListTile(Icons.person, local.personalInfo, () {
              if (userData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoPage(userData: userData!),
                  ),
                );
              }
            }, isDark),
            SwitchListTile(
              title: Text(local.darkMode,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              value: _isDark,
              onChanged: (value) {
                setState(() {
                  _isDark = value;
                });
                toggleTheme(value);
              },
              secondary: Icon(Icons.dark_mode, color: iconColor),
            ),
            _buildListTile(Icons.settings, local.settings, () {
              if (userData != null && userData!['username'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      userData: userData!,
                      changeLanguage: widget.changeLanguage,
                      toggleTheme: widget.toggleTheme,
                      toggleNotifications: widget.toggleNotifications,
                      selectedLanguage: _language,
                      isDarkMode: _isDark,
                    ),
                  ),
                );
              }
            }, isDark),
            _buildListTile(Icons.notifications, local.notifications, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(local.notificationsComingSoon)),
              );
            }, isDark),
            _buildListTile(Icons.history, local.favoriteTrips, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HistoriqueTrajetsPage()),
              );
            }, isDark),
            _buildListTile(Icons.train, local.trainSchedules, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HoraireTrainPage()),
              );
            }, isDark),
            _buildListTile(Icons.help_outline, local.support, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              );
            }, isDark),
            const Divider(),
            _buildListTile(Icons.logout, local.logout, () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    local.logout,
                    style:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  content: Text(local.logoutConfirmation),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(local.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(local.logout),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await logout(context);
              }
            }, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
      IconData icon, String title, VoidCallback onTap, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing:
      Icon(Icons.arrow_forward_ios, color: isDark ? Colors.white54 : Colors.grey),
      onTap: onTap,
    );
  }
}
