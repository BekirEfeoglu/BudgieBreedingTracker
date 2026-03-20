part of 'auth_actions.dart';

/// OAuth sign-in methods for [AuthActions].
mixin _AuthOAuthMixin {
  SupabaseClient get _client;

  bool _isGoogleInitialized = false;

  /// Sign in with OAuth provider (Google, Apple, etc.).
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    final isIos = Platform.isIOS;
    if (isIos) {
      await _suspendIosWindowReclaim();
    }

    try {
      final launched = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: AuthActions._oAuthRedirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched && isIos) {
        await _resumeIosWindowReclaim();
      }
      return launched;
    } catch (_) {
      if (isIos) {
        await _resumeIosWindowReclaim();
      }
      rethrow;
    }
  }

  /// Sign in with Google natively.
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final webClientId = AppConstants.googleWebClientId;
      final iosClientId = AppConstants.googleIosClientId;

      if (webClientId.isEmpty && iosClientId.isEmpty) {
        throw const AuthException(
          'Google sign-in not configured',
          statusCode: '400',
        );
      }

      if (!_isGoogleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: Platform.isIOS
              ? (iosClientId.isEmpty ? null : iosClientId)
              : null,
          serverClientId: webClientId.isEmpty ? null : webClientId,
        );
        _isGoogleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found for Google Sign In.');
      }

      // In google_sign_in 7.0+, you obtain access tokens via authorizationClient if needed.
      // Supabase signInWithIdToken only strongly requires idToken for Google.
      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient
            .authorizationForScopes([]);
        accessToken = authz?.accessToken;
      } catch (_) {
        // ignore authorization fetch error
      }

      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Canceled');
      }
      if (e is PlatformException && e.code == 'sign_in_canceled') {
        throw const AuthException('Canceled');
      }
      AppLogger.error('[AuthActions] Google sign-in failed: $e');
      throw AuthException('Google sign-in failed: $e', statusCode: '400');
    }
  }

  /// Sign in with Apple natively.
  Future<AuthResponse> signInWithApple() async {
    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('No ID Token found for Apple Sign In.');
      }

      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Canceled');
      }
      AppLogger.error('[AuthActions] Apple sign-in failed: $e');
      throw AuthException('Apple sign-in failed: $e', statusCode: '400');
    }
  }

  /// Revoke OAuth provider token (Google/Apple) via Edge Function.
  ///
  /// Best-effort: if provider token is not available in the current session
  /// (e.g., after app restart), this silently skips revocation.
  Future<void> revokeOAuthToken() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    final providerToken = session.providerToken;
    final providerRefreshToken = session.providerRefreshToken;
    if (providerToken == null && providerRefreshToken == null) return;

    // Determine provider from user identities
    final user = _client.auth.currentUser;
    final provider = user?.appMetadata['provider'] as String?;
    if (provider != 'google' && provider != 'apple') return;

    try {
      await _client.functions.invoke(
        'revoke-oauth-token',
        body: {
          'provider': provider,
          if (providerToken != null) 'provider_token': providerToken,
          if (providerRefreshToken != null)
            'provider_refresh_token': providerRefreshToken,
        },
      );
      AppLogger.info('[AuthActions] OAuth token revoked for $provider');
    } catch (e) {
      AppLogger.warning('[AuthActions] OAuth token revocation failed: $e');
    }
  }

  Future<void> _suspendIosWindowReclaim() async {
    try {
      await AuthActions._iosWindowGuardChannel.invokeMethod<void>(
        'suspendWindowReclaim',
        {'seconds': AuthActions._iosWindowGuardSuspendDuration.inSeconds},
      );
    } catch (_) {
      // Channel may be unavailable during startup; keep OAuth flow best-effort.
    }
  }

  Future<void> _resumeIosWindowReclaim() async {
    try {
      await AuthActions._iosWindowGuardChannel.invokeMethod<void>(
        'resumeWindowReclaim',
      );
    } catch (_) {
      // Ignore channel errors; guard will auto-resume after timeout.
    }
  }
}
