import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';

class ScanRunningScreen extends StatefulWidget {
  final String roomName;
  final String roomType;
  final int currentRoomIndex;
  final int totalRooms;

  const ScanRunningScreen({
    super.key,
    this.roomName = 'Living Room',
    this.roomType = 'bedroom',
    this.currentRoomIndex = 1,
    required this.totalRooms,
  });

  @override
  State<ScanRunningScreen> createState() => _ScanRunningScreenState();
}

class _ScanRunningScreenState extends State<ScanRunningScreen> {
  CameraController? _controller;
  bool _initFailed = false;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  Timer? _scanTimer;
  bool _isRecording = false;
  String? _recordedVideoPath;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startScanning();
  }
  
  @override
  void dispose() {
    _scanTimer?.cancel();
    _stopRecordingIfAny().then((_) => _controller?.dispose());
    super.dispose();
  }
  
  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
    });
    
    // Simulate scanning progress
    _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      
      setState(() {
        _scanProgress += 0.01;
        if (_scanProgress >= 1.0) {
          _scanProgress = 1.0;
          _onScanComplete();
          timer.cancel();
        }
      });
    });
    _startRecordingIfPossible();
  }
  
  void _onScanComplete() {
    if (!mounted) return;
    final isLast = widget.currentRoomIndex >= widget.totalRooms;
    _stopRecordingIfAny().then((xfile) {
      if (!mounted) return;
      context.go(
        '/scan/review?quality=excellent&index=${widget.currentRoomIndex}&total=${widget.totalRooms}&room=${Uri.encodeComponent(widget.roomName)}',
        extra: xfile == null ? null : { 'videoPath': xfile.path },
      );
    });
  }

  Future<void> _restartScan() async {
    // Stop any ongoing scan progress
    _scanTimer?.cancel();
    setState(() {
      _isScanning = false;
      _scanProgress = 0.0;
    });
    // Stop recording, rebuild controller, then start again
    await _stopRecordingIfAny();
    final old = _controller;
    _controller = null;
    await old?.dispose();
    await _initCamera();
    // Start scanning again
    _startScanning();
  }
  
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.isNotEmpty ? cameras.first : (throw Exception('No cameras')),
      );
      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _controller = ctrl);
    } catch (e) {
      if (!mounted) return;
      setState(() => _initFailed = true);
    }
  }

  Future<void> _startRecordingIfPossible() async {
    try {
      final ctrl = _controller;
      if (ctrl == null) return;
      if (!ctrl.value.isInitialized) return;
      if (ctrl.value.isRecordingVideo) return;
      await ctrl.startVideoRecording();
      if (!mounted) return;
      setState(() => _isRecording = true);
    } catch (_) {
      // ignore
    }
  }

  Future<XFile?> _stopRecordingIfAny() async {
    try {
      final ctrl = _controller;
      if (ctrl == null) return null;
      if (!ctrl.value.isInitialized) return null;
      if (!ctrl.value.isRecordingVideo) return null;
      final file = await ctrl.stopVideoRecording();
      if (!mounted) return file;
      setState(() {
        _isRecording = false;
        _recordedVideoPath = file.path;
      });
      return file;
    } catch (_) {
      if (!mounted) return null;
      setState(() => _isRecording = false);
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isReady = _controller?.value.isInitialized ?? false;
    final previewSize = isReady ? _controller!.value.previewSize : null;
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final appBarHeight = kToolbarHeight;
    final totalTopPadding = statusBarHeight + appBarHeight;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _showCancelDialog(context),
        ),
        title: Text(
          widget.roomName,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              'Room ${widget.currentRoomIndex} of ${widget.totalRooms}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview taking full screen
          Positioned.fill(
            top: 0,
            child: isReady
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: _initFailed
                        ? 'Camera failed to start'.text.white.make()
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          
          // Scanning progress indicator
          if (_isScanning)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _scanProgress,
                backgroundColor: Colors.black26,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 4,
              ),
            ),
            
          // Scanning instructions overlay
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Slowly move your device around the room',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(_scanProgress * 100).toInt()}% complete',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Semi-transparent overlay for the top part to ensure header is readable
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: totalTopPadding + 10, // Add a little extra for the shadow
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Tip banner over image
          Positioned(
            top: totalTopPadding + 16, // Position below app bar with some padding
            left: 16,
            right: 16,
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
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: _isScanning
                  ? _buildScanningControls()
                  : _buildInitialControls(),
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
                    bgColor: AppColors.navy,
                    fgColor: Colors.white,
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
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      await _restartScan();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.navy,
                                      side: BorderSide(color: AppColors.navy.withOpacity(0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Restart Scan', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 52,
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _stopRecordingIfAny().then((file) {
                                        if (!mounted) return;
                                        context.go(
                                          '/scan/review?quality=fair&index=${widget.currentRoomIndex}&total=${widget.totalRooms}&room=${Uri.encodeComponent(widget.roomName)}',
                                          extra: file == null ? null : {
                                            'videoPath': file.path,
                                          },
                                        );
                                      });
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
                    bgColor: AppColors.navy,
                    fgColor: Colors.white,
                    onPressed: () async {
                      final index = widget.currentRoomIndex;
                      final total = widget.totalRooms;
                      final roomName = widget.roomName;
                      final file = await _stopRecordingIfAny();
                      if (!mounted) return;
                      context.go(
                        '/scan/review?quality=excellent&index=$index&total=$total&room=$roomName',
                        extra: file == null ? null : {
                          'videoPath': file.path,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.flash_on,
          onPressed: () {},
        ),
        _buildScanButton(
          onPressed: _startScanning,
          isScanning: false,
        ),
        _buildControlButton(
          icon: Icons.flip_camera_ios,
          onPressed: () {},
        ),
      ],
    );
  }
  
  Widget _buildScanningControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.pause,
          onPressed: () {
            // Pause scanning
            _scanTimer?.cancel();
            setState(() => _isScanning = false);
          },
        ),
        const SizedBox(width: 24),
        _buildControlButton(
          icon: Icons.check,
          backgroundColor: Colors.green,
          onPressed: () {
            // Complete scanning early
            _scanTimer?.cancel();
            _onScanComplete();
          },
        ),
      ],
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.black54,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildScanButton({VoidCallback? onPressed, bool isScanning = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isScanning ? Colors.red : Colors.transparent,
          border: Border.all(
            color: isScanning ? Colors.red : Colors.white,
            width: 3,
          ),
        ),
        child: Center(
          child: isScanning
              ? const Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: 32,
                )
              : const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }
  
  Future<void> _showCancelDialog(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Scanning'),
        content: const Text('Are you sure you want to cancel scanning this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (shouldCancel == true && mounted) {
      await _stopRecordingIfAny();
      Navigator.of(context).pop();
    }
  }
}