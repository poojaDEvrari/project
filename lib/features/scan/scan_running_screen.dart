import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:camera/camera.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';

class ScanRunningScreen extends StatefulWidget {
  const ScanRunningScreen({super.key});

  @override
  State<ScanRunningScreen> createState() => _ScanRunningScreenState();
}

class _ScanRunningScreenState extends State<ScanRunningScreen> {
  CameraController? _controller;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.isNotEmpty ? cameras.first : throw Exception('No cameras'),
      );
      final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _controller = ctrl);
    } catch (e) {
      setState(() => _initFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller?.value.isInitialized ?? false;
    final previewSize = isReady ? _controller!.value.previewSize : null;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: 'Living Room'.text.make(),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Room 1 of 5',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera live preview - hard-cover using ClipRect + OverflowBox + FittedBox
          Positioned.fill(
            child: isReady
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final fallback = Size(constraints.maxWidth, constraints.maxHeight);
                      final previewSize = _controller!.value.previewSize ?? fallback;
                      final aspect = _controller!.value.aspectRatio; // width / height
                      return ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.center,
                          minWidth: 0,
                          minHeight: 0,
                          maxWidth: double.infinity,
                          maxHeight: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: previewSize.width,
                              height: previewSize.height,
                              child: AspectRatio(
                                aspectRatio: aspect,
                                child: CameraPreview(_controller!),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: _initFailed
                        ? 'Camera failed to start'.text.white.make()
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
          ),

          // Tip banner over image
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2F80ED)),
                    ),
                    child: const Icon(Icons.bolt_outlined, size: 16, color: Color(0xFF2F80ED)),
                  ),
                  12.widthBox,
                  'Move Slowly Around The Room.'
                      .text
                      .color(AppColors.navy)
                      .semiBold
                      .make(),
                ],
              )
                  .p16()
                  .box
                  .color(const Color(0xFFEAF2FF))
                  .border(color: const Color(0xFFBFD7FF))
                  .roundedLg
                  .shadowSm
                  .make(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'End scan early',
                    bgColor: Colors.white,
                    fgColor: AppColors.navy,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: false,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (ctx) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'End scan early',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua Egestas purus',
                                  style: TextStyle(height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 52,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navy,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Continue Scanning', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 52,
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      context.push('/scan/review?quality=fair');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('End Anyway', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Done',
                    onPressed: () async {
                      if (_controller?.value.isInitialized ?? false) {
                        try {
                          final file = await _controller!.takePicture();
                          if (!mounted) return;
                          context.push('/scan/review?quality=excellent', extra: {'imagePath': file.path});
                        } catch (_) {
                          if (!mounted) return;
                          context.push('/scan/review?quality=excellent');
                        }
                      } else {
                        context.push('/scan/review?quality=excellent');
                      }
                    },
                    bgColor: AppColors.navy,
                    fgColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
