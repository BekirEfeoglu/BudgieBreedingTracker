import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';

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
    if (!config.isOpenRouter) {
      _debouncedFetchModels(baseUrl: config.baseUrl, model: config.model);
    }
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
  }) {
    _fetchDebounce?.cancel();
    _fetchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchModels(baseUrl: baseUrl, model: model);
    });
  }

  Future<void> _fetchModels({
    required String baseUrl,
    required String model,
    bool force = false,
  }) async {
    await ref
        .read(localAiModelListProvider.notifier)
        .fetch(baseUrl: baseUrl, selectedModel: model, force: force);
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
    } catch (error) {
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
                  children: [
                    SegmentedButton<LocalAiProvider>(
                      segments: [
                        const ButtonSegment(
                          value: LocalAiProvider.ollama,
                          label: Text('Ollama'),
                          icon: Icon(LucideIcons.server, size: 16),
                        ),
                        const ButtonSegment(
                          value: LocalAiProvider.openRouter,
                          label: Text('OpenRouter'),
                          icon: Icon(LucideIcons.cloud, size: 16),
                        ),
                      ],
                      selected: {_selectedProvider},
                      onSelectionChanged: (selection) {
                        final provider = selection.first;
                        setState(() => _selectedProvider = provider);
                        ref.read(localAiModelListProvider.notifier).clear();
                        final providerDefaults =
                            provider == LocalAiProvider.openRouter
                                ? LocalAiConfig.openRouterDefaults
                                : LocalAiConfig.defaults;
                        _modelController.text = providerDefaults.model;
                        _baseUrlController.text = providerDefaults.baseUrl;
                        if (provider == LocalAiProvider.ollama) {
                          _debouncedFetchModels(
                            baseUrl: providerDefaults.baseUrl,
                            model: providerDefaults.model,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_selectedProvider ==
                        LocalAiProvider.openRouter) ...[
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'genetics.local_ai_api_key'.tr(),
                          hintText: 'sk-or-...',
                          prefixIcon:
                              const Icon(LucideIcons.key, size: 18),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ] else ...[
                      TextField(
                        controller: _baseUrlController,
                        decoration: InputDecoration(
                          labelText: 'genetics.local_ai_url'.tr(),
                          hintText: LocalAiConfig.defaults.baseUrl,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_selectedProvider == LocalAiProvider.ollama)
                      if (modelsAsync.asData?.value case final models?
                          when models.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue:
                              models.contains(_modelController.text)
                                  ? _modelController.text
                                  : null,
                          decoration: InputDecoration(
                            labelText:
                                'genetics.local_ai_model_select'.tr(),
                          ),
                          items: models
                              .map(
                                (model) => DropdownMenuItem<String>(
                                  value: model,
                                  child: Text(
                                    model,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            _modelController.text = value;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    TextField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: 'genetics.local_ai_model'.tr(),
                        hintText:
                            _selectedProvider == LocalAiProvider.openRouter
                                ? LocalAiConfig.openRouterDefaults.model
                                : LocalAiConfig.defaults.model,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildHintStrip(
                      theme,
                      _selectedProvider == LocalAiProvider.openRouter
                          ? 'genetics.local_ai_hint_openrouter'.tr()
                          : 'genetics.local_ai_hint'.tr(),
                    ),
                    if (_selectedProvider == LocalAiProvider.openRouter) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildModelRecommendations(theme),
                    ],
                    if (_selectedProvider == LocalAiProvider.ollama) ...[
                      if (modelsAsync.isLoading) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const LinearProgressIndicator(minHeight: 2),
                      ] else if (modelsAsync.hasError) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _errorMessage(modelsAsync.error),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ] else if ((modelsAsync.asData?.value ?? const [])
                          .isEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'genetics.local_ai_models_empty'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: configAsync.isLoading ||
                                _isTestingConnection
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                await _persistConfig();
                                if (!mounted) return;
                                _showMessage(
                                  'common.saved_successfully'.tr(),
                                );
                                navigator.pop();
                              },
                        icon: const Icon(LucideIcons.save, size: 18),
                        label: Text('genetics.save_ai_config'.tr()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: configAsync.isLoading ||
                                _isTestingConnection
                            ? null
                            : _testConnection,
                        icon: _isTestingConnection
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.wifi, size: 18),
                        label: Text(
                          'genetics.test_local_ai_connection'.tr(),
                        ),
                      ),
                    ),
                    if (_selectedProvider ==
                        LocalAiProvider.ollama) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: configAsync.isLoading ||
                                  modelsAsync.isLoading
                              ? null
                              : () async {
                                  final config = await _persistConfig();
                                  if (config == null || !mounted) return;
                                  try {
                                    await _fetchModels(
                                      baseUrl: config.baseUrl,
                                      model: config.model,
                                      force: true,
                                    );
                                  } catch (error) {
                                    _showMessage(_errorMessage(error));
                                  }
                                },
                          icon: const Icon(
                            LucideIcons.refreshCw,
                            size: 18,
                          ),
                          label: Text(
                            'genetics.refresh_local_ai_models'.tr(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelRecommendations(ThemeData theme) {
    const models = [
      (
        id: 'google/gemma-4-26b-a4b-it:free',
        name: 'Gemma 4 26B',
        tag: 'genetics.ai_model_free',
        vision: true,
      ),
      (
        id: 'meta-llama/llama-4-scout:free',
        name: 'Llama 4 Scout',
        tag: 'genetics.ai_model_free',
        vision: true,
      ),
      (
        id: 'google/gemini-2.0-flash-001',
        name: 'Gemini 2.0 Flash',
        tag: 'genetics.ai_model_paid',
        vision: true,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'genetics.ai_recommended_models'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...models.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: InkWell(
                onTap: () {
                  _modelController.text = m.id;
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        m.vision ? LucideIcons.eye : LucideIcons.type,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          m.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: m.tag.contains('free')
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          m.tag.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: m.tag.contains('free')
                                ? const Color(0xFF10B981)
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintStrip(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
