import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/supabase/edge_function_client.dart';
import '../../../data/remote/supabase/supabase_client.dart';
import 'content_moderation_service.dart';
import 'image_safety_service.dart';

/// Provides [ContentModerationService] with optional Edge Function support.
final contentModerationServiceProvider = Provider<ContentModerationService>((
  ref,
) {
  EdgeFunctionClient? edgeFunctionClient;
  try {
    final client = ref.watch(supabaseClientProvider);
    edgeFunctionClient = EdgeFunctionClient(client);
  } catch (_) {
    // Supabase not initialized (e.g. guest mode) — client-side only.
  }
  return ContentModerationService(edgeFunctionClient: edgeFunctionClient);
});

/// Provides [ImageSafetyService] with optional Edge Function support.
final imageSafetyServiceProvider = Provider<ImageSafetyService>((ref) {
  EdgeFunctionClient? edgeFunctionClient;
  try {
    final client = ref.watch(supabaseClientProvider);
    edgeFunctionClient = EdgeFunctionClient(client);
  } catch (_) {
    // Supabase not initialized — image scanning skipped.
  }
  return ImageSafetyService(edgeFunctionClient: edgeFunctionClient);
});
