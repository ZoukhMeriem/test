import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'SimulationLocalePage.dart';
import 'tracage_page.dart'; // adapte le nom selon ton fichier réel

class GareIntermediaire {
  String gare;
  String heurePassage;
  int id;

  GareIntermediaire({
    required this.gare,
    required this.heurePassage,
    required this.id,
  });

  factory GareIntermediaire.fromMap(Map<String, dynamic> data) {
    return GareIntermediaire(
      gare: data["gare"],
      heurePassage: data["Heure_de_Passage"],
      id: data["id"] ?? 0,
    );
  }
}

class Trajet {
  String gareDepart;
  String gareArrivee;
  String heureDepart;
  String heureArrivee;
  int id;
  String lineId;
  String trainId;
  List<GareIntermediaire> garesIntermediaires;
  int? idDepart;
  int? idArrivee;
  final String jourDeCirculation;

  Trajet({
    required this.gareDepart,
    required this.gareArrivee,
    required this.heureDepart,
    required this.heureArrivee,
    required this.id,
    required this.lineId,
    required this.trainId,
    required this.garesIntermediaires,
    this.idDepart,
    this.idArrivee,
    required this.jourDeCirculation,
  });
}

// 🎯 Maintenant ta page devient un StatefulWidget
class ListeTrajetsScreen extends StatefulWidget {
  final String departure;
  final String destination;
  final DateTime date;

  ListeTrajetsScreen({
    required this.departure,
    required this.destination,
    required this.date,
  });

  @override
  _ListeTrajetsScreenState createState() => _ListeTrajetsScreenState();
}

class _ListeTrajetsScreenState extends State<ListeTrajetsScreen> {
  bool _isAscending = true;
  List<Trajet> _trajets = [];

  @override
  void initState() {
    super.initState();
    _fetchTrajets();
  }

