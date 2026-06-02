import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// A morphing sidebar that transitions between an icon-only rail (56px)
/// and an expanded sidebar (240px) with smooth animations.
class DesktopSidebar extends StatelessWidget {
  /// Whether the sidebar is currently in expanded state.
  final bool isExpanded;

  /// Callback to toggle the expanded/collapsed state.
  final VoidCallback onToggleExpand;

  /// Currently selected destination index.
  /// 0 = All, 1 = Liked, 2 = Empty, 3 = Settings.
  final int selectedIndex;

  /// Callback fired when a destination is tapped.
  final ValueChanged<int> onDestinationChanged;

  /// Callback to open the search overlay.
  final VoidCallback onSearchTap;

  /// Callback to create a new note page.
  final VoidCallback onNewPage;

  const DesktopSidebar({
    super.key,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.selectedIndex,
    required this.onDestinationChanged,
    required this.onSearchTap,
    required this.onNewPage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      width: isExpanded ? 240.0 : 56.0,
      decoration: BoxDecoration(
        color: colors.bgClr,
        border: Border(
          right: BorderSide(
            color: colors.pill.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Top Branding Area ──
          _buildBranding(colors),

          const SizedBox(height: 8),

          // ── Destinations List ──
          _buildDestination(
            colors: colors,
            index: 0,
            label: 'All Notes',
            selectedIcon: Icons.folder,
            unselectedIcon: Icons.folder_outlined,
          ),
          _buildDestination(
            colors: colors,
            index: 1,
            label: 'Liked',
            selectedIcon: Icons.favorite_rounded,
            unselectedIcon: Icons.favorite_border_rounded,
          ),
          _buildDestination(
            colors: colors,
            index: 2,
            label: 'Empty',
            selectedIcon: Icons.folder_off_outlined,
            unselectedIcon: Icons.folder_off_outlined,
          ),
          _buildDestination(
            colors: colors,
            index: 3,
            label: 'Settings',
            selectedIcon: Icons.settings,
            unselectedIcon: Icons.settings_outlined,
          ),

          // ── Spacer ──
          const Spacer(),

          // ── Search Button ──
          _buildActionButton(
            colors: colors,
            icon: Icons.search_rounded,
            label: 'Search',
            backgroundColor: colors.pill,
            foregroundColor: colors.textClr,
            onTap: onSearchTap,
          ),

          const SizedBox(height: 8),

          // ── New Page Button ──
          _buildActionButton(
            colors: colors,
            icon: Icons.add_rounded,
            label: 'New Page',
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onTap: onNewPage,
          ),

          const SizedBox(height: 8),

          // ── Toggle Button ──
          _buildToggleButton(colors),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  Branding
  // ───────────────────────────────────────────────────────────

  Widget _buildBranding(AppColors colors) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isExpanded ? 16.0 : 12.0,
        20.0,
        isExpanded ? 16.0 : 12.0,
        8.0,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            Image.asset(
              'assets/memno_clear_blk.png',
              height: 24,
              width: 24,
              color: colors.isDarkMode ? Colors.white : null,
            ),
            if (isExpanded) ...[
              const SizedBox(width: 10),
              AnimatedOpacity(
                opacity: isExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Memno',
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: colors.textClr,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  Destination Item
  // ───────────────────────────────────────────────────────────

  Widget _buildDestination({
    required AppColors colors,
    required int index,
    required String label,
    required IconData selectedIcon,
    required IconData unselectedIcon,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color bg = isSelected ? colors.accnt : Colors.transparent;
    final Color fg = isSelected ? Colors.black : colors.textClr;
    final IconData icon = isSelected ? selectedIcon : unselectedIcon;

    final Widget tile = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onDestinationChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 12.0 : 0.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 20),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: AnimatedOpacity(
                    opacity: isExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'GoogleSans',
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        color: fg,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final Widget wrappedTile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: tile,
    );

    // When collapsed, show a tooltip so the user still knows what the item is.
    if (!isExpanded) {
      return Tooltip(
        message: label,
        preferBelow: false,
        child: wrappedTile,
      );
    }

    return wrappedTile;
  }

  // ───────────────────────────────────────────────────────────
  //  Action Button (Search / New Page)
  // ───────────────────────────────────────────────────────────

  Widget _buildActionButton({
    required AppColors colors,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
  }) {
    if (isExpanded) {
      // Pill button with icon + label
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: foregroundColor, size: 18),
                      const SizedBox(width: 8),
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'GoogleSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: foregroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Collapsed: icon-only button
    return Tooltip(
      message: label,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: foregroundColor, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  //  Toggle Expand / Collapse Button
  // ───────────────────────────────────────────────────────────

  Widget _buildToggleButton(AppColors colors) {
    return Tooltip(
      message: isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
      preferBelow: false,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedRotation(
            turns: isExpanded ? 0.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.chevron_left,
              color: colors.iconClr,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
