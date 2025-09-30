import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../widgets/primary_button.dart';

class CalibrationGuideScreen extends StatelessWidget {
  const CalibrationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: 'How to Calibrate'.text.make()),
      body: SafeArea(
        child: VStack([
          'Prefer to watch how it\'s done?'.text.semiBold.size(18).make(),
          6.heightBox,
          'Play the video above for a quick walkthrough.'.text.gray600.size(14).make(),
          12.heightBox,
          // video placeholder
          VxBox(child: const Icon(Icons.play_circle_fill, size: 56))
              .roundedLg
              .color(const Color(0xFFECEFF4))
              .height(160)
              .make(),
          16.heightBox,
          'Place an A4/Letter sheet fully in view.'.text.semiBold.make(),
          8.heightBox,
          'Note: If you don\'t have a sheet, use any flat object with known size.'.text.gray600.size(13).make(),
          16.heightBox,
          '2. Hold steady and pan slowly left→right.'.text.semiBold.make(),
          16.heightBox,
          'Keep the entire sheet inside the frame.'.text.semiBold.make(),
          const Spacer(),
          HStack([
            const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF2F80ED)),
            8.widthBox,
            'Tip: Use good lighting for best results.'.text.color(const Color(0xFF2F80ED)).make(),
          ]),
          12.heightBox,
          PrimaryButton(label: 'Start Calibration', onPressed: () {}),
        ]).p16(),
      ),
    );
  }
}
