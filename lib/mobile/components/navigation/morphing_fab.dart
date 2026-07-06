import 'package:flutter/material.dart';
import 'package:memno/mobile/components/navigation/collapsed_inner_fab.dart';
import 'package:memno/mobile/components/navigation/custom_inner_fab.dart';

class MorphingFAB extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final TextEditingController controller;
  final int isEditMode;
  final FocusNode fabFocus;
  final bool isEmbedded;

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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Target dimensions
    final double targetWidth = isExpanded
        ? (isEmbedded ? 500.0 : (screenWidth - 25))
        : 50.0;
    final double targetHeight = isExpanded ? 200.0 : 50.0;

    return Container(
      width: isEmbedded ? 500.0 : screenWidth,
      height: 204.0,
      color: Colors.transparent,
      alignment: isExpanded ? Alignment.bottomCenter : Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isExpanded
              ? 0.0
              : 24.0, // Match standard startFloat layout margin
          bottom: isExpanded ? 0.0 : 16.0,
        ),
        child: AnimatedContainer(
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
        ),
      ),
    );
  }
}
