import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase bootstrap validation', () {
    test('accepts a real Supabase project URL', () {
      expect(
        debugIsValidSupabaseUrl('https://lmqkwgitzvpacycujzgc.supabase.co'),
        isTrue,
      );
    });

    test('rejects placeholder Supabase URLs', () {
      expect(
        debugIsValidSupabaseUrl('https://your-project.supabase.co'),
        isFalse,
      );
      expect(debugIsValidSupabaseUrl('https://example.invalid'), isFalse);
    });

    test('accepts legacy JWT anon keys', () {
      expect(
        debugIsValidSupabaseApiKey(
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiYyIsInJvbGUiOiJhbm9uIn0.'
          'signature',
        ),
        isTrue,
      );
    });

    test('accepts modern publishable keys', () {
      expect(
        debugIsValidSupabaseApiKey('sb_publishable_JE0AXA9bMbUwBIb0x91djA_tUkw4Kpj'),
        isTrue,
      );
    });

    test('rejects placeholder and malformed API keys', () {
      expect(debugIsValidSupabaseApiKey(''), isFalse);
      expect(debugIsValidSupabaseApiKey('your-anon-key-here'), isFalse);
      expect(debugIsValidSupabaseApiKey('sb_publishable_your-key'), isFalse);
      expect(debugIsValidSupabaseApiKey('not-a-real-key'), isFalse);
    });
  });
}
