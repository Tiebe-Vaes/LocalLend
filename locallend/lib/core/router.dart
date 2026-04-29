import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/add_item/add_item_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/item_detail/booking_screen.dart';
import '../screens/item_detail/item_detail_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _Listenable(ref),
    redirect: (ctx, state) {
      final loggedIn = auth.value != null;
      final authRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !authRoute) return '/login';
      if (loggedIn && authRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/item/:id',
        builder: (_, s) =>
            ItemDetailScreen(itemId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'book',
            builder: (_, s) =>
                BookingScreen(itemId: s.pathParameters['id']!),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/favorites',
                builder: (_, _) => const FavoritesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/add', builder: (_, _) => const AddItemScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/dashboard',
                builder: (_, _) => const DashboardScreen()),
          ]),
        ],
      ),
    ],
  );
});

class _Listenable extends ChangeNotifier {
  _Listenable(Ref ref) {
    ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (_, _) => notifyListeners(),
    );
  }
}
