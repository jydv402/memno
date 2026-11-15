import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/functionality/edit_mode.dart';
import 'package:memno/mobile/components/navigation/collapsed_inner_fab.dart';
import 'package:memno/mobile/components/navigation/custom_inner_fab.dart';

/// The expanding entry-input FAB: a round collapsed pill that morphs into
/// a full-width input sheet when opened.
///
/// [MorphingFAB] animates between [CollapsedInnerFAB] and
/// [CustomInnerFAB] over 300 ms with matched 200 ms fades. The parent owns
/// the expanded state; the widget itself is stateless and purely a
/// presenter for the two phases and their callbacks.
class MorphingFAB extends StatelessWidget {
  /// Creates the morphing FAB; all parameters are required because both
  /// phases need their callbacks and the input phase needs the controller.
  const MorphingFAB({
    super.key,
    required this.isExpanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onConfirm,
    required this.onCancel,
    required this.controller,
    required this.isEditMode,
    required this.fabFocus,
    required this.isEmbedded,
  });

  /// Whether the input sheet is currently open.
  final bool isExpanded;

  /// Invoked when the collapsed pill is tapped.
  final VoidCallback onExpand;

  /// Invoked when the input sheet requests collapse.
  final VoidCallback onCollapse;

  /// Invoked when the input sheet confirms its text.
  final VoidCallback onConfirm;

  /// Invoked when the input sheet cancels.
  final VoidCallback onCancel;

  /// Text controller shared with the expanded input field.
  final TextEditingController controller;

  /// Current input mode, deciding the expanded sheet's labels and actions.
  final EditMode isEditMode;

  /// Focus node attached to the expanded input field.
  final FocusNode fabFocus;

  /// Whether the FAB sits inside a narrower embedded surface, capping the
  /// expanded width at 500 px instead of full screen width.
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Target dimensions
    final double targetWidth = isExpanded
        ? (isEmbedded ? 500.0 : (screenWidth - 32.0))
        : 50.0;
    final double targetHeight = isExpanded ? 200.0 : 50.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: targetWidth,
      height: targetHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isExpanded ? 0.0 : 25.0),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: isExpanded
            ? CustomInnerFAB(
                key: const ValueKey('expandedFAB'),
                isEmbedded: isEmbedded,
                onCollapse: onCollapse,
                onConfirm: onConfirm,
                onCancel: onCancel,
                controller: controller,
                isEditMode: isEditMode,
                fabFocus: fabFocus,
              )
            : CollapsedInnerFAB(
                key: const ValueKey('collapsedFAB'),
                onExpand: onExpand,
              ),
      ),
    );
  }
}
