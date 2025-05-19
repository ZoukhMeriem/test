import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'liste_trajets_screen.dart'; // Adapter selon l'importation de ta classe Trajet

class SuiviTempsReelPage extends StatefulWidget {
  final Trajet trajet;

  const SuiviTempsReelPage({super.key, required this.trajet});

  @override
  State<SuiviTempsReelPage> createState() => _SuiviTempsReelPageState();
}

class _SuiviTempsReelPageState extends State<SuiviTempsReelPage> {
  GoogleMapController? mapController;
  List<LatLng> points = [];

  Marker? movingMarker;
  int currentIndex = 0;
  Timer? movementTimer;

  @override
  void initState() {
    super.initState();
    chargerPoints();
  }

  @override
  void dispose() {
    movementTimer?.cancel();
    super.dispose();
  }

  Future<void> chargerPoints() async {
    List<String> nomsGares = [
      widget.trajet.gareDepart,
      ...widget.trajet.garesIntermediaires.map((g) => g.gare),
      widget.trajet.gareArrivee
    ];

    points = await fetchGareLocations(nomsGares);
    setState(() {});
    startTrainSimulation(); // 🚀 Démarre la simulation dès que les points sont chargés
  }

  Future<List<LatLng>> fetchGareLocations(List<String> nomsGares) async {
    List<LatLng> positions = [];

    for (String nom in nomsGares) {
      var snapshot = await FirebaseFirestore.instance
          .collection('Gare')
          .where('name', isEqualTo: nom)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        var lat = data['location']['lat'];
        var lng = data['location']['lng'];
        positions.add(LatLng(lat, lng));
      }
    }

    return positions;
  }

  void startTrainSimulation() {
    if (points.isEmpty) return;

    movingMarker = Marker(
      markerId: MarkerId("train"),
      position: points[0],
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(title: "Train en mouvement"),
    );

    movementTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (currentIndex < points.length) {
        setState(() {
          movingMarker = movingMarker!.copyWith(
            positionParam: points[currentIndex],
          );
        });

        mapController?.animateCamera(
          CameraUpdate.newLatLng(points[currentIndex]),
        );

        currentIndex++;
      } else {
        timer.cancel(); // Arrêt de la simulation à la fin
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suivi en Temps Réel"),
        backgroundColor: Color(0xFF8BB1FF),
      ),
      body: points.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: points.first,
          zoom: 12,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: {
          if (movingMarker != null) movingMarker!,
          ...points.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;

            return Marker(
              markerId: MarkerId("point_$index"),
              position: point,
              infoWindow: InfoWindow(title: "Gare ${index + 1}"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                index == 0
                    ? BitmapDescriptor.hueGreen // Départ
                    : index == points.length - 1
                    ? BitmapDescriptor.hueRed // Arrivée
                    : BitmapDescriptor.hueAzure, // Intermédiaires
              ),
            );
          }),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId("trajet"),
            points: points,
            color: Colors.blueAccent,
            width: 4,
          ),
        },
      ),
    );
  }
}
