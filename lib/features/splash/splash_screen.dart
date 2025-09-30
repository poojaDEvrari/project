import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart' show rootBundle;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasAssets = false;

  @override
  void initState() {
    super.initState();
    _checkAssets().then((_) {
      // Extended splash timing
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) context.go('/home');
      });
    });
  }

  Future<void> _checkAssets() async {
    // Check if user-provided splash assets exist to avoid runtime errors
    final bg = await _assetExists('assets/images/splash_bg.png');
    final logo = await _assetExists('assets/images/splash_logo.png');
    setState(() => _hasAssets = bg && logo);
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          // Background geometric lines if provided
          if (_hasAssets)
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_bg.png',
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(0.12),
                colorBlendMode: BlendMode.srcATop,
              ),
            ),
          // Center content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_hasAssets)
                    Image.asset('assets/images/splash_logo.png', width: 168)
                  else
                    VxCircle(
                      radius: 96,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      child: const Icon(Icons.account_balance, color: Colors.white, size: 56),
                    ),
                  if (!_hasAssets) ...[
                    16.heightBox,
                    'DIMENX'.text.white.extraBold.size(36).letterSpacing(2).make(),
                    8.heightBox,
                    'Scan. Detect. Estimate'.text.white.make().opacity(value: 0.9),
                  ],
                  24.heightBox,
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
