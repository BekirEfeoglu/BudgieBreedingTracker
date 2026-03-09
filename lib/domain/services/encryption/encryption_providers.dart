import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'encryption_service.dart';

/// Provides a singleton [EncryptionService] for encrypting/decrypting
/// sensitive bird data fields (ring numbers, genetic info, etc.).
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});
