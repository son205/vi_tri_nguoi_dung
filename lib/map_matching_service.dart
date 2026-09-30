import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'location_point.dart';

class MapMatchingService {
  static Future<List<LatLng>> matchRoute(
      List<LocationPoint> points,
      ) async {
    if (points.length < 2) {
      return points.map((point) => point.position).toList();
    }

    final coordinates = points.map((point) {
      return '${point.position.longitude},${point.position.latitude}';
    }).join(';');

    final timestamps = points.map((point) {
      return point.timestamp.millisecondsSinceEpoch ~/ 1000;
    }).join(';');

    final url = Uri.parse(
      'https://router.project-osrm.org/match/v1/driving/'
          '$coordinates'
          '?overview=full'
          '&geometries=geojson'
          '&timestamps=$timestamps',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Không thể map matching tuyến đường');
    }

    final data = jsonDecode(response.body);

    if (data['code'] != 'Ok') {
      throw Exception(
        'OSRM không thể khớp tuyến đường',
      );
    }

    final matches = data['matchings'] as List;

    if (matches.isEmpty) {
      throw Exception(
        'Không tìm thấy tuyến đường phù hợp',
      );
    }

    final geometry =
    matches.first['geometry']['coordinates'] as List;

    return geometry.map((point) {
      return LatLng(
        (point[1] as num).toDouble(),
        (point[0] as num).toDouble(),
      );
    }).toList();
  }
}