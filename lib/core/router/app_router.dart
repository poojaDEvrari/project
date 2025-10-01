import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/scan/scan_tips_screen.dart';
import '../../features/scan/scan_running_screen.dart';
import '../../features/scan/scan_processing_screen.dart';
import '../../features/scan/scan_review_screen.dart';
import '../../features/rooms/room_selection_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (BuildContext context, GoRouterState state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/scan/tips',
      name: 'scan_tips',
      builder: (BuildContext context, GoRouterState state) => const ScanTipsScreen(),
    ),
    GoRoute(
      path: '/scan/running',
      name: 'scan_running',
      builder: (BuildContext context, GoRouterState state) => const ScanRunningScreen(),
    ),
    GoRoute(
      path: '/scan/processing',
      name: 'scan_processing',
      builder: (BuildContext context, GoRouterState state) => const ScanProcessingScreen(),
    ),
    GoRoute(
      path: '/scan/review',
      name: 'scan_review',
      builder: (BuildContext context, GoRouterState state) {
        final q = state.uri.queryParameters['quality']?.toLowerCase();
        final quality = (q == 'poor')
            ? ScanQuality.poor
            : (q == 'fair')
                ? ScanQuality.fair
                : ScanQuality.excellent;
        return ScanReviewScreen(quality: quality);
      },
    ),
    GoRoute(
      path: '/rooms/select',
      name: 'room_selection',
      builder: (BuildContext context, GoRouterState state) => const RoomSelectionScreen(),
    ),
  ],
);
