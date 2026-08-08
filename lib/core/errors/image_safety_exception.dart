import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

/// A failed mandatory image-safety scan with a stable application reason.
///
/// It preserves the SDK's [StorageException] contract for storage callers,
/// while keeping the reason code separate from provider diagnostics.
class ImageSafetyException extends StorageException {
  final String? code;

  const ImageSafetyException(super.message, {this.code}) : super(error: code);
}
