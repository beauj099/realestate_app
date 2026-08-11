import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/property_wizard/presentation/screens/property_type_screen.dart';
import '../../features/property_wizard/presentation/screens/address_screen.dart';
import '../../features/property_wizard/presentation/screens/building_info_screen.dart';
import '../../features/property_wizard/presentation/screens/property_features_screen.dart';
import '../../features/property_wizard/presentation/screens/room_details_screen.dart';
import '../../features/property_wizard/presentation/screens/listing_valuation_screen.dart';
import '../../features/property_wizard/presentation/screens/contacts_screen.dart';
import '../../features/property_wizard/presentation/screens/review_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isInitialized = authState.status != AuthStatus.uninitialized;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isInitialized) return null;

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/wizard/property-type',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PropertyTypeStep(),
      ),
      GoRoute(
        path: '/wizard/address',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddressStep(),
      ),
      GoRoute(
        path: '/wizard/building-info',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BuildingInfoStep(),
      ),
      GoRoute(
        path: '/wizard/property-features',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PropertyFeaturesStep(),
      ),
      GoRoute(
        path: '/wizard/room-details/:roomId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomDetailsStep(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/wizard/valuation-costs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ValuationCostsStep(),
      ),
      GoRoute(
        path: '/wizard/contacts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContactsStep(),
      ),
      GoRoute(
        path: '/wizard/review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReviewStep(),
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
