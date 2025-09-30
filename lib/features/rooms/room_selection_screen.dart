import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../widgets/primary_button.dart';
import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: 'Room Selection'.text.make(),
      ),
      body: SafeArea(
        child: VStack([
          'Which rooms are in scope?'.text.semiBold.size(18).make(),
          12.heightBox,
          ...rooms.entries.map((e) => _RoomTile(
                label: e.key,
                value: e.value,
                onChanged: (v) => setState(() => rooms[e.key] = v ?? false),
              )).toList(),
        ]).p16(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: PrimaryButton(
              label: 'Begin Scan',
              icon: Icons.qr_code_scanner_outlined,
              onPressed: () => context.push('/scan'),
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
  final ValueChanged<bool?> onChanged;
  const _RoomTile({required this.label, required this.value, required this.onChanged});

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
