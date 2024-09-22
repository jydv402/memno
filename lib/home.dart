import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memno/components/custom_overlay.dart';
import 'package:memno/components/inner_page.dart';
import 'package:memno/components/settings_page.dart';
import 'package:memno/components/show_toast.dart';
import 'package:memno/components/sub_tile.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';

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

  @override
  void initState() {
    super.initState();
    clearState();
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
      default:
        filteredList = codeProvider.codeList;
    }

    if (_searchedCode.isNotEmpty) {
      filteredList = filteredList.where(
        (code) {
          final codeString = code.toString();
          final headString = codeProvider.getHeadForCode(code).toLowerCase();
          final searchCodeLwr = _searchedCode.toLowerCase();
          return codeString.contains(searchCodeLwr) ||
              headString.contains(searchCodeLwr);
        },
      ).toList();
      showToastMsg(context,
          "${filteredList.length} results found for \"$_searchedCode\"");
    }

    return filteredList;
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
      default:
        return "Generate Code to view";
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
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          ),
          icon: const Icon(Icons.menu_rounded),
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
                          fontFamily: 'Product',
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 130),
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
                      final reversedIndex = filteredList.length - index;
                      final code = filteredList[reversedIndex];
                      final date = codeProvider.getDateForCode(code);
                      final isLiked = codeProvider.getLikeForCode(code);
                      return subTile(context, code, date, isLiked);
                    }
                  });
        },
      ),
      floatingActionButton: isSearchBarVisible
          ? subTileSearch(context)
          : CustomFAB(
              onSearch: () {
                switchSearchMode();
                clearState();
              },
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
            padding:
                EdgeInsets.symmetric(horizontal: widthOfToggle, vertical: 19),
            child: const Text('   All   ',
                style: TextStyle(fontFamily: 'Product'))),
        Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widthOfToggle, vertical: 19),
            child:
                const Text('Liked', style: TextStyle(fontFamily: 'Product'))),
        Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widthOfToggle, vertical: 19),
            child:
                const Text('Empty', style: TextStyle(fontFamily: 'Product'))),
      ],
    );
  }

  Widget subTileSearch(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Padding(
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
                onTap: () {
                  setState(() {
                    _searchedCode = '';
                    _searchController.clear();
                  });
                },
                onChanged: (value) {
                  setState(() {
                    _searchedCode = value;
                  });
                },
                maxLines: 1,
                style: TextStyle(
                  color: colors.fgClr,
                  fontFamily: 'Product',
                ),
                decoration: InputDecoration(
                  icon: const Icon(
                    Icons.search_rounded,
                  ),
                  iconColor: colors.search,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Icon(Icons.close_rounded, color: colors.box))
        ],
      ),
    );
  }
}

class CustomFAB extends StatelessWidget {
  const CustomFAB({
    super.key,
    required this.onSearch,
  });

  final double radius = 50.0;
  final double height = 100.0;
  final double width = 200.0;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'fab_to_page',
      child: GlassmorphicContainer(
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
              const Color(0xFFffffff).withOpacity(0.1),
              const Color(0xFFFFFFFF).withOpacity(0.05),
            ],
            stops: const [
              0.1,
              1,
            ]),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFffffff).withOpacity(0.5),
            const Color((0xFFFFFFFF)).withOpacity(0.5),
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
                Navigator.of(context).push(PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return CustomOverlay(
                      child: InnerPage(
                          code: context.read<CodeGen>().codeList.last),
                    );
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.fastLinearToSlowEaseIn,
                        ),
                      ),
                      child: child,
                    );
                  },
                ));
              },
              child: const Icon(
                Icons.add_rounded,
                size: 30,
              ),
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
                child: const Icon(Icons.search_rounded, size: 30)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      child: Stack(
        children: [
          //Main accent container
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(50.0)),
              color: colors.accnt,
            ),
          ),
          //Custom toggle button
          Positioned(
            bottom: 16,
            left: 16,
            child: customToggle,
          ),
          //Intro text
          const Positioned(
              top: 38,
              left: 26,
              child: Text("Hi,\nI'm Memno",
                  style: TextStyle(
                      fontFamily: 'Product',
                      fontWeight: FontWeight.w700,
                      fontSize: 48))),
          //Memno image
          Positioned(
            top: 54,
            right: 24,
            height: 110,
            width: 110,
            child: Image.asset('assets/memno_clear_blk.png'),
          ),
          //Code count
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              width: 130,
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
                  fontFamily: 'Product',
                  color: colors.accntText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
