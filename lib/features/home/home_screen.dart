import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../widgets/primary_button.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final String? projectId;
  final String? projectName;
  const HomeScreen({super.key, this.projectId, this.projectName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VStack([
        if (projectId != null) ...[
          VxBox(
            child: HStack([
              const Icon(Icons.folder_open, color: Colors.white),
              8.widthBox,
              ('Project: ' + (projectName ?? projectId!)).text.white.semiBold.make(),
            ]).p12(),
          )
              .color(AppColors.navy)
              .withRounded(value: 8)
              .make()
              .px16()
              .py12(),
        ],
        const Spacer(),
        'No Rooms scanned yet'.text.semiBold.size(18).makeCentered(),
        8.heightBox,
        'Tap the "+" button to start scanning your first room.'.text.gray500.center.make().px16(),
        16.heightBox,
     PrimaryButton(
  label: 'Add Room',
  icon: Icons.add,
  iconInWhiteCircle: true,
  iconCircleColor: Colors.white,   // optional (defaults to white)
  iconColor: AppColors.navy,       // optional (defaults to navy)
  onPressed: () => context.push('/rooms/select'),
).w(150).centered(),
        const Spacer(),
      ]).p16(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          // Navigate to settings when settings tab tapped
          if (i == 1) {
            context.go('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Setting'),
        ],
      ),
    );
  }
}
