import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LostObjectStatusScreen extends StatelessWidget {
  final Color mainColor = const Color(0xFFA4C6A8); // vert doux
  final Color backgroundColor = const Color(0xFFF4D9DE); // rose pâle
  final Color cardColor = const Color(0xFFFDFBFD); // blanc léger
  final Color badgeInProgress = const Color(0xFFDDD7E8); // violet clair

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.lostObjectStatus_title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: mainColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 3,
      ),
      backgroundColor: isDark ? Colors.black : backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lost_objects').snapshots(),
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
      color: isDark ? Colors.grey[850] : cardColor,
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
                      color: isDark ? Colors.white : mainColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loc.lostObjectStatus_descriptionLabel}: $description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${loc.lostObjectStatus_dateLabel}: $date',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
        badgeColor = badgeInProgress;
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
          Text(loc.loading_text),
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
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
