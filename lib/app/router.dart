import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../core/api/access_api.dart';
import '../core/api/api_client.dart';
import '../core/api/auth_api.dart';
import '../core/api/devices_api.dart';
import '../core/api/profile_api.dart';
import '../core/api/subscription_api.dart';
import '../core/storage/token_storage.dart';
import '../features/access/application/connection_controller.dart';
import '../core/session/session_controller.dart';
import '../features/access/presentation/connection_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/legal/presentation/privacy_policy_screen.dart';
import '../features/legal/presentation/refund_policy_screen.dart';
import '../features/legal/presentation/user_agreement_screen.dart';
import '../features/logs/presentation/connection_log_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/subscription/presentation/subscription_screen.dart';
import 'app_shell.dart';

final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
final TokenStorage _tokenStorage = TokenStorage(_secureStorage);
final ApiClient _apiClient = ApiClient(_tokenStorage);

final AuthApi _authApi = AuthApi(
  apiClient: _apiClient,
  tokenStorage: _tokenStorage,
);
final ProfileApi _profileApi = ProfileApi(_apiClient);
final AccessApi _accessApi = AccessApi(_apiClient);
final DevicesApi _devicesApi = DevicesApi(_apiClient);
final SubscriptionApi _subscriptionApi = SubscriptionApi(_apiClient);

final SessionController sessionController = SessionController(
  tokenStorage: _tokenStorage,
  profileApi: _profileApi,
  authApi: _authApi,
);

final ConnectionController connectionController = ConnectionController(
  accessApi: _accessApi,
);

final GoRouter appRouter = GoRouter(
  refreshListenable: sessionController,
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) {
    final SessionStatus status = sessionController.status;
    final String location = state.matchedLocation;

    final bool isLogin = location == '/login';
    final bool isSplash = location == '/splash';
    final bool isPublicLegal = location.startsWith('/legal/');

    if (status == SessionStatus.unknown) {
      return isSplash || isPublicLegal ? null : '/splash';
    }

    if (status == SessionStatus.unauthenticated) {
      return isLogin || isPublicLegal ? null : '/login';
    }

    if (status == SessionStatus.authenticated) {
      return (isLogin || isSplash) ? '/home' : null;
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return const _SplashScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return LoginScreen(
          authApi: _authApi,
          sessionController: sessionController,
        );
      },
    ),
    GoRoute(
      path: '/legal/user-agreement',
      builder: (BuildContext context, GoRouterState state) {
        return const UserAgreementScreen();
      },
    ),
    GoRoute(
      path: '/legal/privacy',
      builder: (BuildContext context, GoRouterState state) {
        return const PrivacyPolicyScreen();
      },
    ),
    GoRoute(
      path: '/legal/refund',
      builder: (BuildContext context, GoRouterState state) {
        return const RefundPolicyScreen();
      },
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppShell(navigationShell: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return HomeScreen(
              sessionController: sessionController,
              connectionController: connectionController,
            );
          },
        ),
        GoRoute(
          path: '/access',
          builder: (BuildContext context, GoRouterState state) {
            return ConnectionScreen(connectionController: connectionController);
          },
        ),
        GoRoute(
          path: '/logs',
          builder: (BuildContext context, GoRouterState state) {
            return ConnectionLogScreen(
              connectionController: connectionController,
            );
          },
        ),
        GoRoute(
          path: '/devices',
          builder: (BuildContext context, GoRouterState state) {
            return DevicesScreen(
              devicesApi: _devicesApi,
              sessionController: sessionController,
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return ProfileScreen(sessionController: sessionController);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (BuildContext context, GoRouterState state) {
            return SettingsScreen(sessionController: sessionController);
          },
        ),
        GoRoute(
          path: '/subscription',
          builder: (BuildContext context, GoRouterState state) {
            return SubscriptionScreen(subscriptionApi: _subscriptionApi);
          },
        ),
      ],
    ),
  ],
);

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset('assets/images/logo.png', height: 160),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Загрузка...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
