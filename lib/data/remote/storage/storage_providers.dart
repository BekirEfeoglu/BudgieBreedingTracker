import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/moderation_providers.dart';
import 'storage_service.dart';
import 'storage_url_resolver.dart';

/// Provides a [StorageService] instance backed by the Supabase client.
final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final imageSafetyService = ref.watch(imageSafetyServiceProvider);
  return StorageService(client, imageSafetyService: imageSafetyService);
});

/// Resolves persisted storage URLs into URLs that can be rendered now.
final storageUrlResolverProvider = Provider<StorageUrlResolver>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageUrlResolver(client);
});
