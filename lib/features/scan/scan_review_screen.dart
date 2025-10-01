import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';

enum ScanQuality { excellent, fair, poor }

ScanQuality _parseQuality(String? q) {
  switch (q?.toLowerCase()) {
    case 'excellent':
      return ScanQuality.excellent;
    case 'fair':
      return ScanQuality.fair;
    case 'poor':
      return ScanQuality.poor;
    default:
      return ScanQuality.excellent;
  }
}

class ScanReviewScreen extends StatelessWidget {
  final ScanQuality quality;
  const ScanReviewScreen({super.key, required this.quality});

  Color _qualityColor(ScanQuality q) {
    switch (q) {
      case ScanQuality.excellent:
        return const Color(0xFF2DBE6C); // green
      case ScanQuality.fair:
        return const Color(0xFFFFA726); // orange
      case ScanQuality.poor:
        return const Color(0xFFE53935); // red
    }
  }

  String _qualityLabel(ScanQuality q) {
    switch (q) {
      case ScanQuality.excellent:
        return 'Excellent';
      case ScanQuality.fair:
        return 'Fair';
      case ScanQuality.poor:
        return 'Poor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _qualityColor(quality);
    final label = _qualityLabel(quality);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: 'Review Room'.text.make(),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: AssetImage('assets/images/splash_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Bottom sheet style controls area
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Scan Quality:', style: TextStyle(fontWeight: FontWeight.w600)),
                        6.widthBox,
                        Text(
                          label,
                          style: TextStyle(color: color, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    12.heightBox,
                    Row(
                      children: [
                        // Rescan button (outlined white)
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: PrimaryButton(
                              label: 'Rescan',
                              bgColor: Colors.white,
                              fgColor: AppColors.navy,
                              onPressed: () => context.go('/scan/running'),
                            ),
                          ),
                        ),
                        12.widthBox,
                        // Save button only when quality is not poor
                        if (quality != ScanQuality.poor)
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: PrimaryButton(
                                label: 'Save',
                                bgColor: AppColors.navy,
                                fgColor: Colors.white,
                                onPressed: () => context.go('/home'),
                              ),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
