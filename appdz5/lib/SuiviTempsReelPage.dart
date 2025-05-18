import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'liste_trajets_screen.dart'; // Adapter selon l'importation de ta classe Trajet

class SuiviTempsReelPage extends StatefulWidget {
  final Trajet trajet;

  const SuiviTempsReelPage({super.key, required this.trajet});

  @override
  State<SuiviTempsReelPage> createState() => _CarteTrajetPageState();
}

class _CarteTrajetPageState extends State<SuiviTempsReelPage> {
  GoogleMapController? mapController;
  List<LatLng> points = [];

  @override
  void initState() {
    super.initState();
    chargerPoints();
  }

  Future<void> chargerPoints() async {
    List<String> nomsGares = [
      widget.trajet.gareDepart,
      ...widget.trajet.garesIntermediaires.map((g) => g.gare),
      widget.trajet.gareArrivee
    ];

    points = await fetchGareLocations(nomsGares);
    setState(() {});
  }

  Future<List<LatLng>> fetchGareLocations(List<String> nomsGares) async {
    List<LatLng> points = [];

    for (String nom in nomsGares) {
      var snapshot = await FirebaseFirestore.instance
          .collection('Gare')
          .where('name', isEqualTo: nom)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        var lat = data['location']['lat'];
        var lng = data['location']['lng'];
        points.add(LatLng(lat, lng));
      }
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte du Trajet"),
        backgroundColor: Color(0xFF8BB1FF),
      ),
      body: points.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: points.first,
          zoom: 11,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: points
            .asMap()
            .entries
            .map((entry) => Marker(
          markerId: MarkerId("point_${entry.key}"),
          position: entry.value,
          infoWindow: InfoWindow(title: "Gare ${entry.key + 1}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            entry.key == 0
                ? BitmapDescriptor.hueGreen // Départ
                : entry.key == points.length - 1
                ? BitmapDescriptor.hueRed // Arrivée
                : BitmapDescriptor.hueAzure, // Intermédiaires
          ),
        ))
            .toSet(),
        polylines: {
          Polyline(
            polylineId: const PolylineId("trajet"),
            points: points,
            color: Colors.blueAccent,
            width: 4,
          )
        },
      ),
    );
  }
}
