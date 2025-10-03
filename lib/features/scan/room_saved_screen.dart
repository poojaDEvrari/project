import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../core/theme/app_colors.dart';

class RoomSavedScreen extends StatelessWidget {
  final int currentIndex;
  final int totalRooms;
  final String roomName;
  final String? imagePath;

  const RoomSavedScreen({
    super.key,
    this.currentIndex = 2,
    this.totalRooms = 5,
    this.roomName = 'Living Room',
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex >= totalRooms;
    final roomList = totalRooms > 0 ? List.generate(totalRooms, (i) => 'Room ${i + 1}') : ['Room 1'];
    final nextIndex = currentIndex + 1;
    final nextRoom = nextIndex <= roomList.length && nextIndex > 0 ? roomList[nextIndex - 1] : 'Next Room';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: 'Room Saved'.text.make(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF8EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 52),
              ),
              const SizedBox(height: 16),

              // Progress text
              (isLast ? 'All rooms completed.' : 'Room $currentIndex of $totalRooms complete.')
                  .text
                  .green600
                  .xl
                  .semiBold
                  .make(),
              const SizedBox(height: 8),

              // Title and subtitle
              '$roomName Saved Successfully'.text.xl.semiBold.make(),
              const SizedBox(height: 4),
              'You can review details anytime'.text.gray500.make(),

              const SizedBox(height: 24),

              // List of saved rooms (show current and upcoming)
              ...(() {
                final filtered = roomList.asMap().entries.where((entry) => entry.key < currentIndex && entry.key >= 0).map((entry) {
                  final index = entry.key;
                  return _SavedRoomCard(
                    title: entry.value,
                    imagePath: imagePath,
                    isCurrent: index == currentIndex - 1,
                  );
                }).toList();
                if (filtered.isEmpty) return [];
                final withSeparators = <Widget>[];
                for (var i = 0; i < filtered.length; i++) {
                  withSeparators.add(filtered[i]);
                  if (i < filtered.length - 1) {
                    withSeparators.add(const SizedBox(height: 12));
                  }
                }
                return withSeparators;
              })(),

              const SizedBox(height: 12),

              // Optional secondary action - removed as per request
              // SizedBox(
              //   height: 52,
              //   width: double.infinity,
              //   child: OutlinedButton(
              //     onPressed: () {},
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: Colors.black,
              //       side: const BorderSide(color: Color(0xFFCBD5E1)),
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //     ),
              //     child: const Text('View room details', style: TextStyle(fontWeight: FontWeight.w600)),
              //   ),
              // ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: isLast
                ? ElevatedButton(
                    onPressed: () => context.go('/rooms/scanned?total=$totalRooms'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Finish & review all spaces', style: TextStyle(fontWeight: FontWeight.w600)),
                  )
                : ElevatedButton.icon(
                    onPressed: () => context.go('/scan/running?room=${Uri.encodeComponent(nextRoom)}&index=$nextIndex&total=$totalRooms'),
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    label: const Text('Scan Next Room', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SavedRoomCard extends StatelessWidget {
  final String title;
  final String? imagePath;
  final bool isCurrent;
  const _SavedRoomCard({required this.title, this.imagePath, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: imagePath != null
                ? Image.file(
                    File(imagePath!),
                    width: 92,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 92,
                    height: 72,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.image, color: Colors.black38),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title.text.semiBold.make(),
                  const SizedBox(height: 4),
                  (isCurrent ? 'Just Scanned' : 'Previously Scanned').text.gray600.make(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