  Future<void> _fetchTrajets() async {
    final nowTime = TimeOfDay.fromDateTime(widget.date);
    List<Trajet> fetchedTrajets = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('TRAJET1').get();
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<GareIntermediaire> garesIntermediaires = [];
        QuerySnapshot garesSnapshot = await doc.reference.collection('Gares_Intermédiaires').get();

        for (var gareDoc in garesSnapshot.docs) {
          garesIntermediaires.add(GareIntermediaire.fromMap(gareDoc.data() as Map<String, dynamic>));
        }

        final indexDepart = garesIntermediaires.indexWhere((g) => g.gare.toLowerCase().trim() == widget.departure.toLowerCase().trim());
        final indexArrivee = garesIntermediaires.indexWhere((g) => g.gare.toLowerCase().trim() == widget.destination.toLowerCase().trim());

        if (indexDepart != -1 && indexArrivee != -1 && indexDepart < indexArrivee) {
          final gareDepart = garesIntermediaires[indexDepart];
          final gareArrivee = garesIntermediaires[indexArrivee];

          final format = DateFormat("HH:mm");
          final heureTrajet = format.parse(gareDepart.heurePassage);
          final trajetTime = TimeOfDay.fromDateTime(heureTrajet);

          if (_isAfterOrEqual(trajetTime, nowTime)) {
            fetchedTrajets.add(
              Trajet(
                gareDepart: gareDepart.gare,
                gareArrivee: gareArrivee.gare,
                heureDepart: gareDepart.heurePassage,
                heureArrivee: gareArrivee.heurePassage,
                id: data["ID"] ?? 0,
                lineId: data["lineId"] ?? "Inconnue",
                trainId: data["trainId"] ?? "Inconnu",
                jourDeCirculation: data["Jour_de_Circulation"] ?? "Inconnue",
                garesIntermediaires: garesIntermediaires,
                idDepart: gareDepart.id,
                idArrivee: gareArrivee.id,
              ),
            );
          }
        }
      }
    } catch (e) {
      print("❌ Erreur Firestore: $e");
    }

    setState(() {
      _trajets = fetchedTrajets;
      _sortTrajets();
    });
  }

  bool _isAfterOrEqual(TimeOfDay a, TimeOfDay b) {
    return a.hour > b.hour || (a.hour == b.hour && a.minute >= b.minute);
  }

  void _sortTrajets() {
    _trajets.sort((a, b) {
      final timeA = DateFormat('HH:mm').parse(a.heureDepart);
      final timeB = DateFormat('HH:mm').parse(b.heureDepart);
      return _isAscending ? timeA.compareTo(timeB) : timeB.compareTo(timeA);
    });
  }

  String _calculerDuree(String heureDebut, String heureFin) {
    final format = DateFormat('HH:mm');
    final debut = format.parse(heureDebut);
    final fin = format.parse(heureFin);
    Duration diff = fin.difference(debut);
    if (diff.isNegative) diff += Duration(days: 1);

    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}min';
  }
  void _showDetailsBottomSheet(BuildContext context, Trajet trajet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "🛤️ Détail du trajet",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Graphique du trajet
              _buildTrajetGraphique(
                trajet.garesIntermediaires
                    .where((g) => g.id >= (trajet.idDepart ?? 0) && g.id <= (trajet.idArrivee ?? 0))
                    .toList(),
                trajet.garesIntermediaires.sublist(1, trajet.garesIntermediaires.length - 1),
                context,
              ),

              const SizedBox(height: 20),

              // Infos
              _buildInfoText(
                "Jour de Circulation:",
                trajet.jourDeCirculation.isNotEmpty ? trajet.jourDeCirculation : "Non spécifié",
              ),
              const SizedBox(height: 10),
              _buildInfoText("Prix:", "70 DA"),

              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFavoriserButton(context, trajet),
                  ElevatedButton.icon(

                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SimulationLocalePage(trajet: trajet),
                        ),
                      );
                    },


                    icon: Icon(Icons.check_circle_outline),
                    label: Text("Choisir ce trajet"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x998BB1FF),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                  // TextButton(
                  //onPressed: () => Navigator.pop(context),
                  //child: Text("Fermer"),
                  //style: TextButton.styleFrom(
                  //foregroundColor: Colors.blueGrey[700],
                  //),
                  //),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrajetGraphique(
      List<GareIntermediaire> etapes,
      List<GareIntermediaire> intermediaires,
      BuildContext context,
      ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: List.generate(etapes.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Ligne entre les icônes
              return Container(
                width: 50,
                height: 3,
                color: Color(0xFF353C67),
              );
            } else {
              int index = i ~/ 2;
              final isFirst = index == 0;
              final isLast = index == etapes.length - 1;
              final gare = etapes[index];

              IconData icon = isFirst || isLast
                  ? Icons.directions_train_rounded
                  : Icons.location_on_rounded;

              Color color = isFirst
                  ? Colors.green
                  : isLast
                  ? Colors.red
                  : Color(0xFF353C67);

              return _GareIconWithPopup(
                icon: icon,
                color: color,
                gareName: gare.gare,
                showName: isFirst || isLast,
              );
            }
          }),
        ),
      ),
    );
  }
  Widget _buildInfoText(String title, String content) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87, fontSize: 16),
          children: [
            TextSpan(text: "$title ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF353C67))),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }



  Widget _buildFavoriserButton(BuildContext context, Trajet trajet) {
    // Nous utilisons un FutureBuilder pour vérifier si le trajet est déjà favorisé
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('historique_trajets')
          .where('gareDepart', isEqualTo: trajet.gareDepart)
          .where('gareArrivee', isEqualTo: trajet.gareArrivee)
          .where('heureDepart', isEqualTo: trajet.heureDepart)
          .where('heureArrivee', isEqualTo: trajet.heureArrivee)
          .where('trainId', isEqualTo: trajet.trainId)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        bool isFavorised = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        String? docId = isFavorised ? snapshot.data!.docs.first.id : null;

        // On retourne le bouton avec un comportement instantané
        return ElevatedButton.icon(
          onPressed: () async {
            try {
              // Si le trajet est déjà favorisé, on le défavorise
              if (isFavorised && docId != null) {
                // Supprimer du Firestore
                await FirebaseFirestore.instance
                    .collection('historique_trajets')
                    .doc(docId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Trajet retiré des favoris.")),
                );
              } else {
                // Ajouter aux favoris dans Firestore
                await FirebaseFirestore.instance
                    .collection('historique_trajets')
                    .add({
                  'gareDepart': trajet.gareDepart,
                  'gareArrivee': trajet.gareArrivee,
                  'heureDepart': trajet.heureDepart,
                  'heureArrivee': trajet.heureArrivee,
                  'trainId': trajet.trainId,
                  'lineId': trajet.lineId,
                  'jourDeCirculation': trajet.jourDeCirculation,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("✅ Trajet ajouté aux favoris.")),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("❌ Erreur : $e")),
              );
            }
          },
          icon: Icon(
            isFavorised ? Icons.star : Icons.star_border,
            color: isFavorised ? Colors.white : Colors.black,
          ),
          label: Text(
            isFavorised ? "Favorisé" : "Favoriser",
            style: TextStyle(
              color: isFavorised ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFavorised
                ? Color(0xFF88A8BD) // Couleur pour un trajet favorisé
                : Color(0xFFF8D2D0), // Couleur pour un trajet non favorisé
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.departure} → ${widget.destination}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(widget.date),
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0x998BB1FF),
        actions: [
          IconButton(
            color: isDark ? Colors.white70 : const Color(0x8C000000),
            icon: Icon(_isAscending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
                _sortTrajets();
              });
            },
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.black : const Color(0xCBE9EBF3),
      body: Container(
        child: _trajets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _trajets.length,
          itemBuilder: (context, index) {
            final trajet = _trajets[index];
            final Color cardColor = isDark
                ? Colors.grey[850]!
                : (index % 2 == 0
                ? const Color(0xFFE8ECEAFF)
                : const Color(0xFFDDD7E8FF));

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/sntf_logo.png',
                          width: 60,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Trajet : ${trajet.id.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trajet.heureDepart,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Colors.grey, thickness: 1),
                        ),
                        Text(
                          _calculerDuree(trajet.heureDepart, trajet.heureArrivee),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Colors.grey, thickness: 1),
                        ),
                        Text(
                          trajet.heureArrivee,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trajet.gareDepart,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.indigo),
                        ),
                        Text(
                          trajet.gareArrivee,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.indigo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TRAIN: ${trajet.trainId}",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black,
                          ),
                        ),
                        Text(
                          "Ligne: ${trajet.lineId}",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.info_outline),
                        label: const Text("Voir détails"),
                        onPressed: () => _showDetailsBottomSheet(context, trajet),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0x998BB1FF),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
class _GareIconWithPopup extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String gareName;
  final bool showName; // true = nom affiché tout le temps (sous forme de texte simple)

  const _GareIconWithPopup({
    required this.icon,
    required this.color,
    required this.gareName,
    this.showName = false,
  });

  @override
  State<_GareIconWithPopup> createState() => _GareIconWithPopupState();
}

class _GareIconWithPopupState extends State<_GareIconWithPopup> {
  bool showPopup = false;

  void togglePopup() {
    setState(() => showPopup = true);
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) setState(() => showPopup = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.showName ? null : togglePopup,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.color, size: 24),

          // NOM EN DESSOUS pour les gares de départ/arrivée
          if (widget.showName)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                widget.gareName,
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),

          // Popup au clic pour gares intermédiaires
          if (!widget.showName && showPopup)
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pink[100],
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                widget.gareName,
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }
}
