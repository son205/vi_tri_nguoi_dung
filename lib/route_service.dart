import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distance;
  final double duration;

  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

class RouteService {
  static Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Không thể tìm tuyến đường');
    }

    final data = jsonDecode(response.body);

    if (data['code'] != 'Ok' ||
        (data['routes'] as List).isEmpty) {
      throw Exception('Không tìm thấy tuyến đường');
    }

    final route = data['routes'][0];

    final coordinates =
    route['geometry']['coordinates'] as List;

    final points = coordinates.map((point) {
      return LatLng(
        (point[1] as num).toDouble(),
        (point[0] as num).toDouble(),
      );
    }).toList();

    return RouteResult(
      points: points,
      distance: (route['distance'] as num).toDouble(),
      duration: (route['duration'] as num).toDouble(),
    );
  }
}