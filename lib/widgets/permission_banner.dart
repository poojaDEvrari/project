import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class PermissionBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback? onDismiss;
  const PermissionBanner({super.key, required this.title, required this.message, required this.onOpenSettings, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        border: Border.all(color: const Color(0xFFBFD7FF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2F80ED)),
            ),
            child: const Icon(Icons.info_outline, size: 16, color: Color(0xFF2F80ED)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.gray600, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onOpenSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Open Settings'),
                    ),
                    const Spacer(),
                    if (onDismiss != null)
                      TextButton(
                        onPressed: onDismiss,
                        child: const Text('Not Now', style: TextStyle(color: AppColors.gray600)),
                      ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
