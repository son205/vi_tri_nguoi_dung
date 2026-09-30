import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  Position? _currentPosition;

  final List<LatLng> _routePoints = [];

  double _totalDistance = 0;

  bool _isTracking = false;

  String _message = 'Nhấn Bắt đầu để theo dõi GPS';

  static const LatLng _defaultLocation = LatLng(
    37.4219999,
    -122.0840575,
  );

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
          (Position position) {
        if (!mounted) return;

        final newPoint = LatLng(
          position.latitude,
          position.longitude,
        );

        setState(() {
          if (_routePoints.isNotEmpty) {
            final lastPoint = _routePoints.last;

            _totalDistance += Geolocator.distanceBetween(
              lastPoint.latitude,
              lastPoint.longitude,
              newPoint.latitude,
              newPoint.longitude,
            );
          }

          _currentPosition = position;

          _routePoints.add(newPoint);

          _message = 'Đang theo dõi vị trí';
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newPoint),
        );
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
  }

  Future<void> _goToCurrentLocation() async {
    Position? position = _currentPosition;

    if (position == null) {
      final permitted = await _checkPermission();

      if (!permitted || !mounted) return;

      position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });
    }

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            position.latitude,
            position.longitude,
          ),
          zoom: 17,
        ),
      ),
    );
  }

  void _clearHistory() {
    setState(() {
      _routePoints.clear();

      _totalDistance = 0;

      _message = _isTracking
          ? 'Đang theo dõi vị trí'
          : 'Đã xóa lịch sử di chuyển';
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'Vị trí hiện tại',
          ),
        ),
      );
    }

    final polylines = <Polyline>{};

    if (_routePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('tracking_route'),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete),
                tooltip: 'Xóa lịch sử',
              ),
            ],
          ),
        ),

        Expanded(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            markers: markers,
            polylines: polylines,
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Text(
                _message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Số điểm GPS: ${_routePoints.length}',
              ),

              Text(
                'Quãng đường: '
                    '${_totalDistance.toStringAsFixed(1)} m',
              ),

              if (_currentPosition != null) ...[
                const SizedBox(height: 6),

                Text(
                  'Lat: '
                      '${_currentPosition!.latitude.toStringAsFixed(6)}',
                ),

                Text(
                  'Lng: '
                      '${_currentPosition!.longitude.toStringAsFixed(6)}',
                ),
              ],

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isTracking
                        ? null
                        : _startTracking,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Bắt đầu'),
                  ),

                  const SizedBox(width: 12),

                  ElevatedButton.icon(
                    onPressed: _isTracking
                        ? _stopTracking
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Dừng'),
                  ),

                  const SizedBox(width: 12),

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
    );
  }
}