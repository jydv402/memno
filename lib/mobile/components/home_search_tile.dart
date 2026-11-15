import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

/// The mobile search-by-code row: an autofocused code field plus a round
/// close button that exits search mode.
///
/// [SearchTile] is the only text input on the home screen; every keystroke
/// goes to [onSearch] which filters the note list live. The close button
/// fires a light haptic through [AppSettings] and then invokes [onPressed],
/// which the home page uses to collapse back to the FAB.
class SearchTile extends StatelessWidget {
  /// Controller owning the query text; the parent clears it on exit.
  final TextEditingController searchController;

  /// Called with the current text on every keystroke.
  final Function(String) onSearch;

  /// Called after the haptic when the close button is tapped.
  final VoidCallback onPressed;

  /// Creates the search row; all three parameters are required.
  const SearchTile({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Padding(
      key: const ValueKey('searchBar'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
              padding: const EdgeInsets.fromLTRB(26, 0, 4, 0),
              height: 75,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: colors.box,
                border: Border.all(color: colors.search),
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: onSearch,
                maxLines: 1,
                style: TextStyle(color: colors.fgClr, fontFamily: 'GoogleSans'),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search_rounded),
                  iconColor: colors.search,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.search,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(25),
            ),
            onPressed: () {
              Provider.of<AppSettings>(context, listen: false).triggerHaptic();
              onPressed();
            },
            child: Icon(Icons.close_rounded, color: colors.box),
          ),
        ],
      ),
    );
  }
}
