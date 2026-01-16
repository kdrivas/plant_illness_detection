import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/detection/presentation/screens/detection_screen.dart';
import '../../features/sensors/presentation/screens/sensors_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../widgets/bottom_nav_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/detection',
            name: 'detection',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DetectionScreen(),
            ),
          ),
          GoRoute(
            path: '/sensors',
            name: 'sensors',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SensorsScreen(),
            ),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
