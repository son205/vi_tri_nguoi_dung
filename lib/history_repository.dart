import 'database_helper.dart';
import 'location_point.dart';
import 'package:latlong2/latlong.dart';

class HistoryRepository {
  static Future<List<LocationPoint>> getHistory() async {
    final rows = await DatabaseHelper.instance.getLocations();

    return rows.map((row) {
      return LocationPoint(
        position: LatLng(
          (row['latitude'] as num).toDouble(),
          (row['longitude'] as num).toDouble(),
        ),
        timestamp: DateTime.parse(
          row['timestamp'] as String,
        ),
      );
    }).toList();
  }

  static Future<LocationPoint?> getNearestPoint(
      DateTime targetTime,
      ) async {
    final history = await getHistory();

    if (history.isEmpty) {
      return null;
    }

    LocationPoint nearest = history.first;

    Duration smallestDifference =
    (nearest.timestamp.difference(targetTime)).abs();

    for (final point in history.skip(1)) {
      final difference =
      (point.timestamp.difference(targetTime)).abs();

      if (difference < smallestDifference) {
        smallestDifference = difference;
        nearest = point;
      }
    }

    return nearest;
  }

  static Future<List<LocationPoint>> getPointsInTimeRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final history = await getHistory();

    return history.where((point) {
      return !point.timestamp.isBefore(startTime) &&
          !point.timestamp.isAfter(endTime);
    }).toList();
  }

  static Future<void> clearHistory() async {
    await DatabaseHelper.instance.clearLocations();
  }
}