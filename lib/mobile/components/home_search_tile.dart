import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

class SearchTile extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback onPressed;

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
