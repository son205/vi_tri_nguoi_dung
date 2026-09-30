
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'history_repository.dart';
import 'location_point.dart';
import 'history_map_page.dart';

class HistoryPage extends StatefulWidget {
const HistoryPage({super.key});

@override
State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
List<LocationPoint> _history = [];
bool _isLoading = true;

LocationPoint? _selectedPoint;

DateTime? _startTime;
DateTime? _endTime;

List<LocationPoint> _rangePoints = [];

@override
void initState() {
super.initState();
_loadHistory();
}

// =========================
// LOAD HISTORY
// =========================

Future<void> _loadHistory() async {
final history = await HistoryRepository.getHistory();

if (!mounted) return;

setState(() {
_history = history;
_isLoading = false;
});
}

// =========================
// CALCULATE DISTANCE
// =========================

double _calculateDistance(List<LocationPoint> points) {
double distance = 0;

for (int i = 1; i < points.length; i++) {
final previous = points[i - 1].position;
final current = points[i].position;

distance += Geolocator.distanceBetween(
previous.latitude,
previous.longitude,
current.latitude,
current.longitude,
);
}

return distance;
}

// =========================
// FORMAT DISTANCE
// =========================

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(2)} km';
}

return '${distance.toStringAsFixed(1)} m';
}

// =========================
// FORMAT DURATION
// =========================

String _formatDuration(DateTime start, DateTime end) {
final duration = end.difference(start);

final hours = duration.inHours;
final minutes = duration.inMinutes.remainder(60);
final seconds = duration.inSeconds.remainder(60);

if (hours > 0) {
return '$hours giờ $minutes phút';
}

if (minutes > 0) {
return '$minutes phút $seconds giây';
}

return '$seconds giây';
}

// =========================
// SELECT A TIME
// =========================

Future<void> _selectTime() async {
final date = await showDatePicker(
context: context,
initialDate: DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime.now(),
);

if (date == null || !mounted) return;

final time = await showTimePicker(
context: context,
initialTime: TimeOfDay.now(),
);

if (time == null || !mounted) return;

final targetTime = DateTime(
date.year,
date.month,
date.day,
time.hour,
time.minute,
);

final point = await HistoryRepository.getNearestPoint(
targetTime,
);

if (!mounted) return;

setState(() {
_selectedPoint = point;
});
}

// =========================
// SELECT START TIME
// =========================

Future<void> _selectStartTime() async {
final date = await showDatePicker(
context: context,
initialDate: _startTime ?? DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime.now(),
);

if (date == null || !mounted) return;

final time = await showTimePicker(
context: context,
initialTime: _startTime != null
? TimeOfDay.fromDateTime(_startTime!)
    : TimeOfDay.now(),
);

if (time == null || !mounted) return;

setState(() {
_startTime = DateTime(
date.year,
date.month,
date.day,
time.hour,
time.minute,
);
});

await _updateRange();
}

// =========================
// SELECT END TIME
// =========================

Future<void> _selectEndTime() async {
final date = await showDatePicker(
context: context,
initialDate: _endTime ?? _startTime ?? DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime.now(),
);

if (date == null || !mounted) return;

final time = await showTimePicker(
context: context,
initialTime: _endTime != null
? TimeOfDay.fromDateTime(_endTime!)
    : TimeOfDay.now(),
);

if (time == null || !mounted) return;

setState(() {
_endTime = DateTime(
date.year,
date.month,
date.day,
time.hour,
time.minute,
);
});

await _updateRange();
}

// =========================
// UPDATE TIME RANGE
// =========================

Future<void> _updateRange() async {
if (_startTime == null || _endTime == null) {
return;
}

if (_endTime!.isBefore(_startTime!)) {
setState(() {
_rangePoints = [];
});
return;
}

final points = await HistoryRepository.getPointsInTimeRange(
startTime: _startTime!,
endTime: _endTime!,
);

if (!mounted) return;

setState(() {
_rangePoints = points;
});
}

// =========================
// CLEAR HISTORY
// =========================

Future<void> _confirmClearHistory() async {
final confirmed = await showDialog<bool>(
context: context,
builder: (context) {
return AlertDialog(
title: const Text('Xóa lịch sử?'),
content: const Text(
'Bạn có chắc muốn xóa toàn bộ lịch sử di chuyển không?',
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(context, false);
},
child: const Text('Hủy'),
),
FilledButton(
onPressed: () {
Navigator.pop(context, true);
},
child: const Text('Xóa'),
),
],
);
},
);

if (confirmed != true || !mounted) return;

await HistoryRepository.clearHistory();

if (!mounted) return;

