
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'route_service.dart';
import 'location_point.dart';
import 'database_helper.dart';

class OsmMapPage extends StatefulWidget {
  const OsmMapPage({super.key});

  @override
  State<OsmMapPage> createState() => _OsmMapPageState();
}

class _OsmMapPageState extends State<OsmMapPage> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionStream;

  LatLng? _currentLocation;
  final List<LocationPoint> _locationHistory = [];

  LatLng? _destination;
  List<LatLng> _roadRoute = [];
  bool _isLoadingRoute = false;
  double? _routeDistance;
  double? _routeDuration;

  bool _isTracking = false;
  String _message = 'Nhấn Bắt đầu để theo dõi GPS';

  Future<bool> _checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() {
        _message = 'Vui lòng bật dịch vụ vị trí';
      });
      return false;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _message = 'Ứng dụng chưa được cấp quyền vị trí';
      });
      return false;
    }

    return true;
  }

  Future<void> _startTracking() async {
    if (_isTracking) return;

    final permitted = await _checkPermission();
    if (!permitted || !mounted) return;

    setState(() {
      _isTracking = true;
      _message = 'Đang chờ tín hiệu GPS...';
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
          (Position position) async {
        if (!mounted) return;

        final newPoint = LatLng(
          position.latitude,
          position.longitude,
        );

        final timestamp = DateTime.now();

        _locationHistory.add(
          LocationPoint(
            position: newPoint,
            timestamp: timestamp,
          ),
        );

        await DatabaseHelper.instance.insertLocation(
          latitude: newPoint.latitude,
          longitude: newPoint.longitude,
          timestamp: timestamp,
        );

        if (!mounted) return;

        setState(() {
          _currentLocation = newPoint;
          _message = 'Đang theo dõi vị trí';
        });

        _mapController.move(newPoint, 17);
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _message = 'Lỗi GPS: $error';
          _isTracking = false;
        });

        _positionStream = null;
      },
    );
  }

  Future<void> _stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;

    if (!mounted) return;

    setState(() {
      _isTracking = false;
      _message = 'Đã dừng theo dõi';
    });
    final locations = await DatabaseHelper.instance.getLocations();

    debugPrint('===== LOCATION HISTORY =====');
    debugPrint('Số điểm: ${locations.length}');

    for (final location in locations) {
      debugPrint(location.toString());
    }
  }

  void _goToCurrentLocation() {
    if (_currentLocation == null) {
      setState(() {
        _message = 'Chưa có vị trí GPS. Hãy bấm Bắt đầu.';
      });
      return;
    }

    _mapController.move(_currentLocation!, 17);
  }

  void _selectDestination(LatLng point) {
    setState(() {
      _destination = point;
      _roadRoute.clear();
      _routeDistance = null;
      _routeDuration = null;
      _message = 'Đã chọn điểm đến. Nhấn Tìm đường.';
    });
  }

  Future<void> _findRoute() async {
    if (_currentLocation == null) {
      setState(() {
        _message = 'Hãy bật GPS để xác định vị trí xuất phát.';
      });
      return;
    }

    if (_destination == null) {
      setState(() {
        _message = 'Hãy chạm vào bản đồ để chọn điểm đến.';
      });
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _message = 'Đang tìm đường...';
    });

    try {
      final result = await RouteService.getRoute(
        start: _currentLocation!,
        end: _destination!,
      );

      if (!mounted) return;

      setState(() {
        _roadRoute = result.points;
        _routeDistance = result.distance;
        _routeDuration = result.duration;
        _isLoadingRoute = false;
        _message = 'Đã tìm thấy tuyến đường.';
      });

      if (result.points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(result.points);

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingRoute = false;
        _message = 'Không thể tìm đường: $error';
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 45,
          ),
        ),
      );
    }
    if (_destination != null) {
      markers.add(
        Marker(
          point: _destination!,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 45,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                  37.4219999,
                  -122.0840575,
                ),
                initialZoom: 15,
                onTap: (tapPosition, point) {
                  _selectDestination(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'com.example.vi_tri_nguoi_dung',
                ),

                if (_roadRoute.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _roadRoute,
                        color: Colors.red,
                        strokeWidth: 6,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'osm_zoom_in',
                        onPressed: () {
                          final zoom = _mapController.camera.zoom;

                          _mapController.move(
                            _mapController.camera.center,
                            zoom + 1,
                          );
                        },
                        child: const Icon(Icons.add),
                      ),

                      const SizedBox(height: 8),

                      FloatingActionButton.small(
                        heroTag: 'osm_zoom_out',
                        onPressed: () {
                          final zoom = _mapController.camera.zoom;

                          _mapController.move(
                            _mapController.camera.center,
                            zoom - 1,
                          );
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),

                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (_routeDistance != null && _routeDuration != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Khoảng cách tuyến đường: '
                        '${(_routeDistance! / 1000).toStringAsFixed(2)} km',
                  ),
                  Text(
                    'Thời gian dự kiến: '
                        '${(_routeDuration! / 60).ceil()} phút',
                  ),
                ],
                if (_currentLocation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Lat: '
                        '${_currentLocation!.latitude.toStringAsFixed(6)}',
                  ),
                  Text(
                    'Lng: '
                        '${_currentLocation!.longitude.toStringAsFixed(6)}',
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                      _isTracking ? null : _startTracking,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bắt đầu'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoadingRoute ? null : _findRoute,
                      icon: _isLoadingRoute
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.directions),
                      label: Text(
                        _isLoadingRoute ? 'Đang tìm...' : 'Tìm đường',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                      _isTracking ? _stopTracking : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Dừng'),
                    ),
                    IconButton.filled(
                      onPressed: _goToCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      tooltip: 'Về vị trí hiện tại',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}