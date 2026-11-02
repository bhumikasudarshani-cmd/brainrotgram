import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/studio/studio_screen.dart';
import '../features/sessions/sessions_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/signin/signin_screen.dart';
import '../shared/widgets/app_shell.dart';

// Navigator keys for each shell branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final _studioNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'studio');
final _sessionsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'sessions');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Router provider — depends on auth state for the redirect guard.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,

    // --- Auth redirect guard ---
    // While signed out, only /signin is reachable.
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isSigningIn = state.matchedLocation == '/signin';
      final isLoading = authState.status == AuthStatus.unknown;

      // Still checking stored tokens — don't redirect yet
      if (isLoading) return null;

      // Not authenticated → force to sign-in
      if (!isAuthenticated && !isSigningIn) return '/signin';

      // Authenticated but on sign-in page → go to home
      if (isAuthenticated && isSigningIn) return '/home';

      return null;
    },

    routes: [
      // Sign-in gate
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),

      // Main app with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            navigationShell: navigationShell,
            child: navigationShell,
          );
        },
        branches: [
          // Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          // Search
          StatefulShellBranch(
            navigatorKey: _searchNavigatorKey,
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SearchScreen(),
                ),
              ),
            ],
          ),
          // Studio (+)
          StatefulShellBranch(
            navigatorKey: _studioNavigatorKey,
            routes: [
              GoRoute(
                path: '/studio',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StudioScreen(),
                ),
              ),
            ],
          ),
          // Sessions
          StatefulShellBranch(
            navigatorKey: _sessionsNavigatorKey,
            routes: [
              GoRoute(
                path: '/sessions',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SessionsScreen(),
                ),
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
