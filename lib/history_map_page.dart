import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'location_point.dart';
import 'map_matching_service.dart';

class HistoryMapPage extends StatefulWidget {
  final List<LocationPoint> points;
  final LocationPoint? selectedPoint;

  const HistoryMapPage({
    super.key,
    required this.points,
    this.selectedPoint,
  });

  @override
  State<HistoryMapPage> createState() => _HistoryMapPageState();
}

class _HistoryMapPageState extends State<HistoryMapPage> {
  List<LatLng> _matchedRoute = [];
  bool _isLoading = true;
  String? _error;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _mapMatch();
  }

  void _centerMap() {
    final point = widget.selectedPoint;

    if (point != null) {
      _mapController.move(
        point.position,
        18,
      );
    } else if (widget.points.isNotEmpty) {
      final points = widget.points
          .map((point) => point.position)
          .toList();

      final bounds = LatLngBounds.fromPoints(points);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  Future<void> _mapMatch() async {
    try {
      final route = await MapMatchingService.matchRoute(
        widget.points,
      );

      if (!mounted) return;

      setState(() {
        _matchedRoute = route;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tuyến đường lịch sử'),
        ),
        body: const Center(
          child: Text(
            'Không có dữ liệu GPS trong khoảng thời gian này',
          ),
        ),
      );
    }

    final routePoints = widget.points
        .map((point) => point.position)
        .toList();

    final displayPoints = _matchedRoute.length >= 2
        ? _matchedRoute
        : routePoints;

    final bounds = LatLngBounds.fromPoints(displayPoints);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuyến đường lịch sử'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: displayPoints.first,
              initialZoom: 17,
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
              onMapReady: () {
                if (widget.selectedPoint != null) {
                  _centerMap();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'com.example.vi_tri_nguoi_dung',
              ),

              PolylineLayer(
                polylines: [
                  Polyline(
                    points: displayPoints,
                    strokeWidth: 5,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  if (widget.selectedPoint != null)
                    Marker(
                      point: widget.selectedPoint!.position,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        size: 50,
                      ),
                    ),
                  Marker(
                    point: routePoints.first,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.play_circle,
                      size: 40,
                    ),
                  ),
                  if (routePoints.length > 1)
                    Marker(
                      point: routePoints.last,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.flag,
                        size: 40,
                      ),
                    ),
                ],
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

          Positioned(
            right: 16,
            bottom: 80,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: _centerMap,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'center_route',
                  onPressed: () {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(50),
                      ),
                    );
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Đang map matching...'),
                    ],
                  ),
                ),
              ),
            ),

          if (_error != null)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Map matching thất bại:\n$_error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}