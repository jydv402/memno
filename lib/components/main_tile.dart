import 'package:flutter/material.dart';
import 'package:memno/components/sub_tile.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';

enum Filters { all, liked, empty }

class MainTile extends StatefulWidget {
  const MainTile({super.key});

  @override
  State<MainTile> createState() => _MainTileState();
}

class _MainTileState extends State<MainTile> {
  Filters _filter = Filters.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Consumer<CodeGen>(
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
                  const SizedBox(height: 100),
                  Center(
                    child: Text(
                      _emptyMsg(),
                      style: TextStyle(
                        color: colors.textClr,
                        fontFamily: 'Product',
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 130),
                itemCount: filteredList.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return TopAccentBox(
                      colors: colors,
                      length: filteredList.length,
                      filter: _filter,
                      customToggle: _customToggleButtons(context),
                    );
                  } else if (index == 1) {
                    return subTileSearch(context);
                  } else {
                    final reversedIndex = filteredList.length - index + 1;
                    final code = filteredList[reversedIndex];
                    final date = codeProvider.getDateForCode(code);
                    final isLiked = codeProvider.getLikeForCode(code);
                    return subTile(context, code, date, isLiked);
                  }
                });
      },
    );
  }

  List<int> listFilter(CodeGen codeProvider) {
    switch (_filter) {
      case Filters.all:
        return codeProvider.codeList;
      case Filters.liked:
        return codeProvider.codeList
            .where((element) => codeProvider.getLikeForCode(element))
            .toList();
      case Filters.empty:
        //where
        return codeProvider.codeList
            .where((element) => codeProvider.getLinkListLength(element) == 0)
            .toList();
      default:
        return codeProvider.codeList;
    }
  }

  String _emptyMsg() {
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
    return Container(
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      padding: const EdgeInsets.fromLTRB(26, 0, 4, 0),
      height: 75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: colors.bgClr,
        border: Border.all(color: colors.search),
      ),
      child: TextField(
        controller: _searchController,
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
