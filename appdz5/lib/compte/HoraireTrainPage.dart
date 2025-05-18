import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HoraireTrainPage extends StatefulWidget {
  @override
  _HoraireTrainPageState createState() => _HoraireTrainPageState();
}

class _HoraireTrainPageState extends State<HoraireTrainPage> {
  String searchQuery = '';
  bool isFilterVisible = false;
  String selectedSortOrder = 'asc';
  String selectedSortBy = 'none';
  TimeOfDay? minDepartureTime;
  TimeOfDay? maxDepartureTime;

  List<Map<String, dynamic>> horaires = [
    {
      'id': 1,
      'depart': 'Alger',
      'arret': 'El Harrach',
      'heure_arrivee': '08:30',
      'heure_depart': '08:00',
      'train': 'Train A',
      'ligne_id': '1',
      'jour_circulation': 'Lundi',
    },
    {
      'id': 2,
      'depart': 'Bab Ezzouar',
      'arret': 'Dar El Beida',
      'heure_arrivee': '09:00',
      'heure_depart': '08:45',
      'train': 'Train B',
      'ligne_id': '2',
      'jour_circulation': 'Mardi',
    },
    // Ajoute d'autres horaires ici
  ];

  List<Map<String, dynamic>> get filteredHoraires {
    final filtered = horaires.where((horaire) {
      final matchesSearch = horaire['depart']
          .toLowerCase()
          .contains(searchQuery.toLowerCase()) ||
          horaire['arret'].toLowerCase().contains(searchQuery.toLowerCase());

      final heureDepart =
      TimeOfDay.fromDateTime(DateTime.parse('2022-01-01 ' +
          horaire['heure_depart'] +
          ':00'));

      final matchesMinTime = minDepartureTime == null ||
          (heureDepart.hour > minDepartureTime!.hour ||
              (heureDepart.hour == minDepartureTime!.hour &&
                  heureDepart.minute >= minDepartureTime!.minute));
      final matchesMaxTime = maxDepartureTime == null ||
          (heureDepart.hour < maxDepartureTime!.hour ||
              (heureDepart.hour == maxDepartureTime!.hour &&
                  heureDepart.minute <= maxDepartureTime!.minute));

      return matchesSearch && matchesMinTime && matchesMaxTime;
    }).toList();

    if (selectedSortBy != 'none') {
      filtered.sort((a, b) {
        final aValue = a[selectedSortBy];
        final bValue = b[selectedSortBy];

        if (selectedSortOrder == 'asc') {
          return aValue.compareTo(bValue);
        } else {
          return bValue.compareTo(aValue);
        }
      });
    }

    return filtered;
  }

  Future<void> _selectTime(BuildContext context, bool isMin) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMin
          ? (minDepartureTime ?? TimeOfDay.now())
          : (maxDepartureTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isMin) {
          minDepartureTime = picked;
        } else {
          maxDepartureTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        backgroundColor: Color(0xFE888111),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: loc.search,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                icon: Icon(Icons.filter_list),
                label: Text(loc.filter),
                onPressed: () {
                  setState(() {
                    isFilterVisible = !isFilterVisible;
                  });
                },
              ),
              DropdownButton<String>(
                value: selectedSortOrder,
                style: TextStyle(color: Colors.black),
                items: [
                  DropdownMenuItem(
                    value: 'asc',
                    child: Text(loc.ascending),
                  ),
                  DropdownMenuItem(
                    value: 'desc',
                    child: Text(loc.descending),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSortOrder = value!;
                  });
                },
              ),
              DropdownButton<String>(
                style: TextStyle(color: Colors.black),
                value: selectedSortBy,
                items: [
                  DropdownMenuItem(
                    value: 'none',
                    child: Text(loc.none),
                  ),
                  DropdownMenuItem(
                    value: 'heure_depart',
                    child: Text(loc.time),
                  ),
                  DropdownMenuItem(
                    value: 'ligne_id',
                    child: Text(loc.line),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSortBy = value!;
                  });
                },
              ),
            ],
          ),
          if (isFilterVisible)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(loc.time_Range),
                  Row(
                    children: [
                      Text('${loc.minDepartureTime} '),
                      TextButton(
                        onPressed: () => _selectTime(context, true),
                        child: Text(minDepartureTime?.format(context) ??
                            loc.select),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${loc.maxDepartureTime} '),
                      TextButton(
                        onPressed: () => _selectTime(context, false),
                        child: Text(maxDepartureTime?.format(context) ??
                            loc.select),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            minDepartureTime = null;
                            maxDepartureTime = null;
                          });
                        },
                        child: Text(loc.reset),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: Text(loc.apply),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredHoraires.length,
              itemBuilder: (context, index) {
                final horaire = filteredHoraires[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                        '${loc.departure}: ${horaire['depart']} - ${loc.stop}: ${horaire['arret']}'
                        ,style: TextStyle(color: Colors.black),
                  ),
                    subtitle: Text(
                        '${loc.arrivalTime}: ${horaire['heure_arrivee']}, ${loc.departureTime}: ${horaire['heure_depart']}'),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${loc.train}: ${horaire['train']}'),
                        Text('${loc.lineId}: ${horaire['ligne_id']}'),
                        Text('${loc.circulationDay}: ${horaire['jour_circulation']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
