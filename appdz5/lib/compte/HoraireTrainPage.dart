import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HoraireTrainPage extends StatefulWidget {
  @override
  _HoraireTrainPageState createState() => _HoraireTrainPageState();
}

class _HoraireTrainPageState extends State<HoraireTrainPage> {
  final Color primaryColor = const Color(0x998BB1FF);
  final Color rowColor1 = const Color(0xFFE8ECEAFF);
  final Color rowColor2 = const Color(0xFFDDD7E8FF);
  final Color resetButtonColor = const Color(0xFFF8D2D0);
  final Color applyButtonColor = const Color(0x998BB1FF);

  TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  // Variables pour tri et ordre
  String _tri = 'Aucun';
  bool _ordreCroissant = true;

  // Variables pour filtre horaire
  TimeOfDay? _heureMin;
  TimeOfDay? _heureMax;

  // Variables pour les couleurs des boutons sélectionnés
  bool isOrderSelected = false;
  bool isTriSelected = false;
  bool isTimeRangeSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tableau des trajets",
          style: TextStyle(color: Colors.black87), // Définit le texte en noir
        ),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Ligne recherche et tri
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Recherche...',
                      labelStyle: TextStyle(color: Colors.black),
                      prefixIcon: Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchFilter = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _showFilterModal(context),
                    child: Text("Filtrer", style: TextStyle(color: Colors.white)),
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(primaryColor)),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Affichage des trajets
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('TRAJET1').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final trajets = snapshot.data!.docs;

                  int? _timeOfDayToMinutes(TimeOfDay? t) =>
                      t != null ? t.hour * 60 + t.minute : null;

                  final int? minMinutes = _heureMin != null ? _timeOfDayToMinutes(_heureMin) : null;
                  final int? maxMinutes = _heureMax != null ? _timeOfDayToMinutes(_heureMax) : null;

                  // Filtrage par heure
                  final filtered = trajets.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final heureDepartStr = data["Heure_de_Départ"] ?? '';

                    final heureDepartMinutes = _parseTimeToMinutes(heureDepartStr);
                    if (heureDepartMinutes == null) return false;

                    if (minMinutes != null && heureDepartMinutes < minMinutes) return false;
                    if (maxMinutes != null && heureDepartMinutes > maxMinutes) return false;

                    // Autres filtres (recherche)
                    final all = data.values.map((e) => e.toString().toLowerCase()).join(' ');
                    return all.contains(_searchFilter);
                  }).toList();

                  // Tri par heure
                  if (_tri == 'Heure') {
                    filtered.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;

                      final ha = dataA["Heure_de_Départ"] ?? '';
                      final hb = dataB["Heure_de_Départ"] ?? '';

                      final haMin = _parseTimeToMinutes(ha);
                      final hbMin = _parseTimeToMinutes(hb);

                      if (haMin == null || hbMin == null) return 0;

                      return _ordreCroissant ? haMin.compareTo(hbMin) : hbMin.compareTo(haMin);
                    });
                  } else if (_tri == 'Ligne') {
                    filtered.sort((a, b) {
                      final la = a['lineId'] ?? '';
                      final lb = b['lineId'] ?? '';
                      return la.compareTo(lb);
                    });
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(primaryColor),
                      headingTextStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Départ')),
                        DataColumn(label: Text('Arrêt')),
                        DataColumn(label: Text("Heure d'Arrivée")),
                        DataColumn(label: Text("Heure de Départ")),
                        DataColumn(label: Text('Train')),
                        DataColumn(label: Text('Ligne')),
                        DataColumn(label: Text('Jour de Circulation')),
                      ],
                      rows: List.generate(filtered.length, (index) {
                        final trajet = filtered[index].data() as Map<String, dynamic>;
                        return DataRow(
                          color: MaterialStateColor.resolveWith((states) => index.isEven ? rowColor1 : rowColor2),
                          cells: [
                            DataCell(Text('${trajet['ID'] ?? ''}')),
                            DataCell(Text('${trajet['Depart'] ?? ''}')),
                            DataCell(Text('${trajet['Aret'] ?? ''}')),
                            DataCell(Text('${trajet["Heure_d\'Arrivée"] ?? ''}')),
                            DataCell(Text('${trajet["Heure_de_Départ"] ?? ''}')),
                            DataCell(Text('${trajet['trainId'] ?? ''}')),
                            DataCell(Text('${trajet['lineId'] ?? ''}')),
                            DataCell(Text('${trajet['Jour_de_Circulation'] ?? ''}')),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour afficher le modal de filtrage
  Future<void> _showFilterModal(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ordre de tri
              Text("Ordre de Tri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isOrderSelected = true;
                        isTriSelected = false;
                        isTimeRangeSelected = false;
                        _ordreCroissant = true;
                      });
                    },
                    child: Text("Croissant"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(isOrderSelected ? rowColor2 : rowColor1)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isOrderSelected = true;
                        isTriSelected = false;
                        isTimeRangeSelected = false;
                        _ordreCroissant = false;
                      });
                    },
                    child: Text("Décroissant"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(isOrderSelected ? rowColor2 : rowColor1)),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Tri
              Text("Tri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isTriSelected = true;
                        isOrderSelected = false;
                        isTimeRangeSelected = false;
                        _tri = 'Aucun';
                      });
                    },
                    child: Text("Aucun"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(isTriSelected ? rowColor2 : rowColor1)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isTriSelected = true;
                        isOrderSelected = false;
                        isTimeRangeSelected = false;
                        _tri = 'Heure';
                      });
                    },
                    child: Text("Heure"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(isTriSelected ? rowColor2 : rowColor1)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isTriSelected = true;
                        isOrderSelected = false;
                        isTimeRangeSelected = false;
                        _tri = 'Ligne';
                      });
                    },
                    child: Text("Ligne"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(isTriSelected ? rowColor2 : rowColor1)),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Plage horaire
              Text("Plage Horaire", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              Row(
                children: [
                  Text("Heure Départ Min : "),
                  TextButton(
                    onPressed: () => _selectTime(context, true),
                    child: Text(
                      _heureMin != null ? _heureMin!.format(context) : "Sélectionner",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Heure Départ Max : "),
                  TextButton(
                    onPressed: () => _selectTime(context, false),
                    child: Text(
                      _heureMax != null ? _heureMax!.format(context) : "Sélectionner",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Boutons de réinitialisation et appliquer les filtres
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Réinitialiser les filtres
                        _searchFilter = '';
                        _tri = 'Aucun';
                        _ordreCroissant = true;
                        _heureMin = null;
                        _heureMax = null;
                      });
                    },
                    child: Text("Réinitialiser"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(resetButtonColor)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        // Appliquer les filtres
                      });
                    },
                    child: Text("Appliquer les filtres"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(applyButtonColor)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Fonction pour ouvrir le sélecteur d'heure
  Future<void> _selectTime(BuildContext context, bool isMin) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMin) {
          _heureMin = picked;
        } else {
          _heureMax = picked;
        }
      });
    }
  }

  // Convertir l'heure en minutes
  int? _parseTimeToMinutes(String heure) {
    final parts = heure.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      if (hours != null && minutes != null) {
        return hours * 60 + minutes;
      }
    }
    return null;
  }
}
