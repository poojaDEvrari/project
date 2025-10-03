import 'dart:collection';

class ScanSession {
  static final ScanSession instance = ScanSession._internal();
  ScanSession._internal();

  List<String> _selectedRooms = [];
  final Set<String> _scannedRooms = <String>{};

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
}
