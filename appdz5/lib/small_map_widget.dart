import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SmallMapWidget extends StatelessWidget {
  final LatLng startLocation;
  final LatLng destination;
  final List<LatLng> polylineCoordinates;

  SmallMapWidget({
    required this.startLocation,
    required this.destination,
    required this.polylineCoordinates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Taille réduite pour affichage dans ProfileScreen
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: startLocation,
            zoom: 13.0,
          ),
          markers: _getMarkers(),
          polylines: {
            Polyline(
              polylineId: PolylineId("route"),
              points: polylineCoordinates,
              color: Colors.green,
              width: 3,
            ),
          },
          zoomControlsEnabled: false,
        ),
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
