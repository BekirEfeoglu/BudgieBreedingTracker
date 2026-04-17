import 'package:flutter/material.dart';

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
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
  Clip? clipBehavior,
  double? elevation,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    shape: shape,
    constraints: constraints,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    clipBehavior: clipBehavior,
    elevation: elevation,
    barrierColor: barrierColor,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 16),
        child: builder(ctx),
      ),
    ),
  );
}
