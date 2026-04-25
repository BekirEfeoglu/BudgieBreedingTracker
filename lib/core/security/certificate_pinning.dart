import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// Enforces TLS certificate pinning for known backend hosts.
///
/// Rejects direct HTTPS connections to pinned hosts when the peer certificate
/// fingerprint is not in the trusted set. Set `--dart-define=ALLOW_PROXY=true`
/// for proxy-based debugging tools (Charles, mitmproxy, etc.).
///
/// Usage:
/// ```dart
/// // Call once before Supabase.initialize() in bootstrap.dart
/// CertificatePinning.install();
/// ```
///
/// To update pins when backend certificates rotate, replace the SHA-256
/// fingerprints in [_pinnedHosts]. Obtain new fingerprints via:
/// ```bash
/// openssl s_client -connect <host>:443 -servername <host> < /dev/null 2>/dev/null \
///   | openssl x509 -noout -fingerprint -sha256
/// ```
class CertificatePinning {
  CertificatePinning._();

  static const _tag = '[CertificatePinning]';

  /// Map of pinned hostnames to their allowed SHA-256 certificate fingerprints.
  ///
  /// Each host can have multiple fingerprints to allow for certificate rotation
  /// (e.g., current cert + next cert). Fingerprints are uppercase hex with
  /// colon separators matching `openssl x509 -fingerprint -sha256` output.
  ///
  /// The Supabase host is derived at runtime from the SUPABASE_URL env var,
  /// so we pin against the shared Supabase infrastructure domain suffix.
  static const _pinnedDomainSuffixes = <String>['.supabase.co'];

  /// SHA-256 fingerprints of trusted certificates for pinned domains.
  ///
  /// Pins the currently deployed Supabase leaf certificate. Update these when
  /// Supabase rotates certificates.
  /// Obtain new fingerprints via:
  /// ```bash
  /// openssl s_client -connect <host>:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256
  /// ```
  static const _trustedFingerprints = <String>{
    // Supabase leaf certificate (rotate when renewed)
    '39:8B:CC:E2:D9:95:CB:23:CB:09:2A:93:7B:5B:58:BD:95:B4:08:A4:5F:BF:89:AB:7B:B1:14:03:47:89:AE:7D',
    // Supabase intermediate CA (kept for emergency invalid-chain fallback)
    '1D:FC:16:05:FB:AD:35:8D:8B:C8:44:F7:6D:15:20:3F:AC:9C:A5:C1:A7:9F:D4:85:7F:FA:F2:86:4F:BE:BF:96',
  };

  /// Installs a global [HttpOverrides] that validates TLS certificates
  /// against pinned fingerprints for known backend hosts.
  ///
  /// Must be called before any HTTP connections are made (before
  /// `Supabase.initialize()` in `bootstrap.dart`).
  /// Whether to allow all certificates (for proxy debugging).
  /// Controlled explicitly via `--dart-define=ALLOW_PROXY=true`.
  static const _allowProxy = bool.fromEnvironment('ALLOW_PROXY');

  static void install() {
    if (_allowProxy) {
      AppLogger.info(
        '$_tag Skipping certificate pinning '
        '(ALLOW_PROXY=$_allowProxy)',
      );
      return;
    }

    HttpOverrides.global = _PinningHttpOverrides(
      previous: HttpOverrides.current,
    );
    AppLogger.info('$_tag Certificate pinning installed');
  }

  /// Whether a given hostname matches one of the pinned domain suffixes.
  @visibleForTesting
  static bool isPinnedHost(String host) {
    final lowerHost = host.toLowerCase();
    return _pinnedDomainSuffixes.any((suffix) => lowerHost.endsWith(suffix));
  }

  @visibleForTesting
  static bool shouldRejectProxyForHost(String host, {required bool hasProxy}) {
    return hasProxy && !_allowProxy && isPinnedHost(host);
  }
}

class _PinningHttpOverrides extends HttpOverrides {
  final HttpOverrides? previous;

  _PinningHttpOverrides({this.previous});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Use the system default SecurityContext so that non-pinned hosts work
    // normally with system-trusted CAs (Sentry, RevenueCat, etc.). For pinned
    // direct HTTPS connections, create the SecureSocket ourselves so the
    // successfully validated peer certificate can still be fingerprint-checked.
    final client =
        previous?.createHttpClient(context) ?? super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) async {
      if (proxyHost != null && proxyPort != null) {
        if (CertificatePinning.shouldRejectProxyForHost(
          uri.host,
          hasProxy: true,
        )) {
          throw TlsException(
            'Proxy connections are not allowed for pinned host ${uri.host}',
          );
        }
        return Socket.startConnect(proxyHost, proxyPort);
      }

      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      if (uri.scheme != 'https') {
        return Socket.startConnect(uri.host, port);
      }

      final task = await SecureSocket.startConnect(
        uri.host,
        port,
        context: context,
        onBadCertificate: (cert) => _isTrustedPinnedCertificate(uri.host, cert),
      );

      final checkedSocket = task.socket.then((socket) {
        if (CertificatePinning.isPinnedHost(uri.host)) {
          final cert = socket.peerCertificate;
          if (cert == null || !_isTrustedPinnedCertificate(uri.host, cert)) {
            socket.destroy();
            throw TlsException(
              'Certificate pinning check failed for ${uri.host}:$port',
            );
          }
        }
        return socket;
      });

      return ConnectionTask.fromSocket(checkedSocket, task.cancel);
    };
    return client;
  }

  static bool _isTrustedPinnedCertificate(String host, X509Certificate cert) {
    if (!CertificatePinning.isPinnedHost(host)) return false;
    final fingerprint = _computeFingerprint(cert);
    final trusted =
        fingerprint != null &&
        CertificatePinning._trustedFingerprints.contains(fingerprint);
    if (!trusted) {
      AppLogger.warning(
        '[CertificatePinning] Rejected certificate for $host '
        '(fingerprint mismatch)',
      );
    }
    return trusted;
  }

  /// Computes the SHA-256 fingerprint of a certificate in the same format
  /// as `openssl x509 -fingerprint -sha256` (uppercase hex with colons).
  static String? _computeFingerprint(X509Certificate cert) {
    try {
      final digest = crypto.sha256.convert(cert.der);
      return digest.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');
    } catch (e) {
      AppLogger.warning(
        '[CertificatePinning] Fingerprint computation failed: $e',
      );
      return null;
    }
  }
}
