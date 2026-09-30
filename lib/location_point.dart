import 'package:latlong2/latlong.dart';

class LocationPoint {
  final LatLng position;
  final DateTime timestamp;

  LocationPoint({
    required this.position,
    required this.timestamp,
  });
}
