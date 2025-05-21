import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'liste_trajets_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  final String? message;
  const HomeScreen({Key? key, this.message}) : super(key: key);
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  bool showMessage = false;

  Position? _currentPosition;
  LatLng _initialPosition = LatLng(36.7372, 3.0863);
  Set<Marker> _markers = {};
  Map<String, LatLng> _stations = {}; // Stocke les gares
  Map<int, String> _stationOrder = {}; // ✅ Ajout de la variable
  String? _searchMessage;
  String? _selectedDeparture;
  String? _selectedDestination;
  DateTime _selectedDate = DateTime.now();
  int _passengerCount = 1;
  bool _useCurrentLocationAsDeparture = false;
  LatLng? _selectedDeparturePosition;
  LatLng? _selectedDestinationPosition;
  bool _showGareList = false;
  Set<Polyline> _polylines = {};
  Map<String, List<String>> _stationLines = {};
  bool _showIntermediateStations = false;
  TextEditingController _destinationSearchController = TextEditingController();
  List<String> _filteredDestinationStations = [];
  get smallRedMarker => null;
  TextEditingController _departureSearchController = TextEditingController();
  List<String> _filteredDepartureStations = [];

  void _zoomOnStation(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 8));
  }
  // ✅ Stocke les lignes de chaque gare

  void _onSearch() {
    // Logique de recherche ici
    // ... (votre logique de recherche)

    // Afficher le message après la recherche
    setState(() {
      _searchMessage = "Consulter les trajets de votre voyage";
    });
  }

  @override

  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchStationsFromFirestore();
    testFetchBoufarik();
    _filteredDestinationStations = _stations.keys.toList();
    _filteredDepartureStations = _stations.keys.toList();

    if (widget.message != null) {
      showMessage = true;
      Future.delayed(const Duration(seconds: 15), () {
        setState(() {
          showMessage = false;
        });
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _initialPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 14));
      _showNearestStationsDialog();
    } catch (e) {
      print("Erreur lors de la récupération de la position : $e");
    }
  }

  Future<void> _fetchStationsFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Gare')
          .orderBy('id')
          .get();

      Map<int, List<String>> stationOrder = {}; // ✅ Stocke plusieurs gares sous le même ID
      Map<String, LatLng> stations = {};
      Map<String, List<String>> stationLines = {};

      print("📌 Toutes les gares Firestore :");
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int stationId = data['id'];
        String stationName = data['name'];
        double latitude = data['location']['lat'];
        double longitude = data['location']['lng'];
        List<String> lines = List<String>.from(data['lineId'] ?? []);

        print("🧐 ID: $stationId | Nom: $stationName | Lat: $latitude | Lng: $longitude");

        // ✅ Stocker toutes les gares avec le même ID dans une liste
        if (!stationOrder.containsKey(stationId)) {
          stationOrder[stationId] = [];
        }
        stationOrder[stationId]!.add(stationName);

        stations[stationName] = LatLng(latitude, longitude);
        stationLines[stationName] = lines;
      }

      setState(() {
        _stations = stations;
        _stationOrder.clear(); // On reconstruit l'ordre des gares
        stationOrder.forEach((id, names) {
          for (String name in names) {
            _stationOrder[id] = name; // On garde la dernière gare pour compatibilité
          }
        });
        _stationLines = stationLines;
      });

      print("✅ Gares récupérées : $_stationOrder");
    } catch (e) {
      print("❌ Erreur Firestore : $e");
    }
  }
  void _rechercherTrajets(BuildContext context, String depart, String destination, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeTrajetsScreen(
          departure: depart,
          destination: destination,
          date: date,
        ),
      ),
    );
  }

  // gares proches
  double _calculateDistance(LatLng pos1, LatLng pos2) {
    double distanceInMeters = Geolocator.distanceBetween(
      pos1.latitude, pos1.longitude,
      pos2.latitude, pos2.longitude,
    );
    return distanceInMeters;
  }

  Future<String?> _findNearestStation() async {
    if (_currentPosition == null) return null;

    LatLng userPosition = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    String? nearestStation;
    double minDistance = double.infinity;

    _stations.forEach((stationName, stationPosition) {
      double distance = _calculateDistance(userPosition, stationPosition);
      if (distance < minDistance) {
        minDistance = distance;
        nearestStation = stationName;
      }
    });

    return nearestStation;
  }

  List<MapEntry<String, double>> _findNearestStations() {
    if (_currentPosition == null) {
      print("⚠️ Position actuelle non définie !");
      return [];
    }

    if (_stations.isEmpty) {
      print("⚠️ Aucune gare disponible !");
      return [];
    }

    LatLng userPosition = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    print("📍 Position actuelle : $userPosition");

    // Calculer la distance pour chaque station
    List<MapEntry<String, double>> stationDistances = _stations.entries.map((entry) {
      double distance = _calculateDistance(userPosition, entry.value);
      print("📌 Distance entre ${entry.key} et utilisateur: ${distance.toStringAsFixed(2)}m");
      return MapEntry(entry.key, distance);
    }).toList();

    // Trier par distance croissante
    stationDistances.sort((a, b) => a.value.compareTo(b.value));

    // Retourner les 3 gares les plus proches
    List<MapEntry<String, double>> nearest = stationDistances.take(3).toList();

    print("✅ 3 gares les plus proches : ${nearest.map((e) => '${e.key} (${e.value.toStringAsFixed(2)}m)').toList()}");

    return nearest;
  }

  void _showNearestStationsDialog() {
    List<MapEntry<String, double>> nearestStations = _findNearestStations();

    if (nearestStations.isEmpty) {
      print("⚠️ Aucune gare proche trouvée !");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Gares les plus proches',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: nearestStations.map((station) {
              return ListTile(
                title: Text(station.key),
                subtitle: Text("Distance: ${station.value.toStringAsFixed(2)} m"),
                onTap: () {
                  final selectedStation = station.key;

                  setState(() {
                    _selectedDeparture = selectedStation;
                    _selectedDeparturePosition = _stations[selectedStation];
                    _useCurrentLocationAsDeparture = false;

                    // 👉 Met à jour le champ de recherche avec le nom de la gare choisie
                    _departureSearchController.text = selectedStation;

                    // 👉 Nettoie la destination et les anciens marqueurs/polylines
                    _selectedDestination = null;
                    _selectedDestinationPosition = null;
                    _polylines.clear();
                    _markers.clear();

                    // 👉 Ajoute le marqueur vert pour le départ
                    _addMarker(selectedStation, _stations[selectedStation]!, true);

                    // 👉 Zoom automatique
                    zoomToSelectedLocations();
                  });

                  // 👉 Ferme la boîte de dialogue après sélection
                  Navigator.pop(context);
                },

              );
            }).toList(),
          ),
        );
      },
    );
  }
  void _addMarker(String name, LatLng position, bool isDepart) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId(name),
        position: position,
        infoWindow: InfoWindow(title: isDepart ? "🚆 Départ: $name" : "🏁 Destination: $name"),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isDepart ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
        ),
      ),
    );
    setState(() {});
  }

  void _drawSimpleRoute() {
    if (_selectedDeparture == null || _selectedDestination == null) return;
    if (!_areStationsOnSameLine(_selectedDeparture!, _selectedDestination!)) {
      _showErrorDialog();
      return;
    }

    LatLng start = _stations[_selectedDeparture!]!;
    LatLng end = _stations[_selectedDestination!]!;

    setState(() {
      _polylines.clear();
      _markers.clear();

      _markers.add(Marker(
        markerId: MarkerId(_selectedDeparture!),
        position: start,
        infoWindow: InfoWindow(title: "🚆 Départ: $_selectedDeparture"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));

      _markers.add(Marker(
        markerId: MarkerId(_selectedDestination!),
        position: end,
        infoWindow: InfoWindow(title: "🏁 Destination: $_selectedDestination"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));


    });
  }


  // fin gares







  Future<List<String>> getIntermediateStations(String departure, String destination) async {
    List<int> stationIds = _stationOrder.keys.toList(); // ✅ Liste triée des IDs
    int startIndex = stationIds.indexOf(
      _stationOrder.keys.firstWhere((k) => _stationOrder[k] == departure, orElse: () => -1),
    );
    int endIndex = stationIds.indexOf(
      _stationOrder.keys.firstWhere((k) => _stationOrder[k] == destination, orElse: () => -1),
    );

    if (startIndex == -1 || endIndex == -1 || startIndex == endIndex) {
      print("🚨 Erreur : Impossible de trouver le départ ou la destination !");
      return [];
    }

    List<String> intermediateStations;

    if (startIndex > endIndex) {
      intermediateStations = stationIds
          .sublist(endIndex + 1, startIndex)
          .map((id) => _stationOrder[id]!)
          .toList()
          .reversed
          .toList();
    } else {
      intermediateStations = stationIds
          .sublist(startIndex + 1, endIndex)
          .map((id) => _stationOrder[id]!)
          .toList();
    }

    print("✅ Gares intermédiaires détectées : $intermediateStations");
    return intermediateStations;
  }

  Future<void> testFetchBoufarik() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Gare')
          .where("name", isEqualTo: "Gare de Boufarik")
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("🚨 Boufarik n'est PAS dans Firestore !");
      } else {
        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print("✅ Boufarik trouvée dans Firestore : $data");
        }
      }
    } catch (e) {
      print("❌ Erreur Firestore : $e");
    }
  }

  void _updateMarkers() async {
    if (_selectedDeparture != null && _selectedDestination != null) {
      // Vérifier si les gares sont sur la même ligne
      if (!_areStationsOnSameLine(_selectedDeparture!, _selectedDestination!)) {
        setState(() {
          _polylines.clear(); // Efface la route précédente
          _markers.clear();   // Efface les anciens marqueurs
        });

        _showErrorDialog(); // Affiche la boîte de dialogue
        return; // Arrête l'exécution ici
      }

      // Effacer les anciens marqueurs et polylines avant d'ajouter les nouveaux
      setState(() {
        _markers.clear();
        _polylines.clear();
      });

      LatLng depart = _stations[_selectedDeparture!]!;
      LatLng destination = _stations[_selectedDestination!]!;

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(_selectedDeparture!),
            position: depart,
            infoWindow: InfoWindow(title: "🚆 Départ: $_selectedDeparture"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );

        _markers.add(
          Marker(
            markerId: MarkerId(_selectedDestination!),
            position: destination,
            infoWindow: InfoWindow(title: "🏁 Destination: $_selectedDestination"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });

      List<String> intermediateStations = await getIntermediateStations(_selectedDeparture!, _selectedDestination!);

      setState(() {
        for (String stationName in intermediateStations) {
          if (_stations.containsKey(stationName)) {
            _markers.add(
              Marker(
                markerId: MarkerId(stationName),
                position: _stations[stationName]!,
                infoWindow: InfoWindow(title: "🚉 Arrêt intermédiaire: $stationName"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
            print("📍 Marqueur ajouté pour : $stationName");
          } else {
            print("⚠️ La gare intermédiaire $stationName n'existe pas dans _stations !");
          }
        }
      });
    }
  }

  void zoomToSelectedLocations() {
    if (_selectedDeparture != null && _selectedDestination != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        _selectedDeparturePosition!,
        15.0,
      ));}
  }

  LatLngBounds _calculateLatLngBounds() {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var marker in _markers) {
      LatLng pos = marker.position;
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  void _showDepartureChoiceModal() {
    _showGareList = false; // reset

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: _showGareList ? 0.6 : 0.3,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_showGareList) ...[
                        ListTile(
                          leading: Icon(Icons.my_location, color: Colors.green),
                          title: Text("📍 Utiliser ma position actuelle"),
                          onTap: () async {
                            Navigator.pop(context);
                            Position position = await Geolocator.getCurrentPosition();
                            String? nearestStation = await _findNearestStation();
                            setState(() {
                              _currentPosition = position;
                             // _useCurrentLocationAsDeparture = true;
                            });
                            _showNearestStationsDialog();
                            if (nearestStation != null) {
                              setState(() {
                                _useCurrentLocationAsDeparture = true;
                                _selectedDeparture = nearestStation;
                                _selectedDeparturePosition = _stations[nearestStation];
                              });

                              _updateMarkers();
                              zoomToSelectedLocations();
                            } else {
                              print("⚠️ Aucune gare trouvée à proximité !");
                            }
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.train, color: Colors.blueGrey),
                          title: Text("🚉 Choisir une gare"),
                          onTap: () {
                            setModalState(() {
                              _showGareList = true;
                              _filteredDepartureStations = _stations.keys.toList();
// reset filter
                            });
                          },
                        ),
                      ] else ...[
                        Text("🚉 Choisir une gare", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        TextField(
                          controller: _departureSearchController,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: "Rechercher une gare...",
                            hintStyle: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white54
                                  : Colors.black54,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[850]
                                : Colors.white,
                          ),
                          onChanged: (query) {
                            setModalState(() {
                              _filteredDepartureStations = _stations.keys
                                  .where((name) => name.toLowerCase().contains(query.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),

                        SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _filteredDepartureStations.length,
                            itemBuilder: (context, index) {
                              String name = _filteredDepartureStations[index];

                              return ListTile(
                                leading: Icon(Icons.location_on),
                                title: Text(name),
                                onTap: () {
                                  _polylines.clear(); // Supprime l’ancienne route bleue
                                  _markers.clear();   // Supprime les anciens marqueurs
                                  setState(() {
                                    _useCurrentLocationAsDeparture = false;

                                    // ✅ Sélection du départ
                                    _selectedDeparture = name;
                                    _searchMessage = null;
                                    _selectedDeparturePosition = _stations[name];

                                    // ✅ Suppression de la destination
                                    _selectedDestination = null;
                                    _selectedDestinationPosition = null;

                                    // ✅ Zoom + Marqueur vert
                                    _zoomOnStation(_stations[name]!);
                                    _addMarker(name, _stations[name]!, true);
                                  });

                                  // ✅ Tracer la ligne si les deux existent
                                  if (_selectedDeparture != null && _selectedDestination != null) {
                                    _drawSimpleRoute();
                                  }

                                  zoomToSelectedLocations();
                                  Navigator.pop(context);
                                },

                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      if (_selectedDeparture == null || _useCurrentLocationAsDeparture) {
        _departureSearchController.clear();
        _filteredDepartureStations = _stations.keys.toList();
      }
    });

  }

  void _showDestinationBottomSheet() {
    // Afficher toutes les gares au départ
    _filteredDestinationStations = _stations.keys.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "🚉 Choisir une gare de destination",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _departureSearchController,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: "Rechercher une gare...",
                          hintStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : Colors.black54,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[850]
                              : Colors.white,
                        ),
                        onChanged: (query) {
                          setModalState(() {
                            _filteredDestinationStations = _stations.keys
                                .where((name) => name.toLowerCase().contains(query.toLowerCase()))
                                .toList();

                          });
                        },
                      ),

                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _filteredDestinationStations.length,
                          itemBuilder: (context, index) {
                            String gare = _filteredDestinationStations[index];
                            return ListTile(
                              leading: Icon(Icons.location_on_outlined),
                              title: Text(gare),
                              onTap: () {
                                _polylines.clear(); // Supprime l’ancienne route bleue
                                _markers.clear();   // Supprime les anciens marqueurs
                                setState(() {
                                  _selectedDestination = gare;
                                  _searchMessage = null;
                                  _selectedDestinationPosition = _stations[gare];
                                  _zoomOnStation(_stations[gare]!);
                                  if (_selectedDeparture != null) _drawSimpleRoute();
                                });

                                zoomToSelectedLocations();
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },

      // ✅ Nettoyage si aucune gare n’a été sélectionnée
    ).whenComplete(() {
      if (_selectedDestination == null) {
        _destinationSearchController.clear();
        _filteredDestinationStations = _stations.keys.toList();
      }
    });
  }


  void drawRouteWithIntermediateStations() async {
    if (_selectedDeparture == null || _selectedDestination == null) return;

    // Vérifier si les gares sont sur la même ligne
    if (!_areStationsOnSameLine(_selectedDeparture!, _selectedDestination!)) {
      _showErrorDialog();
      return;
    }

    LatLng start = _stations[_selectedDeparture!]!;
    LatLng end = _stations[_selectedDestination!]!;
    List<LatLng> routePoints = [start];

    List<String> intermediateStations = await getIntermediateStations(
      _selectedDeparture!,
      _selectedDestination!,
    );

    // Récupérer les lignes des gares de départ et destination
    List<String> departureLines = _stationLines[_selectedDeparture!] ?? [];
    List<String> destinationLines = _stationLines[_selectedDestination!] ?? [];

    // Filtrer les gares qui partagent au moins une ligne avec la gare de départ ET avec la gare de destination
    intermediateStations = intermediateStations.where((station) {
      List<String> stationLines = _stationLines[station] ?? [];
      bool partageAvecDepart = stationLines.any((line) => departureLines.contains(line));
      bool partageAvecDestination = stationLines.any((line) => destinationLines.contains(line));
      return partageAvecDepart && partageAvecDestination;
    }).toList();

    setState(() {
      _polylines.clear();
      _markers.clear(); // Supprimer les anciens marqueurs

      // Ajouter le marqueur de départ
      _markers.add(
        Marker(
          markerId: MarkerId(_selectedDeparture!),
          position: start,
          infoWindow: InfoWindow(title: "🚆 Départ: $_selectedDeparture"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Ajouter les gares intermédiaires valides
      for (String station in intermediateStations) {
        if (_stations.containsKey(station)) {
          routePoints.add(_stations[station]!);
          _markers.add(
            Marker(
              markerId: MarkerId(station),
              position: _stations[station]!,
              infoWindow: InfoWindow(title: "🚉 Arrêt intermédiaire: $station"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      // Ajouter le marqueur de destination
      _markers.add(
        Marker(
          markerId: MarkerId(_selectedDestination!),
          position: end,
          infoWindow: InfoWindow(title: "🏁 Destination: $_selectedDestination"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      routePoints.add(end);

      _polylines.add(
        Polyline(
          polylineId: PolylineId("route"),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    });

    print("✅ Route mise à jour avec ${routePoints.length} points !");
  }

  bool _areStationsOnSameLine(String departure, String destination) {
    List<String>? departureLines = _stationLines[departure];
    List<String>? destinationLines = _stationLines[destination];

    print("🚆 Départ: $departure (${departureLines?.join(', ')})");
    print("🚆 Destination: $destination (${destinationLines?.join(', ')})");

    if (departureLines == null || destinationLines == null) return false;

    bool result = departureLines.any((line) => destinationLines.contains(line));
    print("✅ Les deux gares sont sur la même ligne ? $result");
    return result;
  }

  void _showErrorDialog() {
    setState(() {
      _polylines.clear(); // Effacer l'ancienne route
      _markers.clear();   // Effacer les marqueurs des gares intermédiaires
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("🚨 Chemin impossible"),
          content: Text("Les gares sélectionnées appartiennent à des lignes différentes."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day); // pour ignorer l'heure

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today, // empêche les dates passées
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                _mapController = controller;
              });
            },
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 10),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            polylines: _polylines,
          ),



          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                //color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Où souhaitez-vous aller aujourd'hui?",

                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: _showDepartureChoiceModal,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home, color: Color(0xFF1E1E1E)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _useCurrentLocationAsDeparture
                                  ? "📍 Ma position actuelle"
                                  : (_selectedDeparture ?? "🏠 Choisir un point de départ"),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showDestinationBottomSheet,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.train, color: Color(0xFF1E1E1E)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedDestination ?? "🚉 Choisir une gare de destination",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _selectDateTime(context),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF1E1E1E)),
                        SizedBox(width: 10),
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!)
                              : "📅 Choisir une date et heure",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _searchMessage = "Consulter les trajets de votre voyage"; // Met à jour le message après la recherche
                      });
                      _updateMarkers(); // Met à jour les marqueurs après sélection
                      drawRouteWithIntermediateStations(); // 👈 ajouter ceci
                      zoomToSelectedLocations();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  Color(0xFFA7CCAD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Center(
                      child: Text(
                        "Rechercher",
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Color(0xFF1E1E1E),
                        ),
                      ),
                    ),

                  ),

                  if (_searchMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_selectedDeparture != null && _selectedDestination != null && _selectedDate != null) {
                            _rechercherTrajets(context, _selectedDeparture!, _selectedDestination!, _selectedDate!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Veuillez choisir un départ, une destination et une date"))
                            );
                          }
                        },
                        icon: Icon(Icons.directions_transit,  color: Color(0xFF1E1E1E)),
                        label: Text("Consulter les trajets",style: TextStyle(fontSize: 18, color: Color(0xFF1E1E1E))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:  Color(0xFFCCE3F8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.symmetric(vertical: 12,horizontal: 80),
                        ),
                      ),
                    ),


                ],
              ),
            ),
          ),


          if (showMessage && widget.message != null)
            Positioned(
              top: 40,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.message!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

}
