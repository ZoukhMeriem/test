import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTrajetsPage extends StatefulWidget {
  @override
  _AdminTrajetsPageState createState() => _AdminTrajetsPageState();
}

class _AdminTrajetsPageState extends State<AdminTrajetsPage> {
  int _selectedIndex = 0;

  final TextEditingController departController = TextEditingController();
  final TextEditingController aretController = TextEditingController();
  final TextEditingController heureDepartController = TextEditingController();
  final TextEditingController heureArriveeController = TextEditingController();
  final TextEditingController jourController = TextEditingController();

  List<Map<String, dynamic>> garesIntermediaires = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildTrajetsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('TRAJET1').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final trajets = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Liste des trajets disponibles :",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: trajets.length,
                itemBuilder: (context, index) {
                  final trajet = trajets[index];
                  final Color backgroundColor = index.isEven
                      ? Color(0xFFE6F4EA)
                      : Color(0xFFB3D9FF);

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(
                        "Trajet ID : ${trajet.id}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        "${trajet['Depart']} ➔ ${trajet['Aret']}",
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () => _modifierTrajet(trajet),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _confirmerSuppressionTrajet(trajet.id),
                          ),
                        ],
                      ),
                      onTap: () => _showTrajetDetails(context, trajet),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }


  void _modifierTrajet(QueryDocumentSnapshot trajet) async {
    OverlayEntry? overlayEntry;

    final heureDepCtrl = TextEditingController(text: trajet['Heure_de_Départ']);
    final heureArrCtrl = TextEditingController(text: trajet["Heure_d'Arrivée"]);
    final trainIdCtrl = TextEditingController(text: trajet['trainId'] ?? '');
    final jourCtrl = TextEditingController(text: trajet['Jour_de_Circulation'] ?? '');

    final gareSnapshot = await FirebaseFirestore.instance.collection('Gare').get();
    final ligneSnapshot = await FirebaseFirestore.instance.collection('LIGNE').get();

    final gares = gareSnapshot.docs.map((doc) => doc['name'].toString()).toList();
    final lignes = ligneSnapshot.docs.map((doc) => doc['nom'].toString()).toList();

    String? selectedDepart = trajet['Depart'];
    String? selectedAret = trajet['Aret'];
    String? selectedLigne = trajet['lineId'];

    overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(builder: (context, setOverlayState) {
          return Center(
            child: Material(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 350,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            "Modifier le Trajet",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 16),
                        Divider(),

                        _customDropdownField(
                          context: context,
                          label: "Départ",
                          value: selectedDepart,
                          options: gares,
                          onChanged: (val) => setOverlayState(() => selectedDepart = val),
                        ),
                        SizedBox(height: 12),

                        _customDropdownField(
                          context: context,
                          label: "Arrêt",
                          value: selectedAret,
                          options: gares,
                          onChanged: (val) => setOverlayState(() => selectedAret = val),
                        ),
                        _customDropdownField(
                          context: context,
                          label: "Ligne",
                          value: selectedLigne,
                          options: lignes,
                          onChanged: (val) => setOverlayState(() => selectedLigne = val),
                        ),
                        SizedBox(height: 12),

                        _buildTextField("Heure de Départ", heureDepCtrl),
                        SizedBox(height: 12),

                        _buildTextField("Heure d'Arrivée", heureArrCtrl),
                        SizedBox(height: 12),
                        _buildTextField("Jour de circulation", jourCtrl),

                        SizedBox(height: 12),


                        SizedBox(height: 12),

                        _buildTextField("Train ID", trainIdCtrl),
                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => overlayEntry?.remove(),
                              child: Text("Annuler", style: TextStyle(color: Colors.red)),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('TRAJET1')
                                    .doc(trajet.id)
                                    .update({
                                  'Depart': selectedDepart,
                                  'Aret': selectedAret,
                                  'Heure_de_Départ': heureDepCtrl.text,
                                  "Heure_d'Arrivée": heureArrCtrl.text,
                                  'Jour_de_Circulation': jourCtrl.text,
                                  'lineId': selectedLigne,
                                  'trainId': trainIdCtrl.text,
                                });
                                overlayEntry?.remove();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Trajet modifié avec succès.")),
                                );
                              },
                              child: Text("Enregistrer"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }

  void showDropdownOverlay({
    required BuildContext context,
    required Rect targetRect,
    required List<String> options,
    required void Function(String) onSelect,
  }) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: () => overlayEntry?.remove(), // clic hors liste
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned(
                left: targetRect.left,
                top: targetRect.bottom + 8,
                width: targetRect.width,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 300, // hauteur max avant scroll
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: options.map((option) {
                                return ListTile(
                                  title: Text(option),
                                  onTap: () {
                                    onSelect(option);
                                    overlayEntry?.remove();
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Divider(height: 0),
                        TextButton.icon(
                          onPressed: () => overlayEntry?.remove(),
                          icon: Icon(Icons.close, color: Colors.red),
                          label: Text("Fermer", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);
  }



  void _confirmerSuppressionTrajet(String trajetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Supprimer le trajet"),
        content: Text("Es-tu sûr de vouloir supprimer ce trajet ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('TRAJET1').doc(trajetId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Trajet supprimé.")),
              );
            },
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE8AAB4), width: 2),
          ),
        ),
      ),
    );
  }


  Widget _customDropdownField({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String) onChanged,
  }) {
    final GlobalKey key = GlobalKey();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 6),
          GestureDetector(
            key: key,
            onTap: () {
              final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
              final Offset offset = renderBox.localToGlobal(Offset.zero);
              final Size size = renderBox.size;
              final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

              showDropdownOverlay(
                context: context,
                targetRect: rect,
                options: options,
                onSelect: onChanged,
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value ?? "Sélectionner $label",
                      style: TextStyle(
                        fontSize: 14,
                        color: value == null ? Colors.grey[600] : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showTrajetDetails(BuildContext context, QueryDocumentSnapshot trajet) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => overlayEntry.remove(),
            child: Container(color: Colors.black54),
          ),
          Center(
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              elevation: 8,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Détails du trajet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    SizedBox(height: 12),
                    Text("TRAJET: ${trajet['Depart']} ➔ ${trajet['Aret']}"),
                    SizedBox(height: 8),
                    Text("🕒 Départ: ${trajet['Heure_de_Départ']}"),
                    Text("🕒 Arrivée: ${trajet["Heure_d'Arrivée"]}"),
                    SizedBox(height: 8),
                    Text("📆 Circulation: ${trajet['Jour_de_Circulation']}"),
                    SizedBox(height: 8),
                    Text("🚆 Train ID: ${trajet['trainId']}"),
                    Text("🧭 Ligne: ${trajet['lineId']}"),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            overlayEntry.remove();
                            _showGaresOverlay(context, trajet.id);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Color(0xFFE8AAB4),
                            foregroundColor: Colors.white,
                          ),
                          child: Text("Afficher les gares"),
                        ),
                        TextButton(
                          onPressed: () => overlayEntry.remove(),
                          style: TextButton.styleFrom(foregroundColor: Colors.black),
                          child: Text("Fermer"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _showGaresOverlay(BuildContext context, String trajetId) async {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    final snapshot = await FirebaseFirestore.instance
        .collection('TRAJET1')
        .doc(trajetId)
        .collection('Gares_Intermédiaires')
        .orderBy('id')
        .get();

    final gares = snapshot.docs;

    overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.white,
          elevation: 10,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("🚉 Gares intermédiaires", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: gares.map((g) => Card(
                        color: Color(0xFFF8F8F8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Icon(Icons.location_on, color: Colors.indigo),
                          title: Text(g['gare'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("🕒 Passage: ${g['Heure_de_Passage']}   |   ID: ${g['id']}"),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFFE8AAB4),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => overlayEntry.remove(),
                  child: Text("Fermer"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  void _ajouterGareDialog() async {
    String? selectedGare;
    String? selectedHeure;
    bool isGareListVisible = false;
    final TextEditingController heureController = TextEditingController();
    final FocusNode heureFocusNode = FocusNode(); // 🔸 à ajouter avant la création de l'OverlayEntry

    final snapshot = await FirebaseFirestore.instance.collection('Gare').get();
    final gares = snapshot.docs.map((doc) => doc['name'].toString()).toList();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) => Stack(
            children: [
              GestureDetector(
                onTap: () => overlayEntry.remove(),
                child: Container(color: Colors.black54),
              ),
              Center(
                child: Material(
                  elevation: 10,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Ajouter une gare intermédiaire",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        // Boîte pour sélectionner la gare
                        GestureDetector(
                          onTap: () {
                            setOverlayState(() {
                              isGareListVisible = !isGareListVisible;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedGare ?? "Sélectionner une gare"),
                                Icon(isGareListVisible
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                        if (isGareListVisible)
                          Container(
                            height: 150,
                            margin: EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: ListView.builder(
                              itemCount: gares.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(gares[index]),
                                  onTap: () {
                                    setOverlayState(() {
                                      selectedGare = gares[index];
                                      isGareListVisible = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        SizedBox(height: 16),
                        // Boîte pour sélectionner l'heure
                        // Champ texte stylé comme la boîte
                        TextField(
                          controller: heureController,
                          focusNode: heureFocusNode,
                          decoration: InputDecoration(
                            labelText: "Heure de passage",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          // 🟢 Clavier numérique
                          onTap: () {
                            heureFocusNode.requestFocus(); // 🟢 Forcer l’ouverture du clavier
                          },
                        ),


                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => overlayEntry.remove(),
                              child: Text("Annuler"),
                            ),
                            TextButton(
                              onPressed: () {
                                if (selectedGare != null && heureController.text.isNotEmpty) {
                                  setState(() {
                                    garesIntermediaires.add({
                                      'gare': selectedGare!,
                                      'Heure_de_Passage': heureController.text,
                                      'id': garesIntermediaires.length + 1,
                                    });
                                  });
                                  overlayEntry.remove();
                                }
                                else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Veuillez remplir tous les champs.")),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Color(0xFFE8AAB4),
                                foregroundColor: Colors.white,
                              ),
                              child: Text("Ajouter"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
  }




  Widget _buildAjoutForm() {
    String? selectedDepart;
    String? selectedAret;
    String? selectedLigne;
    String? selectedJour;
    final TextEditingController trainIdController = TextEditingController();

    Widget _buildStyledSelector({
      required String label,
      required String? selectedValue,
      required List<String> options,
      required void Function(String) onSelected,
    }) {
      bool isExpanded = false;

      return StatefulBuilder(
        builder: (context, setSelectorState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => setSelectorState(() => isExpanded = !isExpanded),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(selectedValue ?? "Sélectionner $label"),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  height: 150,
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(options[index]),
                        onTap: () {
                          onSelected(options[index]);
                          setSelectorState(() => isExpanded = false);
                        },
                      );
                    },
                  ),
                ),
              SizedBox(height: 16),
            ],
          );
        },
      );
    }

    Widget _buildStyledTextField(String label, TextEditingController controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: label,
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      );
    }

    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance.collection('Gare').get(),
        FirebaseFirestore.instance.collection('LIGNE').get(),
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final gares = snapshot.data![0].docs.map((doc) => doc['name'].toString()).toList();
        final lignes = snapshot.data![1].docs.map((doc) => doc['nom'].toString()).toList();

        return StatefulBuilder(
          builder: (context, setFormState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildStyledSelector(
                    label: "Gare de départ",
                    selectedValue: selectedDepart,
                    options: gares,
                    onSelected: (val) => setFormState(() => selectedDepart = val),
                  ),
                  _buildStyledSelector(
                    label: "Gare d'arrêt",
                    selectedValue: selectedAret,
                    options: gares,
                    onSelected: (val) => setFormState(() => selectedAret = val),
                  ),

                  _buildStyledTextField("Heure de Départ", heureDepartController),
                  _buildStyledTextField("Heure de passage Arrivée ", heureArriveeController),
                  _buildStyledTextField("ID du train", trainIdController),

                  _buildStyledSelector(
                    label: "Ligne",
                    selectedValue: selectedLigne,
                    options: lignes,
                    onSelected: (val) => setFormState(() => selectedLigne = val),
                  ),

                  SizedBox(height: 20),

                  Text("Jour de circulation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: Text("Tous les jours"),
                        value: "Tous les jours",
                        groupValue: selectedJour,
                        onChanged: (value) => setFormState(() => selectedJour = value),
                      ),
                      RadioListTile<String>(
                        title: Text("Week-ends et Jours fériés uniquement"),
                        value: "Week-ends et Jours fériés uniquement",
                        groupValue: selectedJour,
                        onChanged: (value) => setFormState(() => selectedJour = value),
                      ),
                      RadioListTile<String>(
                        title: Text("Tous les jours sauf week-ends"),
                        value: "Tous les jours sauf week-ends",
                        groupValue: selectedJour,
                        onChanged: (value) => setFormState(() => selectedJour = value),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFB3D9FF),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _ajouterGareDialog,
                    child: Text('Ajouter une gare intermédiaire'),
                  ),

                  ...garesIntermediaires.map((gare) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      tileColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      title: Text(gare['gare']),
                      subtitle: Text("🕒 ${gare['Heure_de_Passage']}"),
                      trailing: Text("ID: ${gare['id']}"),
                    ),
                  )),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      if (selectedDepart == null ||
                          selectedAret == null ||
                          selectedLigne == null ||
                          selectedJour == null ||
                          trainIdController.text.isEmpty ||
                          heureDepartController.text.isEmpty ||
                          heureArriveeController.text.isEmpty ||
                          garesIntermediaires.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Veuillez remplir tous les champs.")),
                        );
                        return;
                      }

                      final trajetRef = await FirebaseFirestore.instance.collection('TRAJET1').add({
                        'Depart': selectedDepart,
                        'Aret': selectedAret,
                        'Heure_de_Départ': heureDepartController.text,
                        "Heure_d'Arrivée": heureArriveeController.text,
                        'Jour_de_Circulation': selectedJour,
                        'trainId': trainIdController.text,
                        'lineId': selectedLigne,
                      });

                      for (var gare in garesIntermediaires) {
                        await trajetRef.collection('Gares_Intermédiaires').add(gare);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Trajet ajouté avec succès !")));
                      setState(() {
                        garesIntermediaires.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE8AAB4),
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Ajouter le trajet"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _ajouterTrajet() async {
    if (departController.text.isEmpty ||
        aretController.text.isEmpty ||
        heureDepartController.text.isEmpty ||
        heureArriveeController.text.isEmpty ||
        jourController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tous les champs doivent être remplis.")),
      );
      return;
    }

    if (garesIntermediaires.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez ajouter au moins une gare intermédiaire.")),
      );
      return;
    }

    final trajetRef = await FirebaseFirestore.instance.collection('TRAJET1').add({
      'Depart': departController.text,
      'Aret': aretController.text,
      'Heure_de_Départ': heureDepartController.text,
      "Heure_d'Arrivée": heureArriveeController.text,
      'Jour_de_Circulation': jourController.text,
      'lineId': "${departController.text} - ${aretController.text}",
      'trainId': "train${DateTime.now().millisecondsSinceEpoch}"
    });

    for (var gare in garesIntermediaires) {
      await trajetRef.collection("Gares_Intermédiaires").add(gare);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Trajet et gares ajoutés avec succès.')),
    );

    departController.clear();
    aretController.clear();
    heureDepartController.clear();
    heureArriveeController.clear();
    jourController.clear();
    setState(() {
      garesIntermediaires.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = <Widget>[
      _buildTrajetsList(),
      _buildAjoutForm(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion des trajets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Color(0xFFB3D9FF),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFE8AAB4),
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.train), label: "Consulter"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Ajouter"),
        ],
      ),
    );
  }
}
