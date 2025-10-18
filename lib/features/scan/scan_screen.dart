import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../widgets/permission_banner.dart';
import '../../core/theme/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

class ScanScreen extends StatefulWidget {
  final int totalRooms;
  final String? initialRoomName;
  final int? initialIndex;
  final String? projectId;
  const ScanScreen({
    super.key,
    required this.totalRooms,
    this.initialRoomName,
    this.initialIndex,
    this.projectId,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  // Banner only shows when camera permission is NOT granted
  bool showPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Returning from Settings. Re-check and auto-advance if granted
      _checkPermissions(autoNavigate: true);
    }
  }

  Future<void> _checkPermissions({bool autoNavigate = false}) async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      // Show dialog after a brief delay to ensure it appears on top
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            showPermissionDialog = true;
          });
        }
      });
      if (mounted) setState(() => showPermissionDialog = false);
    }
    if (autoNavigate && status.isGranted) {
      if (mounted) {
        setState(() => showPermissionDialog = false);
        final room = widget.initialRoomName ?? 'Living Room';
        final idx = widget.initialIndex ?? 1;
        final project = widget.projectId;
        final projectQP = (project != null && project.isNotEmpty)
            ? '&project=${Uri.encodeComponent(project)}'
            : '';
        context.push('/scan/tips?total=${widget.totalRooms}&room=${Uri.encodeComponent(room)}&index=$idx$projectQP');
      }
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        showPermissionDialog = false;
      });
      if (mounted) {
        final room = widget.initialRoomName ?? 'Living Room';
        final idx = widget.initialIndex ?? 1;
        final project = widget.projectId;
        final projectQP = (project != null && project.isNotEmpty)
            ? '&project=${Uri.encodeComponent(project)}'
            : '';
        context.push('/scan/tips?total=${widget.totalRooms}&room=${Uri.encodeComponent(room)}&index=$idx$projectQP');
      }
    }
  }

  void _openSettings() {
    openAppSettings();
    setState(() {
      showPermissionDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1d2e),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off_rounded,
                        size: 120,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Camera is off',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Start Scan Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Scan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Re-add the top banner after overlays so it stays visible (Option B)
          if (showPermissionDialog)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: PermissionBanner(
                    title: 'Camera Access',
                    message: 'Camera access is required to scan room. Please enable it in Settings.',
                    onOpenSettings: _openSettings,
                    onDismiss: () => setState(() => showPermissionDialog = false),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}