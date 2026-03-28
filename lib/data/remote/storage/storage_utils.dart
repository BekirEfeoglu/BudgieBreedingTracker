/// Pure utility functions for file validation and MIME type detection
/// used by [StorageService].
abstract final class StorageUtils {
  /// Extracts file extension safely, falling back to 'jpg' if no dot is found.
  static String safeExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == filename.length - 1) return 'jpg';
    return filename.substring(dotIndex + 1).toLowerCase();
  }

  /// Validates that file content matches the claimed extension by checking
  /// magic bytes (file signatures). Prevents renamed malicious files.
  static bool validateMagicBytes(List<int> bytes, String ext) {
    if (bytes.length < 4) return false;
    return switch (ext) {
      'jpg' || 'jpeg' =>
        bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF,
      'png' =>
        bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47,
      'gif' =>
        bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46,
      'webp' =>
        bytes.length >= 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50,
      'heic' =>
        bytes.length >= 12 &&
            bytes[4] == 0x66 &&
            bytes[5] == 0x74 &&
            bytes[6] == 0x79 &&
            bytes[7] == 0x70 &&
            _isHeicBrand(bytes),
      _ => false,
    };
  }

  /// Checks that bytes 8-11 contain a known HEIC/HEIF brand identifier.
  static bool _isHeicBrand(List<int> bytes) {
    if (bytes.length < 12) return false;
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    const validBrands = {'heic', 'heix', 'mif1', 'msf1'};
    return validBrands.contains(brand);
  }

  /// Returns the MIME type for a given filename based on its extension.
  /// Uses [safeExtension] for consistent extension extraction (falls back to 'jpg').
  static String getMimeType(String filename) {
    final ext = safeExtension(filename);
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }
}
