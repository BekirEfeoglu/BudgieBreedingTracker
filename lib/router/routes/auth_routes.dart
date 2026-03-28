import 'package:go_router/go_router.dart';

import '../../features/auth/screens/budgie_login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/auth_callback_screen.dart';
import '../route_names.dart';
import '../route_utils.dart';

/// Public authentication routes (login, register, etc.).
List<GoRoute> buildAuthRoutes() => [
  GoRoute(
    path: AppRoutes.login,
    builder: (context, state) => const BudgieLoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.register,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: AppRoutes.authCallback,
    builder: (context, state) => const AuthCallbackScreen(),
  ),
  GoRoute(
    path: AppRoutes.oauthCallback,
    builder: (context, state) => const AuthCallbackScreen(),
  ),
  GoRoute(
    path: AppRoutes.emailVerification,
    builder: (context, state) {
      final email = state.uri.queryParameters['email'];
      return EmailVerificationScreen(
        email: isValidRouteEmail(email) ? email : null,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
];
