import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const LinearGradient backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFF0F4F8),
    Color(0xFFD1D9E6),
    Color(0xFFA3BED8),
  ],
);

const Color primaryColor = Color(0xFF5677A3);
const Color cardColorConst = Colors.white;
const Color textColor = Colors.black87;
const Color subtitleColor = Colors.grey;

class LostObjectStatusScreen extends StatefulWidget {
  @override
  _LostObjectStatusScreenState createState() => _LostObjectStatusScreenState();
}

class _LostObjectStatusScreenState extends State<LostObjectStatusScreen> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    String name = await getUserNameLocally();
    setState(() {
      username = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (username == null) {
      // En attendant la récupération du username
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.lostObjectStatus_title),
          backgroundColor: primaryColor,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.lostObjectStatus_title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 3,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lost_objects')
              .where('username', isEqualTo: username) // filtre sur le username
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading(loc);
            }
            if (snapshot.hasError) {
              return _buildError(loc, snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmpty(loc);
            }

            final lostObjects = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: lostObjects.length,
              itemBuilder: (context, index) {
                final data = lostObjects[index].data() as Map<String, dynamic>;
                final objectName = data['name'] ?? loc.unknown_name;
                final status = data['status'] ?? 'en cours';
                final description = data['description'] ?? loc.no_description;
                final date = data['date'] ?? loc.unknown_date;
                final imageUrl = data['imageUrl'];

                return _buildLostObjectCard(
                  objectName,
                  description,
                  date,
                  status,
                  imageUrl,
                  loc,
                  isDark,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLostObjectCard(
      String name,
      String description,
      String date,
      String status,
      String? imageUrl,
      AppLocalizations loc,
      bool isDark,
      ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: cardColorConst,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            _buildImage(imageUrl),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loc.lostObjectStatus_descriptionLabel}: $description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loc.lostObjectStatus_dateLabel}: $date',
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStatusBadge(status, loc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: imageUrl != null
          ? Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      )
          : Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations loc) {
    Color badgeColor;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'trouvé':
      case 'found':
        badgeColor = Colors.green;
        displayStatus = loc.status_found;
        break;
      case 'non trouvé':
      case 'not found':
        badgeColor = Colors.red;
        displayStatus = loc.status_notFound;
        break;
      default:
        badgeColor = primaryColor.withOpacity(0.5);
        displayStatus = loc.status_inProgress;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            displayStatus,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            loc.loading_text,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations loc, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '${loc.error_prefix} $error',
          style: const TextStyle(color: Colors.red, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            loc.lostObjectStatus_noObjects,
            style: TextStyle(fontSize: 16, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}



Future<String> getUserNameLocally() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('username') ?? '';
}

