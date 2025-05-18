import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;
  final Dio _dio = Dio();
  String apiKey = "TON_CLE_API_ICI"; // 🔥 Remplace par ta clé API Google Maps

  LatLng startLocation = LatLng(37.7749, -122.4194);
  LatLng destination = LatLng(37.7849, -122.4094);
  List<LatLng> polylineCoordinates = [];

  @override
  void initState() {
    super.initState();
    _getRoute();
  }

  Future<void> _getRoute() async {
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation.latitude},${startLocation.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    try {
      final response = await _dio.get(url);
      final data = response.data;

      if (data["routes"].isNotEmpty) {
        List steps = data["routes"][0]["legs"][0]["steps"];

        polylineCoordinates.clear();
        for (var step in steps) {
          polylineCoordinates.add(LatLng(
            step["end_location"]["lat"],
            step["end_location"]["lng"],
          ));
        }

        setState(() {});

        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
                data["routes"][0]["bounds"]["southwest"]["lat"],
                data["routes"][0]["bounds"]["southwest"]["lng"]),
            northeast: LatLng(
                data["routes"][0]["bounds"]["northeast"]["lat"],
                data["routes"][0]["bounds"]["northeast"]["lng"]),
          ),
          50,
        ));
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'itinéraire : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carte de localisation")),
      body: Column(
        children: [
          // La carte Google Maps
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: startLocation,
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _getMarkers(),
              polylines: {
                Polyline(
                  polylineId: PolylineId("route"),
                  points: polylineCoordinates,
                  color: Colors.greenAccent,
                  width: 4,
                ),
              },
            ),
          ),
          // Section du bas
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Informations sur la localisation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    print("Bouton cliqué");
                  },
                  child: Text("Voir plus de détails"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _getMarkers() {
    return {
      Marker(
        markerId: MarkerId("start"),
        position: startLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: MarkerId("destination"),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }
}
