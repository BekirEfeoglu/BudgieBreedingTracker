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
        authScreenLaunchMode: resolveOAuthLaunchMode(
          isAndroid: Platform.isAndroid,
        ),
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

      if (!shouldUseNativeGoogleSignIn(isAndroid: Platform.isAndroid)) {
        throw const AuthException(
          nativeGoogleSignInFailedMessage,
          statusCode: '400',
        );
      }

      if (webClientId.isEmpty && iosClientId.isEmpty) {
        throw const AuthException(
          nativeGoogleSignInNotConfiguredMessage,
          statusCode: '400',
        );
      }

      // iOS requires nonce for Credential Manager flow; Android does not.
      final String? rawNonce;
      final String? hashedNonce;
      if (Platform.isIOS) {
        rawNonce = _client.auth.generateRawNonce();
        hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      } else {
        rawNonce = null;
        hashedNonce = null;
      }

      // Re-initialize on iOS every time because nonce changes per attempt.
      if (!_isGoogleInitialized || Platform.isIOS) {
        await GoogleSignIn.instance.initialize(
          clientId: Platform.isIOS
              ? (iosClientId.isEmpty ? null : iosClientId)
              : null,
          serverClientId: webClientId.isEmpty ? null : webClientId,
          nonce: hashedNonce,
        );
        _isGoogleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException(nativeGoogleNoIdTokenMessage);
      }

      const scopes = ['email', 'profile'];
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);
      final accessToken = authorization.accessToken;

      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
        nonce: rawNonce,
      );
    } catch (e, st) {
      if (e is AuthException) rethrow;
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        if (shouldTreatNativeGoogleCancelAsUnavailable(
          isAndroid: Platform.isAndroid,
          description: e.description,
          details: e.details,
        )) {
          AppLogger.warning(
            '[AuthActions] Android Google sign-in returned cancellation; '
            'falling back to browser OAuth: ${e.description ?? e.code}',
          );
          throw const AuthException(
            nativeGoogleSignInFailedMessage,
            statusCode: '400',
          );
        }
        throw const AuthException('Canceled');
      }
      if (e is PlatformException && e.code == 'sign_in_canceled') {
        if (shouldTreatNativeGoogleCancelAsUnavailable(
          isAndroid: Platform.isAndroid,
          description: e.message,
          details: e.details,
        )) {
          AppLogger.warning(
            '[AuthActions] Android Google sign-in platform cancellation; '
            'falling back to browser OAuth: ${e.message ?? e.code}',
          );
          throw const AuthException(
            nativeGoogleSignInFailedMessage,
            statusCode: '400',
          );
        }
        throw const AuthException('Canceled');
      }
      AppLogger.error('[AuthActions] Google sign-in failed: $e', e, st);
      throw const AuthException(
        nativeGoogleSignInFailedMessage,
        statusCode: '400',
      );
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
      throw const AuthException('Apple sign-in failed', statusCode: '400');
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

    // Determine provider from user identities.
    // appMetadata is untrusted server-origin data — cast defensively so a
    // malformed payload (non-String provider value) cannot crash logout.
    final user = _client.auth.currentUser;
    final provider = safeString(user?.appMetadata, 'provider');
    if (provider == null) {
      // Either no user, missing key, or non-String value. Best-effort: skip
      // revocation rather than crash. Log only when we had a session but
      // couldn't determine provider — that's the interesting case.
      if (user != null && user.appMetadata['provider'] != null) {
        AppLogger.warning(
          '[AuthActions] OAuth revoke skipped: invalid provider payload '
          '(type=${user.appMetadata['provider'].runtimeType})',
        );
      }
      return;
    }
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
