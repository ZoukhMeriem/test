import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'liste_trajets_screen.dart';
import 'home_screen.dart';
import 'package:geolocator/geolocator.dart';

class SimulationLocalePage extends StatefulWidget {
  final Trajet trajet;

  const SimulationLocalePage({super.key, required this.trajet});

  @override
  _SimulationLocalePageState createState() => _SimulationLocalePageState();
}

class _SimulationLocalePageState extends State<SimulationLocalePage> {
  GoogleMapController? mapController;
  List<LatLng> simulatedRoute = [];
  List<LatLng> smoothPath = [];
  LatLng? currentTrainPosition;
  LatLng? departLatLng;
  int currentGareIndex = 0;
  bool trajetTermine = false;


  bool hasPromptedAtDepart = false;
  bool isTracking = false;
  Marker? movingMarker;
  int currentIndex = 0;
  Timer? movementTimer;
  bool continuerApresDepart = true;

  late BitmapDescriptor trainIcon;
  late BitmapDescriptor pointNoirIcon;

  @override
  void initState() {
    super.initState();
    chargerIcons().then((_) {
      fetchRoutePointsFromFirestore().then((_) {
        generateSmoothPath();
        startSmoothSimulation();
      });
    });
  }

  Future<void> chargerIcons() async {
    try {
      final data = await rootBundle.load('assets/images/train_icon.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 60,
        targetHeight: 60,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      trainIcon = BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final paint = Paint()..color = Colors.black;
      canvas.drawCircle(const Offset(25, 25), 10, paint);
      final imagePoint = await pictureRecorder.endRecording().toImage(50, 50);
      final byteDataPoint = await imagePoint.toByteData(format: ui.ImageByteFormat.png);
      pointNoirIcon = BitmapDescriptor.fromBytes(byteDataPoint!.buffer.asUint8List());
    } catch (e) {
      print("❌ Erreur lors du chargement des icônes : $e");
    }
  }

  Future<void> fetchRoutePointsFromFirestore() async {
    simulatedRoute.clear();

    final orderedGares = widget.trajet.garesIntermediaires
        .where((g) => g.id <= (widget.trajet.idArrivee ?? 999999))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final nomGares = <String>[];

    nomGares.addAll(orderedGares.map((g) => g.gare));

    if (!nomGares.contains(widget.trajet.gareDepart)) {
      nomGares.add(widget.trajet.gareDepart);
    }

    if (!nomGares.contains(widget.trajet.gareArrivee)) {
      nomGares.add(widget.trajet.gareArrivee);
    }

    for (String nom in nomGares) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('Gare')
            .where('name', isEqualTo: nom)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          final lat = data['location']['lat'];
          final lng = data['location']['lng'];
          final point = LatLng(lat, lng);
          simulatedRoute.add(point);

          if (nom == widget.trajet.gareDepart) {
            departLatLng = point;
            print("📍 Position de la gare de départ : $departLatLng");
          }
        } else {
          print("❌ Gare non trouvée dans Firestore : $nom");
        }
      } catch (e) {
        print("❌ Erreur lors de la récupération de la gare '$nom' : $e");
      }
    }

    if (simulatedRoute.isNotEmpty) {
      currentTrainPosition = simulatedRoute.first;
      print("🚆 Points de simulatedRoute :");
      for (var point in simulatedRoute) {
        print("   ➤ ${point.latitude}, ${point.longitude}");
      }
    } else {
      print("⚠️ Aucune position chargée — la carte ne s'affichera pas.");
    }
  }


  void generateSmoothPath() {
    const int stepsPerSegment = 50;
    smoothPath.clear();

    for (int i = 0; i < simulatedRoute.length - 1; i++) {
      final p1 = simulatedRoute[i];
      final p2 = simulatedRoute[i + 1];

      for (int j = 0; j <= stepsPerSegment; j++) {
        double lat = p1.latitude + (p2.latitude - p1.latitude) * (j / stepsPerSegment);
        double lng = p1.longitude + (p2.longitude - p1.longitude) * (j / stepsPerSegment);
        smoothPath.add(LatLng(lat, lng));
      }
    }
  }

  void startSmoothSimulation() {
    if (smoothPath.isEmpty) return;

    setState(() {
      movingMarker = Marker(
        markerId: const MarkerId("train"),
        position: smoothPath[0],
        icon: trainIcon,
        infoWindow: const InfoWindow(title: "Train en mouvement"),
      );
    });

    movementTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (currentIndex < smoothPath.length) {
        setState(() {
          movingMarker = movingMarker!.copyWith(
            positionParam: smoothPath[currentIndex],
          );
        });

        mapController?.animateCamera(
          CameraUpdate.newLatLng(smoothPath[currentIndex]),
        );

        // 👉 Vérifie si on est à la gare de départ (vraie position)
        if (departLatLng != null &&
            !hasPromptedAtDepart &&
            (smoothPath[currentIndex].latitude - departLatLng!.latitude).abs() < 0.0001 &&
            (smoothPath[currentIndex].longitude - departLatLng!.longitude).abs() < 0.0001) {

          hasPromptedAtDepart = true;
          timer.cancel(); // Stoppe temporairement le mouvement

          // 🟢 Affiche la boîte de dialogue
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text(
                "🎉 Bienvenue à bord !",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: const Text(
                "Notre cher(e) voyageur(se), souhaitez-vous continuer à suivre le trajet du train pendant votre voyage ?",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    continuerApresDepart = true;
                    Navigator.of(context).pop();
                    startSmoothSimulation(); // Reprendre la simulation
                  },
                  child: const Text("Oui"),
                ),
                TextButton(
                  onPressed: () {
                    continuerApresDepart = false;
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          message: "Merci de votre confiance. Nous vous souhaitons un agréable voyage !\nEspérons vous revoir très bientôt.",
                        ),
                      ),
                    );
                  },
                  child: const Text("Non"),
                ),
              ],
            ),
          );

          return; // Sortie pour ne pas faire currentIndex++
        }

        currentIndex++;
      } else {
        timer.cancel(); // Fin du trajet
        setState(() {
          trajetTermine = true;
        });



      }
      // 🧠 Mettre à jour currentGareIndex dynamiquement
      double minDistance = double.infinity;
      int closestIndex = 0;

      for (int i = 0; i < simulatedRoute.length; i++) {
        final p = simulatedRoute[i];
        final double distance = Geolocator.distanceBetween(
          p.latitude,
          p.longitude,
          smoothPath[currentIndex].latitude,
          smoothPath[currentIndex].longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
      }

      setState(() {
        currentGareIndex = closestIndex;
      });

    });
  }

  @override
  void dispose() {
    movementTimer?.cancel();
    super.dispose();
  }
  double getTrainTopPosition() {
    int totalGares = widget.trajet.garesIntermediaires.length;

    if (totalGares <= 1) return 0;

    double availableHeight = 400 - 40; // hauteur du widget - marge
    double step = availableHeight / (totalGares - 1);

    return currentGareIndex * step;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: simulatedRoute.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: simulatedRoute[0],
              zoom: 13,
            ),
            onMapCreated: (controller) => mapController = controller,
            markers: {
              if (movingMarker != null) movingMarker!,
              ...simulatedRoute.asMap().entries.map((entry) {
                final index = entry.key;
                final position = entry.value;

                int maxReachedIndex = ((currentIndex / smoothPath.length) * simulatedRoute.length).floor();

                double hue;
                if (index == simulatedRoute.length - 1) {
                  hue = BitmapDescriptor.hueRed;
                } else if (index <= maxReachedIndex) {
                  hue = BitmapDescriptor.hueGreen;
                } else {
                  hue = BitmapDescriptor.hueYellow;
                }

                return Marker(
                  markerId: MarkerId("point_$index"),
                  position: position,
                  icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                  infoWindow: InfoWindow(title: "Gare ${index + 1}"),
                );
              }),
            },
            polylines: {
              if (smoothPath.isNotEmpty && currentIndex > 0)
                Polyline(
                  polylineId: const PolylineId("ligne_verte"),
                  points: smoothPath.sublist(0, currentIndex.clamp(0, smoothPath.length)),
                  color: Colors.green,
                  width: 4,
                ),
              if (smoothPath.isNotEmpty && currentIndex < smoothPath.length)
                Polyline(
                  polylineId: const PolylineId("ligne_jaune"),
                  points: smoothPath.sublist(currentIndex.clamp(0, smoothPath.length - 1)),
                  color: const Color(0xFFDFD041),
                  width: 4,
                ),
            },
          ),
          Positioned(
            top: 30,
            left: 10,
            child: SafeArea(
              child: ClipOval(
                child: Material(
                  color: Colors.black87,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.1,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Stack( // <-- Utiliser Stack ici
                  children: [
                    ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        Text(
                          widget.trajet.lineId,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Train num: ${widget.trajet.trainId}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const Divider(height: 20, thickness: 1),
                        Text(
                          "🗓️ Date : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "🕒 ${widget.trajet.heureDepart}",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.circle, size: 12, color: Color(0xFFF1EE2A)),
                            const Expanded(
                              child: Divider(thickness: 2, color: Colors.grey),
                            ),
                            const Icon(Icons.circle, size: 12, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              "🕒 ${widget.trajet.heureArrivee}",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // ici tu peux ajouter d’autres widgets si besoin
                      ],
                    ),
                    if (trajetTermine)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          color: Colors.teal.shade600,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  "🚉 Cher voyageur, notre trajet est terminé.\nPour revenir à l'accueil, cliquez sur Exit.",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                },
                                child: const Text(
                                  "Exit",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                    Positioned(
                      top: 160,
                      left: 40,
                      bottom: 0,
                      width: 120,
                      child: Container(
                        color: Colors.white54,
                        child: ListView.builder(
                          itemCount: simulatedRoute.length,
                          itemBuilder: (context, index) {
                            final isActive = index == currentGareIndex;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              color: isActive ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.train,
                                    color: isActive ? Colors.blue :  Color(0xFFDFD041),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Gare ${index + 1}", // ou ton nom de gare
                                      style: TextStyle(
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                        color: isActive ? Colors.blue : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),


        ],
      ),
    );
  }
}
