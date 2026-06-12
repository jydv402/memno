import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

class _DockItem {
  final IconData icon;
  final String label;
  final int? index; // null for actions
  final bool isAction;
  final VoidCallback? onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    this.index,
    this.isAction = false,
    this.onTap,
  });
}

class DesktopDock extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationChanged;
  final VoidCallback onSearchTap;
  final VoidCallback onNewPage;

  const DesktopDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationChanged,
    required this.onSearchTap,
    required this.onNewPage,
  });

  @override
  State<DesktopDock> createState() => _DesktopDockState();
}

class _DesktopDockState extends State<DesktopDock> {
  bool _isVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
  }

  void _onDockHoverEnter() {
    _cancelHideTimer();
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  void _onDockHoverExit() {
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final String placement = colors.dockPlacement;

    final isHorizontal = placement == 'bottom' || placement == 'top';

    final items = [
      _DockItem(
        icon: widget.selectedIndex == 0 ? Icons.folder : Icons.folder_outlined,
        label: 'All Notes',
        index: 0,
      ),
      _DockItem(
        icon: widget.selectedIndex == 1 ? Icons.favorite : Icons.favorite_border_rounded,
        label: 'Liked Notes',
        index: 1,
      ),
      _DockItem(
        icon: Icons.folder_off_outlined,
        label: 'Empty Notes',
        index: 2,
      ),
      _DockItem(
        icon: widget.selectedIndex == 3 ? Icons.settings : Icons.settings_outlined,
        label: 'Settings',
        index: 3,
      ),
      _DockItem(
        icon: Icons.search_rounded,
        label: 'Search',
        isAction: true,
        onTap: widget.onSearchTap,
      ),
      _DockItem(
        icon: Icons.add_rounded,
        label: 'New Page',
        isAction: true,
        onTap: widget.onNewPage,
      ),
    ];

    // Build the dock body items
    final List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      if (i == 4) {
        // Divider before actions
        children.add(
          isHorizontal
              ? Container(
                  width: 1,
                  height: 28,
                  color: colors.textClr.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                )
              : Container(
                  height: 1,
                  width: 28,
                  color: colors.textClr.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
        );
      }

      final item = items[i];
      final isSelected = !item.isAction && widget.selectedIndex == item.index;

      final button = Tooltip(
        message: item.label,
        preferBelow: placement == 'top',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.toastBg,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontFamily: 'GoogleSans',
          color: colors.toastText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        child: Material(
          color: isSelected ? colors.accnt : colors.pill.withValues(alpha: 0.25),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (item.isAction) {
                item.onTap?.call();
              } else if (item.index != null) {
                widget.onDestinationChanged(item.index!);
              }
            },
            hoverColor: colors.textClr.withValues(alpha: 0.15),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Icon(
                  item.icon,
                  color: isSelected ? Colors.black : colors.textClr,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      );

      children.add(
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: button,
        ),
      );
    }

    final dockBody = MouseRegion(
      onEnter: (_) => _onDockHoverEnter(),
      onExit: (_) => _onDockHoverExit(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: colors.box.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colors.textClr.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: isHorizontal
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
          ),
        ),
      ),
    );

    // Calculate layout constraints based on placement
    double? left, right, top, bottom;

    if (placement == 'bottom') {
      left = 0;
      right = 0;
      bottom = _isVisible ? 20.0 : -88.0;
    } else if (placement == 'top') {
      left = 0;
      right = 0;
      top = _isVisible ? 20.0 : -88.0;
    } else if (placement == 'left') {
      top = 0;
      bottom = 0;
      left = _isVisible ? 20.0 : -88.0;
    } else if (placement == 'right') {
      top = 0;
      bottom = 0;
      right = _isVisible ? 20.0 : -88.0;
    }

    // Build the hover sensor trigger
    Widget? sensorWidget;
    if (!_isVisible) {
      const sensorColor = Colors.transparent;
      if (placement == 'bottom') {
        sensorWidget = Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 12,
          child: MouseRegion(
            onEnter: (_) => _onDockHoverEnter(),
            child: Container(color: sensorColor),
          ),
        );
      } else if (placement == 'top') {
        sensorWidget = Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 12,
          child: MouseRegion(
            onEnter: (_) => _onDockHoverEnter(),
            child: Container(color: sensorColor),
          ),
        );
      } else if (placement == 'left') {
        sensorWidget = Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 12,
          child: MouseRegion(
            onEnter: (_) => _onDockHoverEnter(),
            child: Container(color: sensorColor),
          ),
        );
      } else if (placement == 'right') {
        sensorWidget = Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 12,
          child: MouseRegion(
            onEnter: (_) => _onDockHoverEnter(),
            child: Container(color: sensorColor),
          ),
        );
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ?sensorWidget,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          child: isHorizontal
              ? Align(
                  alignment: placement == 'bottom'
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  child: dockBody,
                )
              : Align(
                  alignment: placement == 'left'
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: dockBody,
                ),
        ),
      ],
    );
  }
}
