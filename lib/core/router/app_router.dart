import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/scan/scan_tips_screen.dart';
import '../../features/scan/scan_running_screen.dart';
import '../../features/scan/scan_processing_screen.dart';
import '../../features/scan/scan_review_screen.dart';
import '../../features/scan/room_saved_screen.dart';
import '../../features/rooms/room_selection_screen.dart';
import '../../features/rooms/scanned_rooms_screen.dart';
import '../../features/rooms/add_item_screen.dart';
import '../../features/rooms/room_details_screen.dart';
import '../../features/settings/settings_screen.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) {
        final total = int.tryParse(state.uri.queryParameters['total'] ?? '5') ?? 5;
        final room = state.uri.queryParameters['room'];
        final index = int.tryParse(state.uri.queryParameters['index'] ?? '1') ?? 1;
        return ScanScreen(totalRooms: total, initialRoomName: room, initialIndex: index);
      },
    ),
    GoRoute(
      path: '/scan/tips',
      name: 'scan_tips',
      builder: (context, state) {
        final total = int.tryParse(state.uri.queryParameters['total'] ?? '5') ?? 5;
        final room = state.uri.queryParameters['room'] ?? 'Living Room';
        final index = int.tryParse(state.uri.queryParameters['index'] ?? '1') ?? 1;
        return ScanTipsScreen(totalRooms: total, roomName: room, index: index);
      },
    ),
    GoRoute(
      path: '/scan/running',
      name: 'scan_running',
      builder: (context, state) {
        final room = state.uri.queryParameters['room'] ?? 'Living Room';
        final index = int.tryParse(state.uri.queryParameters['index'] ?? '1') ?? 1;
        final total = int.tryParse(state.uri.queryParameters['total'] ?? '5') ?? 5;
        return ScanRunningScreen(
          roomName: room,
          currentRoomIndex: index,
          totalRooms: total,
        );
      },
    ),
    GoRoute(
      path: '/scan/processing',
      name: 'scan_processing',
      builder: (context, state) => const ScanProcessingScreen(),
    ),
    GoRoute(
      path: '/scan/review',
      name: 'scan_review',
      builder: (context, state) {
        final q = state.uri.queryParameters['quality']?.toLowerCase();
        final quality = (q == 'poor')
            ? ScanQuality.poor
            : (q == 'fair')
                ? ScanQuality.fair
                : ScanQuality.excellent;
        final idx = int.tryParse(state.uri.queryParameters['index'] ?? '1') ?? 1;
        final total = int.tryParse(state.uri.queryParameters['total'] ?? '1') ?? 1;
        final room = state.uri.queryParameters['room'] ?? 'Living Room';
        final imagePath = state.extra is Map ? (state.extra as Map)['imagePath'] as String? : null;
        return ScanReviewScreen(
          quality: quality,
          currentIndex: idx,
          totalRooms: total,
          roomName: room,
          imagePath: imagePath,
        );
      },
    ),
    GoRoute(
      path: '/scan/saved',
      name: 'room_saved',
      builder: (context, state) {
        final idx = int.tryParse(state.uri.queryParameters['index'] ?? '2') ?? 2;
        final total = int.tryParse(state.uri.queryParameters['total'] ?? '5') ?? 5;
        final room = state.uri.queryParameters['room'] ?? 'Living Room';
        final imagePath = state.extra is Map ? (state.extra as Map)['imagePath'] as String? : null;
        return RoomSavedScreen(currentIndex: idx, totalRooms: total, roomName: room, imagePath: imagePath);
      },
    ),
    GoRoute(
      path: '/rooms/select',
      name: 'room_selection',
      builder: (context, state) => RoomSelectionScreen(),
    ),
    GoRoute(
      path: '/rooms/scanned',
      name: 'rooms_scanned',
      builder: (context, state) {
        final total = int.tryParse(state.uri.queryParameters['total'] ?? '5') ?? 5;
        return ScannedRoomsScreen(totalRooms: total);
      },
    ),
    GoRoute(
      path: '/rooms/add',
      name: 'rooms_add',
      builder: (context, state) {
        final room = state.uri.queryParameters['room'] ?? 'Room 1';
        return AddItemScreen(roomName: room);
      },
    ),
    GoRoute(
      path: '/room-details',
      name: 'room_details',
      builder: (context, state) {
        final room = state.uri.queryParameters['room'] ?? 'Living Room';
        return RoomDetailsScreen(roomName: room);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ), 
  ],
);
