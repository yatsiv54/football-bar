import '../../features/home/presentation/home_page.dart';
import '../../features/menu/presentation/menu_page.dart';
import '../../features/menu/presentation/cart_page.dart';
import '../../features/reserve/presentation/reserve_table_page.dart';
import '../../features/reserve/presentation/reservation_qr_page.dart';
import '../../features/schedule/presentation/match_schedule_page.dart';
import '../../features/fan/presentation/fan_shoutboard_page.dart';
import '../../features/qr/presentation/my_qr_codes_page.dart';
import '../../features/challenges/presentation/challenges_page.dart';
import '../../features/info/presentation/bar_information_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/welcome/presentation/welcome.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(path: '/cart', builder: (context, state) => CartPage()),
    GoRoute(path: '/menu', builder: (context, state) => const MenuPage()),
    GoRoute(
      path: '/reserve',
      builder: (context, state) => const ReserveTablePage(),
    ),
    GoRoute(
      path: '/reserve/confirmation',
      builder: (context, state) {
        final qrData = state.extra as QrConfirmData?;
        if (qrData == null) {
          return const Scaffold(body: Center(child: Text('Missing QR data')));
        }
        return QrConfirmPage(data: qrData);
      },
    ),
    GoRoute(
      path: '/order/confirmation',
      builder: (context, state) {
        final qrData = state.extra as QrConfirmData?;
        if (qrData == null) {
          return const Scaffold(body: Center(child: Text('Missing QR data')));
        }
        return QrConfirmPage(data: qrData);
      },
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => const MatchSchedulePage(),
    ),
    GoRoute(
      path: '/fan',
      builder: (context, state) => const FanShoutboardPage(),
    ),
    GoRoute(
      path: '/qr-codes',
      builder: (context, state) => const MyQrCodesPage(),
    ),
    GoRoute(
      path: '/challenges',
      builder: (context, state) => const ChallengesPage(),
    ),
    GoRoute(
      path: '/info',
      builder: (context, state) => const BarInformationPage(),
    ),
  ],
);
