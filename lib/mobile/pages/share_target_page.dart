import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memno/mobile/pages/inner_page.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/mobile/components/haptic_app_bar.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

/// Page shown when the user shares text/link from another app.
/// Lists all existing code pages and lets the user pick one or create a new one.
class ShareTargetPage extends StatefulWidget {
  final String sharedText;

  const ShareTargetPage({super.key, required this.sharedText});

  @override
  State<ShareTargetPage> createState() => _ShareTargetPageState();
}

class _ShareTargetPageState extends State<ShareTargetPage> {
  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _sharedTextController;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _sharedTextController = TextEditingController(text: widget.sharedText);
  }

  void _onSearch(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  List<int> _filteredCodes(CodeGen codeProvider) {
    List<int> codes = List.from(codeProvider.codeList);

    if (_searchQuery.isNotEmpty) {
      codes = codes.where((code) {
        final codeString = code.toString();
        final headString = codeProvider.getHeadForCode(code).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return codeString.contains(query) || headString.contains(query);
      }).toList();
    }

    // Sort by date, most recent first (Schwartzian transform)
    final parsedDates = <int, DateTime>{};
    for (final code in codes) {
      final dateStr = codeProvider.getDateForCode(code);
      parsedDates[code] = DateTime.tryParse(dateStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    codes.sort((a, b) => parsedDates[b]!.compareTo(parsedDates[a]!));

    return codes;
  }

  void _saveToCode(int code) {
    if (_sharedTextController.text.isEmpty) return;
    context.read<CodeGen>().addLink(code, _sharedTextController.text);
    showToastMsg(context, "Saved to #$code");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => InnerPage(code: code)),
    );
  }

  void _createNewAndSave() {
    Provider.of<AppSettings>(context, listen: false).triggerHaptic();
    if (_sharedTextController.text.isEmpty) return;
    final codeProvider = context.read<CodeGen>();
    codeProvider.generateCode();
    final newCode = codeProvider.codeList.last;
    codeProvider.addLink(newCode, _sharedTextController.text);
    showToastMsg(context, "Saved to new code #$newCode");

    // Replace this page with InnerPage for the new code
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => InnerPage(code: newCode)),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _sharedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Scaffold(
      backgroundColor: colors.bgClr,
      appBar: HapticAppBar(
        backgroundColor: colors.bgClr,
        foregroundColor: colors.fgClr,
        surfaceTintColor: colors.bgClr,
        title: const Text(
          "Save to…",
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<CodeGen>(
        builder: (context, codeProvider, child) {
          if (!codeProvider.isReady) {
            return const Center(child: CircularProgressIndicator());
          }

          final codes = _filteredCodes(codeProvider);

          return Column(
            children: [
              // Shared content preview card
              _SharedContentCard(
                controller: _sharedTextController,
                colors: colors,
              ),

              const SizedBox(height: 8),

              // Search bar
              _SearchBar(
                controller: _searchController,
                onChanged: _onSearch,
                colors: colors,
              ),

              const SizedBox(height: 8),

              // Code page list
              Expanded(
                child: codes.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? "No results for \"$_searchQuery\""
                              : "No code pages yet",
                          style: TextStyle(
                            color: colors.textClr,
                            fontFamily: 'GoogleSans',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: codes.length,
                        itemBuilder: (context, index) {
                          final code = codes[index];
                          final head = codeProvider.getHeadForCode(code);
                          final date = codeProvider.getDateForCode(code);
                          final entryCount = codeProvider.getLinkListLength(
                            code,
                          );

                          return _CodePageTile(
                            code: code,
                            head: head,
                            date: date,
                            entryCount: entryCount,
                            colors: colors,
                            onTap: () => _saveToCode(code),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      // Bottom FAB — Create New + Search
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _createNewAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accnt,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                "Create New",
                style: TextStyle(fontFamily: 'GoogleSans', fontSize: 16),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Card showing the shared content at the top of the page.
class _SharedContentCard extends StatelessWidget {
  final TextEditingController controller;
  final AppColors colors;

  const _SharedContentCard({required this.controller, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: colors.accnt,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shared content",
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 1,
            style: const TextStyle(
              fontFamily: 'GoogleSans',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search bar for filtering code pages.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppColors colors;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 60,
      decoration: BoxDecoration(
        color: colors.box,
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: colors.fgClr, fontFamily: 'GoogleSans'),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: colors.search),
          hintText: "Search code pages…",
          hintStyle: TextStyle(
            color: colors.textClr.withValues(alpha: 0.5),
            fontFamily: 'GoogleSans',
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

/// A single code page tile in the list.
class _CodePageTile extends StatelessWidget {
  final int code;
  final String head;
  final String date;
  final int entryCount;
  final AppColors colors;
  final VoidCallback onTap;

  const _CodePageTile({
    required this.code,
    required this.head,
    required this.date,
    required this.entryCount,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Provider.of<AppSettings>(context, listen: false).triggerHaptic();
        onTap();
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        decoration: BoxDecoration(
          color: colors.box,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            // Code number badge
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "#",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'GoogleSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Title + code number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    head,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textClr,
                      fontFamily: 'GoogleSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "#$code · $entryCount ${entryCount == 1 ? 'entry' : 'entries'}",
                    style: TextStyle(
                      color: colors.textClr.withValues(alpha: 0.6),
                      fontFamily: 'GoogleSans',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_rounded,
              color: colors.iconClr.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
