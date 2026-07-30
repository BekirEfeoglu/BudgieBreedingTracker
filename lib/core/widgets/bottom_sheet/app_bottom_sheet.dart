import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';

/// Shows a modal bottom sheet with consistent safe-area + keyboard handling.
///
/// Wraps the caller's [builder] output in:
/// - `SafeArea(minimum: EdgeInsets.only(bottom: 16))` so a notch/home-indicator
///   never occludes the sheet's bottom CTA.
/// - `Padding(padding: MediaQuery.viewInsetsOf)` so an open keyboard pushes the
///   content up instead of covering the submit button.
///
/// Use this instead of [showModalBottomSheet] directly unless the sheet is
/// intentionally small-content (e.g. a single confirmation dialog).
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool showCloseButton = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
  Clip? clipBehavior,
  double? elevation,
  Color? barrierColor,
  String? barrierLabel,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
    shape:
        shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24.0),
          ), // AppSpacing.radiusXl
        ),
    constraints: constraints,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    clipBehavior: clipBehavior,
    elevation: elevation,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel ?? 'common.close'.tr(),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (isDismissible && showCloseButton)
                    PositionedDirectional(
                      end: 4,
                      child: AppIconButton(
                        icon: const Icon(LucideIcons.x),
                        semanticLabel: 'common.close'.tr(),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(child: builder(ctx)),
          ],
        ),
      ),
    ),
  );
}
