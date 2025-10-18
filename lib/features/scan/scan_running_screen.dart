import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../core/services/s3_presigner.dart';
import '../../core/config/aws_config.dart';
import '../auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/primary_button.dart';

class ScanRunningScreen extends StatefulWidget {
  final String roomName;
  final String roomType;
  final int currentRoomIndex;
  final int totalRooms;
  final String? projectId;
  final String? subProjectId;

  const ScanRunningScreen({
    super.key,
    this.roomName = 'Living Room',
    this.roomType = 'bedroom',
    this.currentRoomIndex = 1,
    required this.totalRooms,
    this.projectId,
    this.subProjectId,
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
  XFile? _recordedVideo;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  static const int _maxRecordingSeconds = 30;
  bool _isProcessing = false;
  String? _uploadedS3Url;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startScanning();
  }

  // Ensures we have at least a short recorded clip. If none is present, it
  // starts recording for [minDuration], stops, and assigns to _recordedVideo.
  Future<void> _ensureVideoFile({Duration minDuration = const Duration(seconds: 2)}) async {
    if (_recordedVideo != null) {
      debugPrint('ℹ️  [RECORD] _ensureVideoFile: already have file=${_recordedVideo!.path}');
      return;
    }
    debugPrint('🧪 [RECORD] _ensureVideoFile: capturing short clip...');
    final started = await ensureRecordingStarted(timeout: const Duration(seconds: 2));
    if (!started) {
      debugPrint('⛔ [RECORD] Could not start recording for fallback');
      return;
    }
    await Future.delayed(minDuration);
    final file = await _stopRecordingIfAny();
    if (file != null) {
      _recordedVideo = file;
      try {
        final size = await File(file.path).length();
        debugPrint('✅ [RECORD] Fallback captured file=${file.path} size=${size}B');
      } catch (_) {}
    } else {
      debugPrint('❌ [RECORD] Fallback stop returned null');
    }
  }
  
  @override
  void dispose() {
    _scanTimer?.cancel();
    _recordingTimer?.cancel();
    _stopRecordingIfAny().then((_) => _controller?.dispose());
    super.dispose();
  }
  
  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _recordingSeconds = 0;
    });
    
    // Start recording first, then begin progress simulation
    _startRecordingIfPossible().then((_) {
      // Simulate scanning progress
      _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted) return;
        
        setState(() {
          _scanProgress += 0.01;
          if (_scanProgress >= 1.0) {
            _scanProgress = 1.0;
            timer.cancel();
          }
        });
      });
      
      // Start recording duration timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        
        setState(() {
          _recordingSeconds++;
          
          // Auto-stop at 30 seconds
          if (_recordingSeconds >= _maxRecordingSeconds) {
            timer.cancel();
            _scanTimer?.cancel();
            _handleRecordingComplete();
          }
        });
      });
    });
  }
  
  Future<void> _handleRecordingComplete() async {
    if (_isProcessing) return;
    
    debugPrint('🎥 [RECORD] Handle complete: isRecording=$_isRecording, ctrl.isRecording=${_controller?.value.isRecordingVideo}');
    
    setState(() => _isProcessing = true);
    
    final video = await _stopRecordingIfAny();
    debugPrint('🎥 [RECORD] stopRecording -> ${video?.path ?? 'null'}');
    
    if (video != null && mounted) {
      _recordedVideo = video;
      try {
        final size = await File(video.path).length();
        debugPrint('💾 [FILE] Saved video path=${video.path}, size=${size}B');
      } catch (_) {}
    } else {
      debugPrint('❗ [RECORD] Video is null after stopping recording');
    }
    
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
  
  Future<void> _uploadVideoAndNavigate(String quality) async {
    if (_recordedVideo == null) {
      // If no video yet, stop recording first
      final video = await _stopRecordingIfAny();
      if (video != null) {
        _recordedVideo = video;
      }
    }
    
    if (_recordedVideo == null) {
      debugPrint('⚠️  [FLOW] No video yet. Trying fallback to capture short clip...');
      await _ensureVideoFile();
      if (_recordedVideo == null) {
        _showErrorDialog('No video recorded. Please ensure camera permissions are granted.');
        return;
      }
    }
    
    setState(() => _isProcessing = true);
    
    try {
      // Step 1: Upload video to S3 (kept as-is; ensure your presign endpoint works)
      debugPrint('☁️ [UPLOAD] Begin S3 upload...');
      final s3Url = await _uploadVideoToS3(_recordedVideo!);
      
      if (s3Url == null) {
        debugPrint('❌ [UPLOAD] Failed to upload to S3');
        _showErrorDialog('Failed to upload video to S3. Please try again.');
        return;
      }
      
      _uploadedS3Url = s3Url;
      debugPrint('✅ [UPLOAD] S3 URL: $s3Url');
      
      // Step 2: Create sub-project for this room
      Map<String, dynamic>? subProject;
      if (widget.projectId != null && widget.projectId!.isNotEmpty) {
        debugPrint('🗂️ [SUBPROJECT] Creating for projectId=${widget.projectId}, roomName=${widget.roomName}');
        subProject = await _createSubProject(
          projectId: widget.projectId!,
          roomName: widget.roomName,
          s3Url: s3Url,
        );
        if (subProject != null) {
          final sid = (subProject['sub_project'] is Map) ? (subProject['sub_project']['id']?.toString()) : null;
          debugPrint('✅ [SUBPROJECT] Created sub_project_id=${sid ?? 'unknown'}');
        } else {
          debugPrint('⚠️ [SUBPROJECT] Creation returned null');
        }
      }

      // Step 3: Process LiDAR pipeline using the new API
      debugPrint('🛰️ [LIDAR] Processing start for s3Url');
      final subProjectId = (subProject != null && subProject['sub_project'] is Map)
          ? (subProject['sub_project']['id']?.toString())
          : null;
      final response = await _processLiDARFromS3(
        s3Url,
        projectId: widget.projectId,
        subProjectId: subProjectId,
        processingMode: 'full_pipeline',
        maxFrames: 30,
      );
      
      if (!mounted) return;
      
      if (response != null) {
        // Success - navigate with API response
        debugPrint('✅ [LIDAR] Processing success, navigating to review');
        context.go(
          '/scan/review?quality=$quality&index=${widget.currentRoomIndex}&total=${widget.totalRooms}&room=${Uri.encodeComponent(widget.roomName)}',
          extra: {
            'videoPath': _recordedVideo!.path,
            's3Url': s3Url,
            'apiResponse': response,
            if (subProject != null) 'subProject': subProject,
          },
        );
      } else {
        debugPrint('❌ [LIDAR] Processing failed');
        _showErrorDialog('Failed to process scan. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('💥 [FLOW] Error: $e');
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        debugPrint('🧹 [FLOW] Done (isProcessing=false)');
      }
    }
  }
  
  // 1) Get token (adapt to your auth storage)
  Future<String?> _getAccessToken() async {
    // Use the existing AuthService to read the JWT stored under key 'jwt'
    final auth = AuthService();
    return await auth.getToken();
  }

  // 2) Request a presigned URL from your backend
  Future<Map<String, String>?> _getPresignedUrl({
    required String fileName,
    required String contentType,
    String? projectId,
    String? subProjectId,
  }) async {
    final token = await _getAccessToken();
    // Try a sequence of possible endpoints since server 404 shows no 'storage/' prefix
    final candidateEndpoints = <String>[
      'http://98.86.182.22/projects/presign-upload/',
      'http://98.86.182.22/detections/presign-upload/',
      'http://98.86.182.22/storage/presign-upload/', // legacy guess
    ];

    // Construct S3 key similar to the web code: project-videos/<timestamp>-<original name>
    final s3Key = 'project-videos/${DateTime.now().millisecondsSinceEpoch}-$fileName';

    final body = {
      'file_name': fileName,
      'content_type': contentType,
      's3_key': s3Key,
      if (projectId != null) 'project_id': projectId,
      if (subProjectId != null) 'sub_project_id': subProjectId,
    };

    for (final url in candidateEndpoints) {
      final uri = Uri.parse(url);
      debugPrint('📝 [PRESIGN] Request -> url=$uri body=${json.encode(body)}');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        final map = json.decode(res.body) as Map<String, dynamic>;
        debugPrint('✅ [PRESIGN] 200 OK from $url, keys=${map.keys.toList()}');
        return {
          'uploadUrl': map['uploadUrl'] as String,
          's3Url': map['s3Url'] as String,
        };
      }
      debugPrint('❌ [PRESIGN] ${res.statusCode} at $url');
      if (res.statusCode != 404) {
        // Non-404 errors shouldn't try other endpoints
        debugPrint('❌ [PRESIGN] Error body: ${res.body}');
        return null;
      }
    }
    debugPrint('❌ [PRESIGN] All candidate endpoints returned 404');
    // Local presign fallback (mirrors website UploadModel pattern)
    if (awsBucket.isNotEmpty && awsRegion.isNotEmpty && awsAccessKeyId.isNotEmpty && awsSecretAccessKey.isNotEmpty) {
      try {
        final uploadUrl = S3Presigner.presignPutUrl(
          bucket: awsBucket,
          region: awsRegion,
          key: s3Key,
          contentType: contentType,
        );
        final s3Url = 'https://$awsBucket.s3.$awsRegion.amazonaws.com/$s3Key';
        debugPrint('🔐 [PRESIGN-LOCAL] Generated PUT URL');
        return {
          'uploadUrl': uploadUrl,
          's3Url': s3Url,
        };
      } catch (e) {
        debugPrint('💥 [PRESIGN-LOCAL] Error: $e');
      }
    } else {
      debugPrint('⚠️  [PRESIGN-LOCAL] AWS config is empty. Fill lib/core/config/aws_config.dart');
    }
    return null;
  }

  // 3) PUT the file to presigned URL (no auth header, just content-type)
  Future<bool> _putToPresignedUrl({
    required String uploadUrl,
    required XFile video,
    required String contentType,
  }) async {
    final bytes = await File(video.path).readAsBytes();
    final uri = Uri.parse(uploadUrl);
    final signedHeaders = uri.queryParameters['X-Amz-SignedHeaders'] ?? uri.queryParameters['x-amz-signedheaders'] ?? '';
    final req = http.Request('PUT', uri)
      ..bodyBytes = bytes;
    if (signedHeaders.toLowerCase().split(';').contains('content-type')) {
      req.headers['Content-Type'] = contentType;
    }
    debugPrint('⬆️  [PUT] Upload to presignedUrl=${uploadUrl} contentType=${contentType} bytes=${bytes.length}');
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final ok = res.statusCode == 200;
    if (!ok) {
      debugPrint('❌ [PUT] Failed ${res.statusCode} ${res.body}');
    } else {
      debugPrint('✅ [PUT] Success 200');
    }
    return ok;
  }

  // 4) Your upload entry: mirrors web: get presign -> PUT -> return s3Url
  Future<String?> _uploadVideoToS3(XFile video) async {
    try {
      final fileName = path.basename(video.path);
      debugPrint('☁️ [UPLOAD] Preparing presign for file=$fileName');
      final ext = path.extension(fileName).toLowerCase();
      String contentType;
      switch (ext) {
        case '.mp4':
          contentType = 'video/mp4';
          break;
        case '.mov':
          contentType = 'video/quicktime';
          break;
        case '.m4v':
          contentType = 'video/x-m4v';
          break;
        default:
          contentType = 'application/octet-stream';
      }
      final presign = await _getPresignedUrl(
        fileName: fileName,
        contentType: contentType,
        projectId: widget.projectId,
        subProjectId: widget.subProjectId,
      );
      if (presign == null) return null;

      final ok = await _putToPresignedUrl(
        uploadUrl: presign['uploadUrl']!,
        video: video,
        contentType: contentType,
      );
      if (!ok) return null;

      debugPrint('☁️ [UPLOAD] Completed, s3Url=${presign['s3Url']}');
      return presign['s3Url'];
    } catch (e) {
      debugPrint('💥 [UPLOAD] S3 error: $e');
      return null;
    }
  }
  
  /// Create sub-project with project_id, room_name, s3_bucket_url
  Future<Map<String, dynamic>?> _createSubProject({
    required String projectId,
    required String roomName,
    required String s3Url,
  }) async {
    try {
      final token = await _getAccessToken();
      final uri = Uri.parse('http://98.86.182.22/detections/sub-projects/create/');
      final requestBody = {
        'project_id': projectId,
        'room_name': roomName,
        's3_bucket_url': s3Url,
      };
      debugPrint('🗂️ [SUBPROJECT] POST ${uri.toString()} body=${json.encode(requestBody)}');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [SUBPROJECT] ${response.statusCode} ${json.encode(jsonResponse)}');
        return jsonResponse;
      }
      debugPrint('❌ [SUBPROJECT] Error ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('💥 [SUBPROJECT] Exception: $e');
      return null;
    }
  }

  /// Step: Process LiDAR using the new API
  Future<Map<String, dynamic>?> _processLiDARFromS3(
    String s3Url, {
    String? projectId,
    String? subProjectId,
    String processingMode = 'full_pipeline',
    int maxFrames = 30,
  }) async {
    try {
      final token = await _getAccessToken();
      final uri = Uri.parse('http://98.86.182.22/lidar/process-video/');

      final requestBody = <String, dynamic>{
        's3_bucket_url': s3Url,
        'max_frames': maxFrames,
        'processing_mode': processingMode,
        if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
        if (subProjectId != null && subProjectId.isNotEmpty) 'sub_project_id': subProjectId,
      };

      debugPrint('🛰️ [LIDAR] POST ${uri.toString()} body=${json.encode(requestBody)}');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [LIDAR] 200 OK: ${json.encode(jsonResponse)}');
        return jsonResponse;
      }
      debugPrint('❌ [LIDAR] Error ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('💥 [LIDAR] Exception: $e');
      return null;
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _restartScan() async {
    // Stop any ongoing scan progress
    _scanTimer?.cancel();
    _recordingTimer?.cancel();
    setState(() {
      _isScanning = false;
      _scanProgress = 0.0;
      _recordingSeconds = 0;
      _recordedVideo = null;
      _uploadedS3Url = null;
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
      debugPrint('📷 [CAMERA] Querying available cameras...');
      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.isNotEmpty ? cameras.first : (throw Exception('No cameras')),
      );
      debugPrint('📷 [CAMERA] Using camera: ${cam.name} (${cam.lensDirection})');
      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      debugPrint('📷 [CAMERA] Initializing controller...');
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _controller = ctrl);
      debugPrint('✅ [CAMERA] Initialized (isInitialized=${ctrl.value.isInitialized})');
    } catch (e) {
      if (!mounted) return;
      setState(() => _initFailed = true);
      debugPrint('💥 [CAMERA] Init error: $e');
    }
  }

  Future<void> _startRecordingIfPossible() async {
    try {
      final ctrl = _controller;
      if (ctrl == null) {
        debugPrint('⏳ [RECORD] Controller is null, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
        return _startRecordingIfPossible();
      }
      if (!ctrl.value.isInitialized) {
        debugPrint('⏳ [RECORD] Controller not initialized, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
        return _startRecordingIfPossible();
      }
      if (ctrl.value.isRecordingVideo) {
        debugPrint('ℹ️  [RECORD] Already recording');
        return;
      }
      debugPrint('▶️  [RECORD] startVideoRecording()');
      await ctrl.startVideoRecording();
      debugPrint('✅ [RECORD] Recording started successfully');
      if (!mounted) return;
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('💥 [RECORD] start error: $e');
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted && _controller?.value.isInitialized == true) {
        try {
          await _controller!.startVideoRecording();
          if (mounted) {
            setState(() => _isRecording = true);
          }
        } catch (e2) {
          debugPrint('💥 [RECORD] retry failed: $e2');
        }
      }
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
      });
      return file;
    } catch (e) {
      debugPrint('Recording stop error: $e');
      if (!mounted) return null;
      setState(() => _isRecording = false);
      return null;
    }
  }

  Future<bool> ensureRecordingStarted({Duration timeout = const Duration(seconds: 2)}) async {
    debugPrint('⏱️  [RECORD] ensureRecordingStarted(timeout=${timeout.inMilliseconds}ms)');
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (_isRecording || (_controller?.value.isRecordingVideo ?? false)) return true;
      await _startRecordingIfPossible();
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final result = _isRecording || (_controller?.value.isRecordingVideo ?? false);
    debugPrint(result
        ? '✅ [RECORD] ensureRecordingStarted -> recording'
        : '⛔ [RECORD] ensureRecordingStarted -> timed out');
    return result;
  }
  
  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final isReady = _controller?.value.isInitialized ?? false;
    debugPrint('🧱 [BUILD] ready=$isReady, isRecording=$_isRecording, progress=${(_scanProgress * 100).toStringAsFixed(0)}%');
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
          
          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _uploadedS3Url == null 
                          ? 'Uploading video...' 
                          : 'Processing scan...',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Recording duration indicator
          if (_isRecording)
            Positioned(
              top: totalTopPadding + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REC ${_formatDuration(_recordingSeconds)} / ${_formatDuration(_maxRecordingSeconds)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
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
          
          // Semi-transparent overlay for the top part
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: totalTopPadding + 10,
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

          // Tip banner
          Positioned(
            top: totalTopPadding + 16,
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
                    onPressed: _isProcessing 
                      ? () {} 
                      : () {
                      debugPrint('🛑 [UI] End scan early pressed');
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
                                      debugPrint('🔁 [UI] Restart Scan');
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
                                      debugPrint('🛑 [UI] End Anyway -> ensureRecordingStarted + complete + upload');
                                      ensureRecordingStarted().then((_) => _handleRecordingComplete())
                                        .then((_) { if (mounted) _uploadVideoAndNavigate('fair'); });
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
                    label: _isProcessing ? 'Processing...' : 'Done',
                    bgColor: AppColors.navy,
                    fgColor: Colors.white,
                    onPressed: _isProcessing 
                      ? () {}
                      : () async {
                          debugPrint('✅ [UI] Done pressed');
                          setState(() => _isProcessing = true);
                          await ensureRecordingStarted();
                          await _handleRecordingComplete();
                          if (mounted) await _uploadVideoAndNavigate('excellent');
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
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}