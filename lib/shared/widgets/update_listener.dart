import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/enums/update_status.dart';
import 'package:budgie_breeding_tracker/features/update/providers/update_status_provider.dart';
import 'package:budgie_breeding_tracker/features/update/screens/forced_update_screen.dart';
import 'package:budgie_breeding_tracker/features/update/widgets/update_optional_sheet.dart';

/// Wraps a child and reacts to [updateStatusProvider]:
/// - `forced` -> replaces child with [ForcedUpdateScreen]
/// - `optional` -> shows [UpdateOptionalSheet] once per app session
/// - `none` -> renders child as-is
class UpdateListener extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateListener({super.key, required this.child});

  @override
  ConsumerState<UpdateListener> createState() => _UpdateListenerState();
}

class _UpdateListenerState extends ConsumerState<UpdateListener> {
  bool _optionalShown = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(updateStatusProvider).asData?.value;

    if (status == UpdateStatus.forced) {
      return const ForcedUpdateScreen();
    }

    if (status == UpdateStatus.optional && !_optionalShown) {
      _optionalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) UpdateOptionalSheet.show(context);
      });
    }

    return widget.child;
  }
}
