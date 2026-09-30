import 'package:flutter/material.dart';

import 'google_map_page.dart';
import 'osm_map_page.dart';
import 'history_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vị trí người dùng',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _useOsm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ vị trí'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử di chuyển',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Google Maps'),
                  icon: Icon(Icons.map),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('OpenStreetMap'),
                  icon: Icon(Icons.public),
                ),
              ],
              selected: {_useOsm},
              onSelectionChanged: (selection) {
                setState(() {
                  _useOsm = selection.first;
                });
              },
            ),
          ),
          Expanded(
            child: _useOsm
                ? const OsmMapPage()
                : const GoogleMapPage(),
          ),
        ],
      ),
    );
  }
}