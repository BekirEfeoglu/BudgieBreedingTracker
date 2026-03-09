import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pdf_export_service.dart';

/// Export button with menu: PDF and image export options.
class PedigreeExportButton extends StatefulWidget {
  final Bird rootBird;
  final Map<String, Bird> ancestors;
  final int maxDepth;
  final Future<ui.Image?> Function()? onCaptureImage;

  const PedigreeExportButton({
    super.key,
    required this.rootBird,
    required this.ancestors,
    required this.maxDepth,
    this.onCaptureImage,
  });

  @override
  State<PedigreeExportButton> createState() => _PedigreeExportButtonState();
}

class _PedigreeExportButtonState extends State<PedigreeExportButton> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: MenuAnchor(
        builder: (context, controller, child) {
          return FilledButton.tonalIcon(
            onPressed: _isExporting ? null : () => controller.open(),
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.share2, size: 18),
            label: Text('genealogy.export_options'.tr()),
          );
        },
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(LucideIcons.fileDown, size: 18),
            onPressed: _isExporting ? null : _exportPdf,
            child: Text('genealogy.export_pdf'.tr()),
          ),
          if (widget.onCaptureImage != null)
            MenuItemButton(
              leadingIcon: const Icon(LucideIcons.image, size: 18),
              onPressed: _isExporting ? null : _exportImage,
              child: Text('genealogy.share_as_image'.tr()),
            ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final service = PdfExportService();
      final bytes = await service.generatePedigreeReport(
        rootBird: widget.rootBird,
        ancestors: widget.ancestors,
        maxDepth: widget.maxDepth,
      );

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'pedigree_${widget.rootBird.name}_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));

      messenger.showSnackBar(
        SnackBar(content: Text('genealogy.export_success'.tr())),
      );
    } catch (e, st) {
      AppLogger.error('[PedigreeExport]', e, st);
      messenger.showSnackBar(
        SnackBar(content: Text('errors.unknown'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportImage() async {
    if (widget.onCaptureImage == null) return;
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final image = await widget.onCaptureImage!();
      if (image == null) throw Exception('Failed to capture tree image');

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image');

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'pedigree_${widget.rootBird.name}_$timestamp.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));

      messenger.showSnackBar(
        SnackBar(content: Text('genealogy.image_export_success'.tr())),
      );
    } catch (e, st) {
      AppLogger.error('[PedigreeImageExport]', e, st);
      messenger.showSnackBar(
        SnackBar(content: Text('errors.unknown'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
