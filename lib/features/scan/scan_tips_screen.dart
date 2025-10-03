import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';

class ScanTipsScreen extends StatelessWidget {
  final int totalRooms;
  final String roomName;
  final int index;
  const ScanTipsScreen({super.key, required this.totalRooms, required this.roomName, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: roomName.text.make(),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Room $index of $totalRooms',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: VStack([
          // Tip banner
          HStack([
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2F80ED)),
              ),
              child: const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF2F80ED)),
            ),
            14.widthBox,
            'Good lighting improves edge\ndetection.'
                .text
                .color(AppColors.navy)
                .semiBold
                .make(),
          ])
              .p16()
              .box
              .color(const Color(0xFFEAF2FF))
              .border(color: const Color(0xFFBFD7FF))
              .roundedSM
              .shadowSm
              .make(),
        ]).p16(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            child: PrimaryButton(
              label: 'Begin Scan',
              icon: Icons.qr_code_scanner_outlined,
              bgColor: AppColors.navy,
              fgColor: Colors.white,
              onPressed: () => context.push('/scan/running?room=${Uri.encodeComponent(roomName)}&index=$index&total=$totalRooms'),
            ),
          ),
        ),
      ),
    );
  }
}
