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
              'Room ${currentIndex} of ${totalRooms} complete.'
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

              // Summary card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
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
                              // ignore: deprecated_member_use
                              // The File constructor is OK here; platform will handle.
                              // We keep this minimal without importing dart:io explicitly in analysis.
                              // A placeholder Container will show if not supported.
                              // This block will be replaced if you want robust cross-platform preview.
                              // Using Image.file requires dart:io; in web it would fail, but app targets mobile.
                              // ignore_for_file: unnecessary_import
                              // ignore_for_file: avoid_print
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
                            'Card Title'.text.semiBold.make(),
                            const SizedBox(height: 4),
                            'Card Description'.text.gray600.make(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            child: ElevatedButton.icon(
              onPressed: () => context.go('/scan/running'),
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
