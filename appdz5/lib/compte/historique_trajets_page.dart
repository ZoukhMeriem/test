import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HistoriqueTrajetsPage extends StatefulWidget {
  const HistoriqueTrajetsPage({super.key});

  @override
  State<HistoriqueTrajetsPage> createState() => _HistoriqueTrajetsPageState();
}

class _HistoriqueTrajetsPageState extends State<HistoriqueTrajetsPage> {
  String _searchText = "";
  String _selectedLine = "Toutes les lignes";
  String _selectedJour = "Tous les jours";

  List<String> lignesDisponibles = ["Toutes les lignes"];
  final List<String> joursDisponibles = [
    "Tous les jours",
    "Week-ends et Jours fériés uniquement",
    "Tous les jours sauf week-ends"
  ];

  @override
  void initState() {
    super.initState();
    _fetchLignesFromFirestore();
  }

  Future<void> _fetchLignesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('LIGNE').get();
    final nomsLignes = snapshot.docs
        .map((doc) => doc.data()['nom']?.toString())
        .where((nom) => nom != null)
        .cast<String>()
        .toList();
    setState(() {
      lignesDisponibles = [AppLocalizations.of(context)!.allLines, ...nomsLignes];
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedLine = AppLocalizations.of(context)!.allLines;
      _selectedJour = AppLocalizations.of(context)!.allDays;
    });
  }

  void _openFiltersBottomSheet() {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.filters,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => _selectFromList(
                  title: AppLocalizations.of(context)!.selectLine,
                  options: lignesDisponibles,
                  selectedValue: _selectedLine,
                  onSelected: (val) {
                    setState(() => _selectedLine = val);
                  },
                ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.filterByLine,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.train),
                  ),
                  child: Text(
                    _selectedLine,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => _selectFromList(
                  title: AppLocalizations.of(context)!.selectDay,
                  options: joursDisponibles,
                  selectedValue: _selectedJour,
                  onSelected: (val) {
                    setState(() => _selectedJour = val);
                  },
                ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.filterByDay,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedJour,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  _resetFilters();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.resetFilters),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8AAB4),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectFromList({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text(option),
                    trailing: selectedValue == option
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0x998BB1FF);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myFavoriteTrips,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchStationHint,
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _openFiltersBottomSheet,
                  icon: const Icon(Icons.filter_list, color: Colors.black),
                  label: Text(
                    AppLocalizations.of(context)!.filters,
                    style: const TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x998BB1FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('historique_trajets')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("${AppLocalizations.of(context)!.error} : ${snapshot.error}",
                          style: const TextStyle(color: Colors.black)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;
                final trajets = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final gareDepart = data['gareDepart']?.toString().toLowerCase() ?? '';
                  final gareArrivee = data['gareArrivee']?.toString().toLowerCase() ?? '';
                  final line = data['lineId'] ?? '';
                  final jour = data['jourDeCirculation'] ?? '';

                  final matchesSearch = gareDepart.contains(_searchText) || gareArrivee.contains(_searchText);
                  final matchesLine = _selectedLine == AppLocalizations.of(context)!.allLines || _selectedLine == line;
                  final matchesJour = _selectedJour == AppLocalizations.of(context)!.allDays || _selectedJour == jour;

                  return matchesSearch && matchesLine && matchesJour;
                }).toList();

                if (trajets.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noFavoriteTripsFound,
                        style: const TextStyle(color: Colors.black)),
                  );
                }

                return ListView.builder(
                  itemCount: trajets.length,
                  itemBuilder: (context, index) {
                    final doc = trajets[index];
                    final trajet = doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: index.isEven ? const Color(0xFFEDF6EF) : const Color(0xFFD8E8FA),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: const Icon(Icons.train, color: Color(0xFF353C67), size: 30),
                        title: Text(
                          "${trajet['gareDepart']} → ${trajet['gareArrivee']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                                "${AppLocalizations.of(context)!.time} ${trajet['heureDepart']} → ${trajet['heureArrivee']}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text("${AppLocalizations.of(context)!.line} : ${trajet['lineId']}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text("${AppLocalizations.of(context)!.jourDeCirculation} : ${trajet['jourDeCirculation']}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
