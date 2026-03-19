import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/supabase/edge_function_client.dart';
import '../../../data/remote/supabase/supabase_client.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';

/// Provides [ContentModerationService] with optional Edge Function support.
final contentModerationServiceProvider =
    Provider<ContentModerationService>((ref) {
  EdgeFunctionClient? edgeFunctionClient;
  try {
    final client = ref.watch(supabaseClientProvider);
    edgeFunctionClient = EdgeFunctionClient(client);
  } catch (_) {
    // Supabase not initialized (e.g. guest mode) — client-side only.
  }
  return ContentModerationService(edgeFunctionClient: edgeFunctionClient);
});
