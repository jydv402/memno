import 'dart:async';
import 'dart:io' show Platform;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:memno/mobile/pages/inner_page.dart';
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
    // Sort based on the date
    filteredList.sort((a, b) {
      final aDate = DateTime.parse(codeProvider.getDateForCode(a));
      final bDate = DateTime.parse(codeProvider.getDateForCode(b));
      return bDate.compareTo(aDate);
    });

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
          openColor: colors.bgClr,
          middleColor: colors.bgClr,
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
            ? subTileSearch(context)
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

  Widget subTileSearch(BuildContext context) {
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
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
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
              switchSearchMode();
              clearState();
            },
            child: Icon(Icons.close_rounded, color: colors.box),
          ),
        ],
      ),
    );
  }
}

class CustomFAB extends StatelessWidget {
  const CustomFAB({super.key, required this.onSearch});

  final double radius = 50.0;
  final double height = 100.0;
  final double width = 200.0;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (context, _) =>
          InnerPage(code: context.read<CodeGen>().codeList.last),
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius + 10),
      ),
      closedColor: Colors.transparent,
      openColor: colors.bgClr,
      middleColor: colors.bgClr,
      closedBuilder: (context, openContainer) => GlassmorphicContainer(
        width: width,
        height: height,
        alignment: Alignment.center,
        blur: 20,
        borderRadius: radius + 10,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withValues(alpha: 0.1),
            const Color(0xFFFFFFFF).withValues(alpha: 0.05),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withValues(alpha: 0.5),
            const Color((0xFFFFFFFF)).withValues(alpha: 0.5),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                fixedSize: Size(height - 20, height - 20),
              ),
              onPressed: () {
                context.read<CodeGen>().generateCode();
                openContainer();
              },
              child: const Icon(Icons.add_rounded, size: 30),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                fixedSize: Size(height - 20, height - 20),
              ),
              onPressed: onSearch,
              child: const Icon(Icons.search_rounded, size: 30),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class TopAccentBox extends StatelessWidget {
  const TopAccentBox({
    super.key,
    required this.colors,
    required this.length,
    required this.filter,
    required this.customToggle,
  });

  final AppColors colors;
  final int length;
  final Filters filter;
  final Widget customToggle;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      height: colors.isCompactHeader ? width * 0.236 : width * 0.585,
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(50.0)),
        color: colors.accnt,
      ),
      child: Column(
        children: [
          if (!colors.isCompactHeader)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 22),
                    child: Text(
                      "Hi,\nI'm Memno",
                      style: TextStyle(
                        fontFamily: 'GoogleSans',
                        fontWeight: FontWeight.w700,
                        fontSize: width * 0.11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 38),
                    child: Image.asset(
                      'assets/memno_clear_blk.png',
                      height: width * 0.25,
                      width: width * 0.25,
                    ),
                  ),
                ],
              ),
            )
          else
            const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Toggle for All, Liked or Empty
              customToggle,
              // Total number of counts
              Container(
                width: width * 0.26,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: colors.accntPill,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  length == 1 ? '$length Code' : '$length Codes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'GoogleSans',
                    color: colors.accntText,
                  ),
                ),
              ),
            ],
          ),
          if (colors.isCompactHeader) const Spacer(),
          if (!colors.isCompactHeader) SizedBox(height: 16),
        ],
      ),
    );
  }
}
