import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/api/fcm_token_remote_source.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Missing native Firebase config should not crash background isolate.
  }
}

class PushNotificationService {
  PushNotificationService({
    required FcmTokenRemoteSource tokenRemoteSource,
    required NotificationService localNotificationService,
    FirebaseMessaging? messaging,
  }) : _tokenRemoteSource = tokenRemoteSource,
       _localNotificationService = localNotificationService,
       _messaging = messaging;

  final FcmTokenRemoteSource _tokenRemoteSource;
  final NotificationService _localNotificationService;
  FirebaseMessaging? _messaging;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageOpenSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  bool _firebaseReady = false;
  bool _listenersBound = false;

  Future<void> init({required String userId}) async {
    if (!_supportsPushNotifications) return;
    final ready = await _ensureFirebaseReady();
    if (!ready) return;

    if (!_listenersBound) {
      final messaging = _messagingInstance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _tokenRefreshSub = messaging.onTokenRefresh.listen(
        (token) => unawaited(_upsertToken(userId, token)),
        onError: (Object error, StackTrace stackTrace) {
          AppLogger.warning(
            '[PushNotificationService] Token refresh stream failed: $error',
          );
        },
      );
      _messageOpenSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleNotificationTap,
      );
      _foregroundMessageSub = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _listenersBound = true;
    }

    if (Platform.isIOS) {
      await _messagingInstance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final initialMessage = await _messagingInstance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    await syncToken(userId);
  }

  Future<void> syncToken(String userId) async {
    if (!_supportsPushNotifications) return;
    final ready = await _ensureFirebaseReady();
    if (!ready) return;

    try {
      final token = await _messagingInstance.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.info(
          '[PushNotificationService] No FCM token available yet for ${userId.substring(0, 8)}...',
        );
        return;
      }
      await _upsertToken(userId, token);
    } catch (e, st) {
      AppLogger.error('[PushNotificationService] syncToken failed', e, st);
    }
  }

  Future<void> deactivateCurrentToken() async {
    if (!_supportsPushNotifications || !_firebaseReady) return;
    try {
      final token = await _messagingInstance.getToken();
      if (token == null || token.isEmpty) return;
      await _tokenRemoteSource.deactivateToken(token);
    } catch (e, st) {
      AppLogger.error(
        '[PushNotificationService] deactivateCurrentToken failed',
        e,
        st,
      );
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _messageOpenSub?.cancel();
    await _foregroundMessageSub?.cancel();
    _listenersBound = false;
  }

  bool get _supportsPushNotifications => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  FirebaseMessaging get _messagingInstance =>
      _messaging ??= FirebaseMessaging.instance;

  Future<bool> _ensureFirebaseReady() async {
    if (_firebaseReady) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
      return true;
    } catch (e) {
      AppLogger.warning(
        '[PushNotificationService] Firebase not configured. '
        'Add google-services.json / GoogleService-Info.plist to enable push: $e',
      );
      return false;
    }
  }

  Future<void> _upsertToken(String userId, String token) async {
    await _tokenRemoteSource.upsertToken(
      userId: userId,
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
    AppLogger.info('[PushNotificationService] Synced FCM token for ${userId.substring(0, 8)}...');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (Platform.isIOS || !_localNotificationService.isInitialized) return;

    final title =
        message.notification?.title ??
        _stringValue(message.data['title']) ??
        _stringValue(message.data['notification_title']);
    final body =
        message.notification?.body ??
        _stringValue(message.data['body']) ??
        _stringValue(message.data['notification_body']) ??
        '';
    if (title == null || title.isEmpty) return;

    try {
      await _localNotificationService.showNotification(
        id: _notificationIdFor(message),
        title: title,
        body: body,
        payload: _payloadFromMessage(message),
      );
    } catch (e) {
      AppLogger.warning(
        '[PushNotificationService] Failed to surface foreground push: $e',
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final payload = _payloadFromMessage(message);
    if (payload == null) return;
    _localNotificationService.onNotificationTap?.call(payload);
  }

  String? _payloadFromMessage(RemoteMessage message) {
    final payload = _stringValue(message.data['payload']);
    if (payload != null && payload.isNotEmpty) return payload;

    final type =
        _stringValue(message.data['type']) ??
        _stringValue(message.data['reference_type']);
    final entityId =
        _stringValue(message.data['entity_id']) ??
        _stringValue(message.data['related_entity_id']) ??
        _stringValue(message.data['reference_id']) ??
        _stringValue(message.data['id']);

    if (type == null || entityId == null || type.isEmpty || entityId.isEmpty) {
      return null;
    }
    return '$type:$entityId';
  }

  int _notificationIdFor(RemoteMessage message) {
    final sentTime = message.sentTime?.millisecondsSinceEpoch;
    if (sentTime != null) return sentTime.remainder(1 << 31);
    return message.messageId.hashCode & 0x7fffffff;
  }

  String? _stringValue(Object? value) {
    if (value == null) return null;
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }
}
