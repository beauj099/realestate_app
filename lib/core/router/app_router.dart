import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/property_overview/presentation/screens/address_screen.dart';
import '../../features/property_overview/presentation/screens/building_info_screen.dart';
import '../../features/property_overview/presentation/screens/expenses_screen.dart';
import '../../features/property_overview/presentation/screens/owner_details_screen.dart';
import '../../features/property_overview/presentation/screens/property_features_screen.dart';
import '../../features/property_overview/presentation/screens/property_overview_screen.dart';
import '../../features/property_overview/presentation/screens/property_type_screen.dart';
import '../../features/property_overview/presentation/screens/room_details_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../constants/route_constants.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.loginPath,
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isInitialized = authState.status != AuthStatus.uninitialized;
      final isLoginRoute = state.matchedLocation == AppRoutes.loginPath;
      final isRegisterRoute = state.matchedLocation == AppRoutes.registerPath;

      if (!isInitialized) return null;

      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        return AppRoutes.loginPath;
      }
      if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
        return AppRoutes.homePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPath,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homePath,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settingsPath,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.propertyPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PropertyOverviewScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.propertyTypePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PropertyTypeScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.buildingInfoPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BuildingInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.propertyFeaturesPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PropertyFeaturesScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomDetailsPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomDetailsScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: AppRoutes.expensesPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: AppRoutes.valuationCostsPath,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) {
          final id = state.pathParameters['id']!;
          return AppRoutes.expenses(int.parse(id));
        },
      ),
      GoRoute(
        path: AppRoutes.ownerDetailsPath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OwnerDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.contactsPath,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) {
          final id = state.pathParameters['id']!;
          return AppRoutes.ownerDetails(int.parse(id));
        },
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
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.5),
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
