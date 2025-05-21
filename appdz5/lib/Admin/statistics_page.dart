import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class StylishStatsScreen extends StatefulWidget {
  @override
  _StylishStatsScreenState createState() => _StylishStatsScreenState();
}

class _StylishStatsScreenState extends State<StylishStatsScreen> {
  int totalUsers = 0;
  int hommes = 0, femmes = 0;
  int etudiants = 0, employes = 0, chomeurs = 0;
  bool isLoading = true;
  double moyenneEvaluation = 0.0;
  int totalEvaluations = 0;
  Map<int, int> distributionNotes = {}; // 🗂️ pour compter les notes

  @override
  void initState() {
    super.initState();
    fetchStats();
  }


  Future<void> fetchStats() async {
    final snapshot = await FirebaseFirestore.instance.collection('User').get();
    final evalSnapshot = await FirebaseFirestore.instance.collection('Evaluations').get();

    int h = 0, f = 0;
    int e = 0, emp = 0, c = 0;
    double totalNotes = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final sexe = data['sexe'];
      final emploi = data['emploi'];

      if (sexe == 'Homme') h++;
      if (sexe == 'Femme') f++;

      if (emploi == 'Étudiant') e++;
      if (emploi == 'employee') emp++;
      if (emploi == 'Autres') c++;
    }
    for (var doc in evalSnapshot.docs) {
      final data = doc.data();
      final note = data['note'];
      if (note != null) {
        double noteValue = (note as num).toDouble();
        int roundedNote = noteValue.round(); // on arrondit à l'entier le plus proche (ex: 4.5 devient 5)

        if (distributionNotes.containsKey(roundedNote)) {
          distributionNotes[roundedNote] = distributionNotes[roundedNote]! + 1;
        } else {
          distributionNotes[roundedNote] = 1;
        }
        totalNotes += noteValue; // pour calcul de moyenne
      }
    }

    String getNotePercent(int stars) {
      if (totalEvaluations == 0) return "0%";
      int count = distributionNotes[stars] ?? 0;
      double percent = (count / totalEvaluations) * 100;
      return "${percent.toStringAsFixed(1)}%";
    }


    setState(() {
      totalUsers = snapshot.docs.length;
      hommes = h;
      femmes = f;
      etudiants = e;
      employes = emp;
      chomeurs = c;
      totalEvaluations = evalSnapshot.docs.length;
      moyenneEvaluation = totalEvaluations == 0 ? 0 : totalNotes / totalEvaluations;
      isLoading = false;
    });
  }
  Widget themeEtoilesProgressives(double moyenne) {
    int fullStars = moyenne.floor();
    bool halfStar = (moyenne - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: 30);
        } else if (index == fullStars && halfStar) {
          return Icon(Icons.star_half, color: Colors.amber, size: 30);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 30);
        }
      }),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🌞 mode clair
      appBar: AppBar(
        title: const Text("Statistiques", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFD5BA7F),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📦 Bloc SEXE
            _buildCardSection(
              title: "Répartition par sexe",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircle(
                      label: "${_percent(hommes)}%",
                      subtitle: "Hommes",
                      percent: _percentDouble(hommes),
                      colors: [Color(0xFFB5D5C5), Color(0xFFDEF1D8)], // Menthe pastel
                    ),
                    _buildCircle(
                      label: "${_percent(femmes)}%",
                      subtitle: "Femmes",
                      percent: _percentDouble(femmes),
                      colors: [Color(0xFFFADADD), Color(0xFFFFE4E1)], // Rose clair pastel
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 📦 Bloc EMPLOI
            _buildCardSection(
              title: "Répartition par emploi",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircle(
                      label: "${_percent(etudiants)}%",
                      subtitle: "Étudiants",
                      percent: _percentDouble(etudiants),
                      colors: [Color(0xFFFFF1CC), Color(0xFFFDE8D0)], // Jaune pêche
                    ),
                    _buildCircle(
                      label: "${_percent(employes)}%",
                      subtitle: "Employés",
                      percent: _percentDouble(employes),
                      colors: [Color(0xFFDBE6FD), Color(0xFFC2D9FF)], // Lavande pastel
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: _buildCircle(
                    label: "${_percent(chomeurs)}%",
                    subtitle: "Autres",
                    percent: _percentDouble(chomeurs),
                    colors: [Color(0xFFFFE4E1), Color(0xFFFFD6E8)], // Rose très clair
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildCardSection(
              title: "Évaluations des utilisateurs",
              children: [
                Center(
                  child: Column(
                    children: [
                      Center(
                        child: themeEtoilesProgressives(moyenneEvaluation)

                      ),
                      Text(
                        moyenneEvaluation > 0
                            ? "⭐ ${moyenneEvaluation.toStringAsFixed(1)} / 5"
                            : "Aucune évaluation disponible",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: moyenneEvaluation > 0 ? Colors.black : Colors.grey,
                        ),
                      ),
                      if (moyenneEvaluation > 0)
                        Text(
                          "$totalEvaluations évaluations reçues",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),


          ],
        ),
      ),
    );
  }

  /// 🔶 Bloc carte claire stylée
  Widget _buildCardSection({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCircle({
    required String label,
    required String subtitle,
    required double percent,
    required List<Color> colors,
  }) {
    return CircularPercentIndicator(
      radius: 70.0,
      lineWidth: 12.0,
      percent: percent.clamp(0.0, 1.0),
      animation: true,
      circularStrokeCap: CircularStrokeCap.round,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
      backgroundColor: Colors.grey.shade300,
      linearGradient: LinearGradient(colors: colors),
    );
  }

  String _percent(int value) {
    if (totalUsers == 0) return "0";
    return ((value / totalUsers) * 100).toStringAsFixed(0);
  }

  double _percentDouble(int value) {
    if (totalUsers == 0) return 0;
    return value / totalUsers;
  }
}
