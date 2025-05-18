import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrainTrackingMap extends StatefulWidget {
  @override
  _TrainTrackingMapState createState() => _TrainTrackingMapState();
}

class _TrainTrackingMapState extends State<TrainTrackingMap> {
  GoogleMapController? mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadTrainPositions();
  }

  Future<void> _loadTrainPositions() async {
    FirebaseFirestore.instance.collection('train_positions').snapshots().listen((snapshot) {
      Set<Marker> newMarkers = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        double lat = data['latitude'];
        double lng = data['longitude'];

        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: 'Train ${doc.id}'),
          ),
        );
      }
      setState(() {
        _markers = newMarkers;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.trainTrackingTitle)),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(36.737232, 3.086472), zoom: 10),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
    );
  }
}
