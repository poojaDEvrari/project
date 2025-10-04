import 'dart:collection';
import 'dart:io' show File;
import 'dart:convert' show json;
import 'package:path_provider/path_provider.dart';
import 'item_model.dart';

class ScanSession {
  static final ScanSession instance = ScanSession._internal();
  ScanSession._internal();

  List<String> _selectedRooms = [];
  final Set<String> _scannedRooms = <String>{};
  final Map<String, List<ItemModel>> _roomItems = {};

  void start(List<String> selectedRooms) {
    _selectedRooms = List<String>.from(selectedRooms);
    _scannedRooms.clear();
  }

  bool get hasStarted => _selectedRooms.isNotEmpty;

  UnmodifiableListView<String> get selectedRooms => UnmodifiableListView(_selectedRooms);
  UnmodifiableListView<String> get scannedRooms => UnmodifiableListView(_scannedRooms.toList());

  int get total => _selectedRooms.length;
  int get scannedCount => _scannedRooms.length;
  bool get isComplete => scannedCount >= total && total > 0;

  List<String> get remainingRooms => _selectedRooms.where((r) => !_scannedRooms.contains(r)).toList(growable: false);

  String? nextUnscanned() {
    for (final r in _selectedRooms) {
      if (!_scannedRooms.contains(r)) return r;
    }
    return null;
  }

  bool markScanned(String roomName) {
    if (_selectedRooms.contains(roomName)) {
      _scannedRooms.add(roomName);
      return true;
    }
    return false;
  }

  bool deleteRoom(String roomName) {
    bool removed = false;
    if (_selectedRooms.contains(roomName)) {
      _selectedRooms.remove(roomName);
      removed = true;
    }
    if (_scannedRooms.contains(roomName)) {
      _scannedRooms.remove(roomName);
      removed = true;
    }
    // remove items for the room as well
    if (_roomItems.containsKey(roomName)) {
      _roomItems.remove(roomName);
      removed = true;
    }
    return removed;
  }

  bool markUnscanned(String roomName) {
    return _scannedRooms.remove(roomName);
  }

  Future<String?> exportRoom(String roomName) async {
    try {
      final Map<String, dynamic> roomData = {
        'roomName': roomName,
        'isScanned': _scannedRooms.contains(roomName),
        'scanDate': DateTime.now().toIso8601String(),
        'totalRooms': _selectedRooms.length,
        'scannedRooms': _scannedRooms.toList(),
        'items': _roomItems[roomName]?.map((i) => i.toJson()).toList() ?? [],
      };

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'room_export_${roomName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(json.encode(roomData));

      return file.path;
    } catch (e) {
      return null;
    }
  }

  // Items API
  List<ItemModel> itemsFor(String roomName) {
    return List.unmodifiable(_roomItems[roomName] ?? <ItemModel>[]);
  }

  void addItem(String roomName, ItemModel item) {
    _roomItems.putIfAbsent(roomName, () => <ItemModel>[]);
    _roomItems[roomName]!.add(item);
  }

  bool deleteItem(String roomName, ItemModel item) {
    final list = _roomItems[roomName];
    if (list == null) return false;
    return list.remove(item);
  }
}
