import 'package:flutter/material.dart';
import 'package:dztrainfay/Admin/train_management_screen.dart';
import 'AdminListScreen.dart';
import 'AdminLostObjectsScreen.dart';
import 'GareListScreen.dart';
import 'LigneListScreen.dart';
import 'UserListScreen.dart';
import 'trajet_management_screen.dart';
import 'statistics_page.dart';
import 'package:dztrainfay/SignInScreen.dart';

class AdminHomePage extends StatelessWidget {
  final String adminUsername;

  const AdminHomePage({required this.adminUsername});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        elevation: 4,
        title: const Text(
          'Espace Administrateur',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    adminUsername,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E6D6),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.waving_hand_rounded, color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "Bienvenue ",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: adminUsername,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111213),
                            ),
                          ),
                          const TextSpan(
                            text: " \nHeureux de vous revoir dans votre tableau de bord.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _buildMenuButton(
                    context: context,
                    label: "Gérer les Admins",
                    screen: AdminListScreen(),
                    icon: Icons.admin_panel_settings,
                    color: const Color(0xFF1E1E1E),
                  ),
                  _buildMenuButton(
                    context: context,
                    label: "Gérer les Gares",
                    screen: GareManagementScreen(),
                    icon: Icons.train,
                    color: const Color(0xFFECD6A6),
                  ),
                  _buildMenuButton(
                    context: context,
                    label: "Gérer les Lignes",
                    screen: LigneManagementScreen(),
                    icon: Icons.timeline,
                    color: const Color(0x998BB1FF),
                  ),
                  _buildMenuButton(
                    context: context,
                    label: "Gérer les Voyageurs",
                    screen: UserListScreen(),
                    icon: Icons.people,
                    color: const Color(0xFF88A8BD),
                  ),
                  _buildMenuButton(
                    context: context,
                    label: "Gérer les Trains",
                    screen: TrainManagementScreen(),
                    icon: Icons.directions_train,
                    color: const Color(0xFFF8D2D0),
                  ),
                  _buildMenuButton(
                    context: context,
                    label: "Gérer les Trajets",
                    screen: AdminTrajetsPage(),
                    icon: Icons.alt_route,
                    color: const Color(0xFF78957C),
                  ),
                  _buildMenuButton(
                    context: context,
                    label: "Voir les Statistiques",
                    screen: StylishStatsScreen (),//StatistiquesScreen(),
                    icon: Icons.bar_chart,
                    color: const Color(0xFFB3A0F1),
                  ),
                  _buildMenuButton(
                    context: context,
                    label: "Objets Perdus",
                    screen: AdminLostObjectsScreen(),
                    icon: Icons.search, // ou Icons.backpack, Icons.inventory, selon le style voulu
                    color: const Color(0xFFF4D9DE),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required Widget screen,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _navigateTo(context, screen),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
