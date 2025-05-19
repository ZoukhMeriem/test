import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'liste_trajets_screen.dart'; // Pour utiliser la classe Trajet

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

  Marker? movingMarker;
  int currentIndex = 0;
  Timer? movementTimer;

  @override
  void initState() {
    super.initState();
    fetchRoutePointsFromFirestore().then((_) {
      generateSmoothPath();
      startSmoothSimulation();
    });
  }

  Future<void> fetchRoutePointsFromFirestore() async {
    simulatedRoute.clear();

    final orderedGares = widget.trajet.garesIntermediaires
        .where((g) => g.id >= (widget.trajet.idDepart ?? 0) &&
        g.id <= (widget.trajet.idArrivee ?? 0))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final nomGares = [
      widget.trajet.gareDepart,
      ...orderedGares.map((g) => g.gare),
      widget.trajet.gareArrivee
    ];

    for (String nom in nomGares) {
      final snapshot = await FirebaseFirestore.instance
          .collection('Gare')
          .where('name', isEqualTo: nom)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final lat = data['location']['lat'];
        final lng = data['location']['lng'];
        simulatedRoute.add(LatLng(lat, lng));
      } else {
        print("\u274C Gare non trouv\u00e9e : $nom");
      }
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
        markerId: MarkerId("train"),
        position: smoothPath[0],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: "Train en mouvement"),
      );
    });

    movementTimer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      if (currentIndex < smoothPath.length) {
        setState(() {
          movingMarker = movingMarker!.copyWith(
            positionParam: smoothPath[currentIndex],
          );
        });

        mapController?.animateCamera(
          CameraUpdate.newLatLng(smoothPath[currentIndex]),
        );

        currentIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    movementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trackage du Train"),
        backgroundColor: Color(0xFF8BB1FF),
      ),
      body: simulatedRoute.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
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
            return Marker(
              markerId: MarkerId("point_$index"),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                index == 0
                    ? BitmapDescriptor.hueGreen
                    : index == simulatedRoute.length - 1
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueAzure,
              ),
              infoWindow: InfoWindow(title: "Gare ${index + 1}"),
            );
          }),
        },
        polylines: {
          Polyline(
            polylineId: PolylineId("ligne"),
            points: simulatedRoute,
            color: Colors.blue,
            width: 4,
          ),
        },
      ),
    );
  }
}
