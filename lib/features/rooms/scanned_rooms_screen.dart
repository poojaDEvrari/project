import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/scan_session.dart';

class ScannedRoomsScreen extends StatefulWidget {
  final int totalRooms;
  const ScannedRoomsScreen({super.key, this.totalRooms = 5});

  @override
  State<ScannedRoomsScreen> createState() => _ScannedRoomsScreenState();
}

class _ScannedRoomsScreenState extends State<ScannedRoomsScreen> {
  void _refreshRooms() {
    setState(() {});
  }

  Future<void> _handleMenuAction(String action, String roomName) async {
    switch (action) {
      case 'rescan':
        // Navigate to scan screen to rescan the room
        final session = ScanSession.instance;
        final roomIndex = session.selectedRooms.toList().indexOf(roomName) + 1;
        final totalRooms = session.total;

        context.push('/scan?total=$totalRooms&room=${Uri.encodeComponent(roomName)}&index=$roomIndex');
        break;
      case 'delete':
        _showDeleteConfirmation(context, roomName);
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    final session = ScanSession.instance;
    final hasSession = session.hasStarted;
    final total = hasSession ? session.total : widget.totalRooms;
    final scannedRooms = hasSession && session.scannedRooms.isNotEmpty
        ? session.scannedRooms
        : (total > 0 ? List.generate(total.clamp(0, 3), (i) => 'Room ${i + 1}') : <String>['Room 1']);
    final bottomInset = MediaQuery.of(context).padding.bottom + 24.0; // nav bars + extra spacing

    return Scaffold(
      appBar: AppBar(
        title: 'Scanned Rooms'.text.make(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
          children: [
            ...(() {
              final withSeparators = <Widget>[];
              for (var i = 0; i < scannedRooms.length; i++) {
                final title = scannedRooms[i];
                withSeparators.add(_ScannedRoomCard(
                  title: title,
                  status: 'Fully Scanned',
                  onMenuAction: _handleMenuAction,
                ));
                if (i < scannedRooms.length - 1) {
                  withSeparators.add(const SizedBox(height: 12));
                }
              }
              return withSeparators;
            })(),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go('/rooms/select'),
              child: Container(
                height: 100,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.black87),
                    const SizedBox(width: 8),
                    'Add Room'.text.semiBold.make(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String roomName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Room'),
          content: Text('Are you sure you want to delete "$roomName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final success = ScanSession.instance.deleteRoom(roomName);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '$roomName deleted successfully' : 'Failed to delete room')),
                );
                _refreshRooms();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _ScannedRoomCard extends StatelessWidget {
  final String title;
  final String status;
  final Function(String, String) onMenuAction;

  const _ScannedRoomCard({
    required this.title,
    required this.status,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 64,
            height: 48,
            color: const Color(0xFFF1F5F9),
            child: const Icon(Icons.image, color: Colors.black38),
          ),
        ),
        title: title.text.semiBold.make(),
        subtitle: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
            const SizedBox(width: 6),
            status.text.color(const Color(0xFF16A34A)).make(),
          ],
        ),
        trailing: Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: const PopupMenuThemeData(
              elevation: 8,
            ),
          ),
          child: PopupMenuButton<String>(
            onSelected: (value) => onMenuAction(value, title),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'rescan',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Rescan'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Room', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          context.push('/room-details?room=${Uri.encodeComponent(title)}');
        },
      ),
    );
  }
}


class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (i) {
        if (i == 0) return; // Home
        if (i == 1) {
          context.go('/settings');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Setting'),
      ],
    );
  }
}

