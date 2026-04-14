import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';

part 'ai_settings_sheet_form.dart';
part 'ai_settings_sheet_helpers.dart';

class AiSettingsSheet extends ConsumerStatefulWidget {
  const AiSettingsSheet({super.key});

  @override
  ConsumerState<AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends ConsumerState<AiSettingsSheet> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _apiKeyController;
  LocalAiProvider _selectedProvider = LocalAiProvider.openRouter;
  bool _isTestingConnection = false;
  Timer? _fetchDebounce;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _modelController = TextEditingController();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _fetchDebounce?.cancel();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _initFromConfig(LocalAiConfig config) {
    if (_initialized) return;
    _initialized = true;
    _selectedProvider = config.provider;
    _baseUrlController.text = config.baseUrl;
    _modelController.text = config.model;
    _apiKeyController.text = config.apiKey;
    _debouncedFetchModels(
      baseUrl: config.baseUrl,
      model: config.model,
      provider: config.provider,
      apiKey: config.apiKey,
    );
  }

  Future<LocalAiConfig?> _persistConfig() async {
    final notifier = ref.read(localAiConfigProvider.notifier);
    await notifier.save(
      provider: _selectedProvider,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
      apiKey: _apiKeyController.text,
    );
    return ref.read(localAiConfigProvider).asData?.value;
  }

  void _debouncedFetchModels({
    required String baseUrl,
    required String model,
    LocalAiProvider? provider,
    String? apiKey,
  }) {
    _fetchDebounce?.cancel();
    _fetchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchModels(
        baseUrl: baseUrl,
        model: model,
        provider: provider,
        apiKey: apiKey,
      );
    });
  }

  Future<void> _fetchModels({
    required String baseUrl,
    required String model,
    LocalAiProvider? provider,
    String? apiKey,
    bool force = false,
  }) async {
    await ref.read(localAiModelListProvider.notifier).fetch(
          baseUrl: baseUrl,
          selectedModel: model,
          provider: provider ?? _selectedProvider,
          apiKey: apiKey ?? _apiKeyController.text,
          force: force,
        );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _testConnection() async {
    if (_isTestingConnection) return;

    setState(() => _isTestingConnection = true);
    try {
      final config = await _persistConfig();
      if (config == null || !mounted) return;
      await ref.read(localAiServiceProvider).testConnection(config: config);
      if (!mounted) return;
      await _fetchModels(
        baseUrl: config.baseUrl,
        model: config.model,
        force: true,
      );
      _showMessage('genetics.local_ai_connection_ok'.tr());
    } catch (error, st) {
      AppLogger.error('[AiSettingsSheet] Connection test failed', error, st);
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  String _errorMessage(Object? error) {
    if (error is AppException) {
      final msg = error.message;
      if (msg.startsWith(LocalAiService.errorKeyPrefix)) {
        final parts = msg.split('\x00');
        final key = parts[0];
        return parts.length > 1
            ? key.tr(args: parts.sublist(1))
            : key.tr();
      }
      return msg;
    }
    return error?.toString() ?? 'common.error'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(localAiConfigProvider);
    final modelsAsync = ref.watch(localAiModelListProvider);

    if (configAsync.asData?.value case final config?) {
      _initFromConfig(config);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(
                    LucideIcons.settings2,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'genetics.local_ai_model_settings'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: buildFormChildren(
                    theme: theme,
                    configAsync: configAsync,
                    modelsAsync: modelsAsync,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