setState(() {
_history = [];
_selectedPoint = null;
_startTime = null;
_endTime = null;
_rangePoints = [];
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Đã xóa toàn bộ lịch sử di chuyển'),
),
);
}

// =========================
// BUILD
// =========================

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Lịch sử di chuyển'),
actions: [
IconButton(
icon: const Icon(Icons.delete_outline),
tooltip: 'Xóa lịch sử',
onPressed:
_history.isEmpty ? null : _confirmClearHistory,
),
],
),
body: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
    : _history.isEmpty
? const Center(
child: Text('Chưa có lịch sử di chuyển'),
)
    : Column(
children: [
Padding(
padding: const EdgeInsets.all(12),
child: Column(
children: [
// =========================
// CHỌN THỜI ĐIỂM
// =========================

ElevatedButton.icon(
onPressed: _selectTime,
icon: const Icon(Icons.access_time),
label: const Text('Chọn thời gian'),
),

const SizedBox(height: 8),

// =========================
// CHỌN KHOẢNG THỜI GIAN
// =========================

Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: _selectStartTime,
child: Column(
children: [
const Text('Bắt đầu'),
const SizedBox(height: 4),
Text(
_startTime == null
? '--/-- --:--'
    : '${_startTime!.day.toString().padLeft(2, '0')}/'
'${_startTime!.month.toString().padLeft(2, '0')} '
'${_startTime!.hour.toString().padLeft(2, '0')}:'
'${_startTime!.minute.toString().padLeft(2, '0')}',
),
],
),
),
),

const SizedBox(width: 12),

Expanded(
child: OutlinedButton(
onPressed: _selectEndTime,
child: Column(
children: [
const Text('Kết thúc'),
const SizedBox(height: 4),
Text(
_endTime == null
? '--/-- --:--'
    : '${_endTime!.day.toString().padLeft(2, '0')}/'
'${_endTime!.month.toString().padLeft(2, '0')} '
'${_endTime!.hour.toString().padLeft(2, '0')}:'
'${_endTime!.minute.toString().padLeft(2, '0')}',
),
],
),
),
),
],
),

// =========================
// THÔNG SỐ KHOẢNG THỜI GIAN
// =========================

if (_startTime != null &&
_endTime != null) ...[
const SizedBox(height: 8),

Card(
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
children: [
const Text(
'Thông tin chuyến di chuyển',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),

const SizedBox(height: 8),

Text(
'Thời gian: '
'${_startTime!.hour.toString().padLeft(2, '0')}:'
'${_startTime!.minute.toString().padLeft(2, '0')}'
' → '
'${_endTime!.hour.toString().padLeft(2, '0')}:'
'${_endTime!.minute.toString().padLeft(2, '0')}',
),

const SizedBox(height: 4),

Text(
'Thời lượng: '
'${_formatDuration(_startTime!, _endTime!)}',
),

const SizedBox(height: 4),

Text(
'Số điểm GPS: ${_rangePoints.length}',
),

const SizedBox(height: 4),

Text(
'Quãng đường: '
'${_formatDistance(
_calculateDistance(_rangePoints),
)}',
),

if (_rangePoints.length >= 2) ...[
const SizedBox(height: 10),

ElevatedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
HistoryMapPage(
points: _rangePoints,
),
),
);
},
icon: const Icon(Icons.map),
label: const Text(
'Xem tuyến đường',
),
),
],
],
),
),
),
],

// =========================
// VỊ TRÍ TẠI THỜI ĐIỂM ĐÃ CHỌN
// =========================

if (_selectedPoint != null) ...[
const SizedBox(height: 8),

Card(
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
children: [
const Text(
'Vị trí gần thời gian đã chọn',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 6),

Text(
'Lat: '
'${_selectedPoint!.position.latitude.toStringAsFixed(6)}',
),

Text(
'Lng: '
'${_selectedPoint!.position.longitude.toStringAsFixed(6)}',
),

Text(
'Thời gian: '
'${_selectedPoint!.timestamp}',
),

const SizedBox(height: 8),

ElevatedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
HistoryMapPage(
points: [
_selectedPoint!
],
selectedPoint:
_selectedPoint,
),
),
);
},
icon: const Icon(Icons.map),
label: const Text(
'Xem vị trí trên bản đồ',
),
),
],
),
),
),
],
],
),
),

// =========================
// DANH SÁCH LỊCH SỬ
// =========================

Expanded(
child: ListView.builder(
itemCount: _history.length,
itemBuilder: (context, index) {
final point = _history[index];

return ListTile(
leading: const Icon(
Icons.location_on,
),
title: Text(
'${point.position.latitude.toStringAsFixed(6)}, '
'${point.position.longitude.toStringAsFixed(6)}',
),
subtitle: Text(
point.timestamp.toString(),
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
