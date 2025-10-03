import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../widgets/primary_button.dart';
import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/scan_session.dart';

class RoomSelectionScreen extends StatefulWidget {
  const RoomSelectionScreen({super.key});

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  final Map<String, bool> rooms = {
    'Bedroom': true,
    'Bathroom': false,
    'Kitchen': false,
    'Living Room': false,
    'Dining Room': false,
    'Hallway': false,
    'laundry Room': false,
  };

  // For choosing the next room during an active session
  Map<String, bool> _nextRooms = {};

  @override
  Widget build(BuildContext context) {
    final session = ScanSession.instance;
    final hasSession = session.hasStarted;
    // Keep _nextRooms in sync with remaining rooms
    if (hasSession) {
      final remaining = session.remainingRooms;
      // Reinitialize if keys differ
      final needsInit = _nextRooms.keys.toSet().length != remaining.toSet().length ||
          !_nextRooms.keys.toSet().containsAll(remaining);
      if (needsInit) {
        _nextRooms = {for (final r in remaining) r: false};
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: (hasSession ? 'Select Next Room' : 'Room Selection').text.make(),
      ),
      body: SafeArea(
        child: VStack([
          if (!hasSession) ...[
            'Which rooms are in scope?'.text.semiBold.size(18).make(),
            12.heightBox,
            ...rooms.entries.map((e) => _RoomTile(
                  label: e.key,
                  value: e.value,
                  onChanged: (v) => setState(() => rooms[e.key] = v ?? false),
                )).toList(),
          ] else ...[
            'Choose next room to scan'.text.semiBold.size(18).make(),
            12.heightBox,
            // Remaining rooms (selectable)
            ..._nextRooms.entries.map((e) => _RoomTile(
                  label: e.key,
                  value: e.value,
                  onChanged: (v) => setState(() => _nextRooms[e.key] = v ?? false),
                )).toList(),
            16.heightBox,
            // Already scanned (disabled)
            if (session.scannedCount > 0) ...[
              'Already scanned'.text.size(14).gray500.make(),
              8.heightBox,
              ...session.scannedRooms.map((r) => _RoomTile(
                    label: r,
                    value: true,
                    onChanged: null, // disabled
                  )),
            ],
          ],
        ]).p16(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: PrimaryButton(
              label: hasSession ? 'Begin Scan' : 'Begin Scan',
              icon: Icons.qr_code_scanner_outlined,
              onPressed: () {
                if (!hasSession) {
                  final selected = rooms.entries.where((e) => e.value).map((e) => e.key).toList();
                  if (selected.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one room')),
                    );
                    return;
                  }
                  final total = selected.length;
                  final firstRoom = selected.first;
                  // Initialize scan session with selected rooms
                  ScanSession.instance.start(selected);
                  context.push('/scan?total=$total&room=${Uri.encodeComponent(firstRoom)}&index=1');
                  return;
                }

                // Active session: pick exactly one remaining room
                final nextSelected = _nextRooms.entries.where((e) => e.value).map((e) => e.key).toList();
                if (nextSelected.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please choose a room to scan next')),
                  );
                  return;
                }
                final chosen = nextSelected.first;
                final idx = session.scannedCount + 1;
                final total = session.total;
                context.push('/scan?total=$total&room=${Uri.encodeComponent(chosen)}&index=$idx');
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  const _RoomTile({required this.label, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool selected = value;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: selected ? AppColors.navy : AppColors.gray200, width: selected ? 1.4 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        title: label.text.semiBold.color(AppColors.navy).make(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        activeColor: AppColors.navy,
        checkColor: Colors.white,
        side: BorderSide(color: AppColors.gray400, width: 1),
      ),
    ).pOnly(bottom: 12);
  }
}
