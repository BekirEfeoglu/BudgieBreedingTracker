part of 'ai_settings_sheet.dart';

/// Form body content for [AiSettingsSheet] — provider selector, text fields,
/// model dropdown, and action buttons.
extension _AiSettingsFormBody on _AiSettingsSheetState {
  List<Widget> buildFormChildren({
    required ThemeData theme,
    required AsyncValue<LocalAiConfig?> configAsync,
    required AsyncValue<List<String>> modelsAsync,
  }) {
    return [
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
          final providerDefaults = provider == LocalAiProvider.openRouter
              ? LocalAiConfig.openRouterDefaults
              : LocalAiConfig.defaults;
          _modelController.text = providerDefaults.model;
          _baseUrlController.text = providerDefaults.baseUrl;
          _debouncedFetchModels(
            baseUrl: providerDefaults.baseUrl,
            model: providerDefaults.model,
            provider: provider,
          );
        },
      ),
      const SizedBox(height: AppSpacing.md),
      if (_selectedProvider == LocalAiProvider.openRouter) ...[
        TextField(
          controller: _apiKeyController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'genetics.local_ai_api_key'.tr(),
            hintText: 'sk-or-...',
            prefixIcon: const Icon(LucideIcons.key, size: 18),
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
      if (modelsAsync.asData?.value case final models?
          when models.isNotEmpty) ...[
        DropdownButtonFormField<String>(
          initialValue: models.contains(_modelController.text)
              ? _modelController.text
              : null,
          decoration: InputDecoration(
            labelText: 'genetics.local_ai_model_select'.tr(),
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
          hintText: _selectedProvider == LocalAiProvider.openRouter
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
      ..._buildModelStatusIndicator(theme, modelsAsync),
      const SizedBox(height: AppSpacing.lg),
      ..._buildActionButtons(theme, configAsync, modelsAsync),
      const SizedBox(height: AppSpacing.lg),
    ];
  }

  List<Widget> _buildModelStatusIndicator(
    ThemeData theme,
    AsyncValue<List<String>> modelsAsync,
  ) {
    if (modelsAsync.isLoading) {
      return [
        const SizedBox(height: AppSpacing.sm),
        const LinearProgressIndicator(minHeight: 2),
      ];
    } else if (modelsAsync.hasError) {
      return [
        const SizedBox(height: AppSpacing.sm),
        Text(
          _errorMessage(modelsAsync.error),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ];
    } else if ((modelsAsync.asData?.value ?? const []).isEmpty &&
        _selectedProvider == LocalAiProvider.ollama) {
      return [
        const SizedBox(height: AppSpacing.sm),
        Text(
          'genetics.local_ai_models_empty'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ];
    }
    return [];
  }

  List<Widget> _buildActionButtons(
    ThemeData theme,
    AsyncValue<LocalAiConfig?> configAsync,
    AsyncValue<List<String>> modelsAsync,
  ) {
    return [
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: configAsync.isLoading || _isTestingConnection
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await _persistConfig();
                  if (!mounted) return;
                  _showMessage('common.saved_successfully'.tr());
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
          onPressed: configAsync.isLoading || _isTestingConnection
              ? null
              : _testConnection,
          icon: _isTestingConnection
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.wifi, size: 18),
          label: Text('genetics.test_local_ai_connection'.tr()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: configAsync.isLoading || modelsAsync.isLoading
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
                  } catch (error, st) {
                    AppLogger.error(
                      '[AiSettingsSheet] Model refresh failed',
                      error,
                      st,
                    );
                    _showMessage(_errorMessage(error));
                  }
                },
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          label: Text('genetics.refresh_local_ai_models'.tr()),
        ),
      ),
    ];
  }
}
