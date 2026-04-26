library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../remote/supabase/edge_function_client.dart';
import '../remote/supabase/supabase_client.dart';

/// Supabase Edge Function client provider for cross-feature use.
final edgeFunctionClientProvider = Provider<EdgeFunctionClient>((ref) {
  return EdgeFunctionClient(ref.watch(supabaseClientProvider));
});
