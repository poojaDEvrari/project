import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';

class LidarDetectionScreen extends StatefulWidget {
  const LidarDetectionScreen({super.key});

  @override
  State<LidarDetectionScreen> createState() => _LidarDetectionScreenState();
}

class _LidarDetectionScreenState extends State<LidarDetectionScreen> {
  bool? _hasLidar;
  bool _isLoading = true;
  String _deviceInfo = '';
  List<CameraDescription> _cameras = [];
  bool _nonLidarAssetAvailable = false;

  @override
  void initState() {
    super.initState();
    _detectLidar();
  }

  Future<void> _detectLidar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try loading optional non-LiDAR illustration from assets
      try {
        await rootBundle.load('assets/images/non_lidar_info.png');
        _nonLidarAssetAvailable = true;
      } catch (_) {
        _nonLidarAssetAvailable = false;
      }

      // List cameras for informational display
      _cameras = await availableCameras();
      final info = StringBuffer();
      info.writeln('Total cameras found: ${_cameras.length}\n');
      for (var i = 0; i < _cameras.length; i++) {
        final camera = _cameras[i];
        info.writeln('Camera ${i + 1}:');
        info.writeln('  Name: ${camera.name}');
        info.writeln('  Lens Direction: ${camera.lensDirection}');
        info.writeln('  Sensor Orientation: ${camera.sensorOrientation}°');
        info.writeln('');
      }

      // Heuristic device detection: iOS Pro devices/iPad Pro likely have LiDAR
      bool hasLiDAR = false;
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        final model = (ios.model ?? '').toLowerCase(); // e.g., iPhone, iPad
        final name = (ios.name ?? '').toLowerCase();
        final machine = (ios.utsname.machine ?? '').toLowerCase(); // e.g., iPhone17,1
        // Quick heuristics: any iPhone "Pro" generation (name often contains owner's name, so fallback to machine code generation)
        final likelyPro = name.contains('pro') || model.contains('ipad') && name.contains('pro');
        // Rough mapping: iPhone12,3+ (and iPad8,?) for Pro lines since 2020; here we only use a coarse threshold on machine prefix
        final isIphone = machine.startsWith('iphone');
        final isIpad = machine.startsWith('ipad');
        hasLiDAR = likelyPro || isIpad; // iPad Pro more likely; this is a best-effort heuristic
      } else if (Platform.isAndroid) {
        // Some Android flagships have ToF/LiDAR-like sensors, but not standard.
        // Treat as no LiDAR for now; scanning still works.
        hasLiDAR = false;
      } else {
        hasLiDAR = false;
      }

      setState(() {
        _hasLidar = hasLiDAR;
        _deviceInfo = info.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasLidar = false;
        _deviceInfo = 'Error detecting cameras: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiDAR Detection'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Detecting device sensors...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top status panel
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                    color: _hasLidar == true
                        ? Colors.white
                        : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (_hasLidar != true && _nonLidarAssetAvailable)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Image.asset(
                                'assets/images/non_lidar_info.png',
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Icon(
                              _hasLidar == true
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              size: 80,
                              color: _hasLidar == true
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          const SizedBox(height: 16),
                          Text(
                            _hasLidar == true
                                ? 'LiDar Detected'
                                : 'Your device does not include a LiDar sensor',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _hasLidar == true
                                ? 'You can proceed with high‑accuracy depth-enhanced scanning.'
                                : 'For best results, we recommend a quick calibration to improve measurement accuracy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade100,
                            ),
                          ),
                          if (_hasLidar != true) ...[
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_box, color: Colors.black),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Improves accuracy of room and object measurements.',
                                    style: TextStyle(color: Colors.grey.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_box, color: Colors.black),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Reduces errors in distance estimation.',
                                    style: TextStyle(color: Colors.grey.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Skipping calibration may reduce accuracy (up to ~5%).',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bottom primary CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_hasLidar == true) {
                          context.go('/projects');
                        } else {
                          context.go('/projects');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_hasLidar == true
                          ? 'Proceed to Projects'
                          : 'Proceed to Calibration'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
