import 'dart:async';
import 'dart:io' show Platform;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:memno/mobile/components/home_search_tile.dart';
import 'package:memno/mobile/components/navigation/home_custom_fab.dart';
import 'package:memno/mobile/components/home_top_accent_box.dart';
import 'package:memno/mobile/pages/settings_page.dart';
import 'package:memno/mobile/pages/share_target_page.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/mobile/components/sub_tile.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/main.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:memno/logic/functionality/check_update.dart';

enum Filters { all, liked, empty }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Filters _filter = Filters.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchedCode = '';
  bool isSearchBarVisible = false;
  Timer? _debounceTimer;
  StreamSubscription? _shareSubscription;

  @override
  void initState() {
    super.initState();
    clearState();
    _initShareIntent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
  }

  void _checkForUpdates() async {
    if (mounted) {
      await checkAppUpdate(context, false);
    }
  }

  void _initShareIntent() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // Handle shares received while app is running
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        final sharedText = value.first.path;
        if (sharedText.isNotEmpty) {
          _navigateToShareTarget(sharedText);
        }
      }
    });

    // Handle shares that launched the app (cold start)
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        final sharedText = value.first.path;
        if (sharedText.isNotEmpty) {
          _navigateToShareTarget(sharedText);
        }
      }
    });
  }

  void _navigateToShareTarget(String sharedText) {
    // Use the global navigatorKey so we can navigate even during init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ShareTargetPage(sharedText: sharedText),
        ),
      );
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void switchSearchMode() {
    setState(() {
      isSearchBarVisible = !isSearchBarVisible;
    });
  }

  void clearState() {
    setState(() {
      _searchController.clear();
      _searchedCode = '';
    });
  }

  List<int> listFilter(CodeGen codeProvider) {
    List<int> filteredList;
    switch (_filter) {
      case Filters.all:
        filteredList = codeProvider.codeList;
      case Filters.liked:
        filteredList = codeProvider.codeList
            .where((element) => codeProvider.getLikeForCode(element))
            .toList();
      case Filters.empty:
        filteredList = codeProvider.codeList
            .where((element) => codeProvider.getLinkListLength(element) == 0)
            .toList();
    }

    if (_searchedCode.isNotEmpty) {
      filteredList = filteredList.where((code) {
        final codeString = code.toString();
        final headString = codeProvider.getHeadForCode(code).toLowerCase();
        final searchCodeLwr = _searchedCode.toLowerCase();
        return codeString.contains(searchCodeLwr) ||
            headString.contains(searchCodeLwr);
      }).toList();
    }
    // Sort based on the date using Schwartzian transform (cache parses)
    final parsedDates = <int, DateTime>{};
    for (final code in filteredList) {
      final dateStr = codeProvider.getDateForCode(code);
      parsedDates[code] =
          DateTime.tryParse(dateStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    filteredList.sort((a, b) => parsedDates[b]!.compareTo(parsedDates[a]!));

    return filteredList;
  }

  /// Search function
  ///
  /// Uses a debounce timer to prevent too many UI rebuilds
  /// Current debounce time is 300ms
  void _onSearch(String searchQuery) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchedCode = searchQuery;
      });

      if (searchQuery.isNotEmpty) {
        // Temporary filter run
        // Computed just to get the count for toast
        // Heavy, might remove later
        final codeProvider = context.read<CodeGen>();
        final results = listFilter(codeProvider);

        showToastMsg(
          context,
          "${results.length} results found for \"$searchQuery\"",
        );
      }
    });
  }

  String _emptyMsg() {
    if (_searchedCode.isNotEmpty) {
      return "No results found for \"$_searchedCode\"";
    }
    switch (_filter) {
      case Filters.all:
        return "Generate Code to view";
      case Filters.liked:
        return "No liked codes";
      case Filters.empty:
        return "No empty codes";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Scaffold(
      backgroundColor: colors.bgClr,
      appBar: AppBar(
        backgroundColor: colors.bgClr,
        foregroundColor: colors.fgClr,
        surfaceTintColor: colors.bgClr,
        // Settings button
        // Show the animation to the settings page
        leading: OpenContainer(
          transitionType: ContainerTransitionType.fade,
          openBuilder: (context, _) => const SettingsPage(),
          closedElevation: 0,
          closedColor: Colors.transparent,
          openColor: Theme.of(context).scaffoldBackgroundColor,
          middleColor: Theme.of(context).scaffoldBackgroundColor,
          closedBuilder: (context, openContainer) => IconButton(
            onPressed: openContainer,
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
      ),
      body: Consumer<CodeGen>(
        builder: (context, codeProvider, child) {
          if (!codeProvider.isReady) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredList = listFilter(codeProvider);

          return filteredList.isEmpty
              ? ListView(
                  children: [
                    TopAccentBox(
                      colors: colors,
                      length: filteredList.length,
                      filter: _filter,
                      customToggle: _customToggleButtons(context),
                    ),
                    const SizedBox(height: 50),
                    Center(
                      child: Text(
                        _emptyMsg(),
                        style: TextStyle(
                          color: colors.textClr,
                          fontFamily: 'GoogleSans',
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  ],
                )
              : ListView.builder(
                  padding: .only(
                    bottom: MediaQuery.of(context).size.height * 0.40,
                  ),
                  itemCount: filteredList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return TopAccentBox(
                        colors: colors,
                        length: filteredList.length,
                        filter: _filter,
                        customToggle: _customToggleButtons(context),
                      );
                    } else {
                      final code = filteredList[index - 1];
                      final date = codeProvider.getDateForCode(code);
                      final isLiked = codeProvider.getLikeForCode(code);
                      return SubTileStack(
                        code: code,
                        date: date,
                        isLiked: isLiked,
                      );
                    }
                  },
                );
        },
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: isSearchBarVisible
            ? SearchTile(
                searchController: _searchController,
                onSearch: _onSearch,
                onPressed: () {
                  switchSearchMode();
                  clearState();
                },
              )
            : CustomFAB(
                key: const ValueKey('fabToggle'),
                onSearch: () {
                  switchSearchMode();
                  clearState();
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _customToggleButtons(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    final widthOfToggle = MediaQuery.of(context).size.width * 0.05;
    return ToggleButtons(
      borderColor: Colors.black,
      selectedBorderColor: Colors.black,
      selectedColor: colors.accntText,
      fillColor: colors.accntPill,
      color: Colors.black,
      direction: Axis.horizontal,
      onPressed: (int index) {
        setState(() {
          _filter = Filters.values[index];
        });
      },
      borderRadius: BorderRadius.circular(50),
      isSelected: Filters.values.map((e) => e == _filter).toList(),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widthOfToggle,
            vertical: 19,
          ),
          child: const Text(
            '   All   ',
            style: TextStyle(fontFamily: 'GoogleSans'),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widthOfToggle,
            vertical: 19,
          ),
          child: const Text(
            'Liked',
            style: TextStyle(fontFamily: 'GoogleSans'),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widthOfToggle,
            vertical: 19,
          ),
          child: const Text(
            'Empty',
            style: TextStyle(fontFamily: 'GoogleSans'),
          ),
        ),
      ],
    );
  }
}
