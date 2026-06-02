import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memno/desktop/components/desktop_notification.dart';
import 'package:memno/desktop/components/note_card.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desktop note detail page with a responsive masonry-style card grid.
///
/// Shows note title, entries as [NoteCard] widgets in a [Wrap]-based
/// responsive layout, and a floating input bar at the bottom for adding
/// or editing entries.
class DesktopNotePage extends StatefulWidget {
  /// The 6-digit note page code.
  final int code;

  /// Callback to return to the grid home view.
  final VoidCallback onBack;

  const DesktopNotePage({
    super.key,
    required this.code,
    required this.onBack,
  });

  @override
  State<DesktopNotePage> createState() => _DesktopNotePageState();
}

class _DesktopNotePageState extends State<DesktopNotePage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  /// 0 = add new, 1 = edit existing entry, 2 = edit title
  int _editMode = 0;

  /// Index of the entry being edited (only for _editMode == 1).
  int _editIndex = -1;

  /// Whether the input bar is visible.
  bool _showInputBar = false;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────
  //  Action Handlers
  // ───────────────────────────────────────────────────────────

  void _startAddEntry() {
    setState(() {
      _editMode = 0;
      _editIndex = -1;
      _inputController.clear();
      _showInputBar = true;
    });
    _inputFocusNode.requestFocus();
  }

  void _startEditEntry(int index, String currentText) {
    setState(() {
      _editMode = 1;
      _editIndex = index;
      _inputController.text = currentText;
      _showInputBar = true;
    });
    _inputFocusNode.requestFocus();
  }

  void _startEditTitle(String currentTitle) {
    setState(() {
      _editMode = 2;
      _editIndex = -1;
      _inputController.text = currentTitle;
      _showInputBar = true;
    });
    _inputFocusNode.requestFocus();
  }

  void _confirmInput() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final codeProvider = context.read<CodeGen>();

    switch (_editMode) {
      case 0:
        // Add new entry
        codeProvider.addLink(widget.code, text);
        showDesktopNotification(context, 'Entry added');
      case 1:
        // Edit existing entry
        codeProvider.editLink(widget.code, _editIndex, text);
        showDesktopNotification(context, 'Entry updated');
      case 2:
        // Edit title
        codeProvider.addHead(widget.code, text);
        showDesktopNotification(context, 'Title updated');
    }

    setState(() {
      _showInputBar = false;
      _inputController.clear();
      _editMode = 0;
      _editIndex = -1;
    });
  }

  void _cancelInput() {
    setState(() {
      _showInputBar = false;
      _inputController.clear();
      _editMode = 0;
      _editIndex = -1;
    });
  }

  void _copyEntry(String content) {
    Clipboard.setData(ClipboardData(text: content));
    showDesktopNotification(context, 'Copied to clipboard');
  }

  void _shareEntry(String content) {
    SharePlus.instance.share(ShareParams(text: content));
  }

  void _deleteEntry(int index, String content) {
    final colors = Provider.of<AppColors>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.box,
        title: Text(
          'Delete Entry',
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 20,
            color: colors.textClr,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this entry?',
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 16,
            color: colors.textClr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                color: colors.textClr,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final codeProvider = context.read<CodeGen>();
              final previewMap = context.read<PreviewMap>();
              codeProvider.deleteLink(widget.code, index);
              previewMap.deletePreviewForLink(content);
              showDesktopNotification(context, 'Entry deleted');
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'GoogleSans',
                color: Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isUrl(String text) {
    final firstWord = text.split(' ').first;
    return AnyLinkPreview.isValidLink(firstWord);
  }

  // ───────────────────────────────────────────────────────────
  //  Build
  // ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return Consumer2<CodeGen, PreviewMap>(
      builder: (context, codeProvider, previewMap, _) {
        final links = codeProvider.getLinksForCode(widget.code);
        final title = codeProvider.getHeadForCode(widget.code);

        return Stack(
          children: [
            Column(
              children: [
                // ── Top Bar ──
                _buildTopBar(colors, title),

                // ── Content Grid ──
                Expanded(
                  child: links.isEmpty
                      ? _buildEmptyState(colors)
                      : _buildGrid(colors, links),
                ),

                // Reserve space for input bar
                if (_showInputBar) const SizedBox(height: 80),
              ],
            ),

            // ── Floating Input Bar ──
            if (_showInputBar) _buildInputBar(colors),

            // ── FAB to add entry (when input bar is hidden) ──
            if (!_showInputBar)
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  backgroundColor: colors.accnt,
                  foregroundColor: Colors.black,
                  onPressed: _startAddEntry,
                  child: const Icon(Icons.add_rounded),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(AppColors colors, String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.accnt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black,
            onPressed: widget.onBack,
            tooltip: 'Back to grid',
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: GestureDetector(
              onDoubleTap: () => _startEditTitle(title),
              child: Text(
                title.isNotEmpty ? title : 'Untitled Note',
                style: const TextStyle(
                  fontFamily: 'GoogleSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Edit title button
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            color: Colors.black54,
            onPressed: () => _startEditTitle(title),
            tooltip: 'Edit title',
          ),

          // Like button
          Consumer<CodeGen>(
            builder: (context, codeProvider, _) {
              final isLiked = codeProvider.getLikeForCode(widget.code);
              return IconButton(
                icon: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                ),
                color: isLiked ? Colors.red : Colors.black54,
                onPressed: () {
                  codeProvider.toggleLike(widget.code);
                  showDesktopNotification(
                    context,
                    isLiked ? 'Removed from liked' : 'Added to liked',
                  );
                },
                tooltip: isLiked ? 'Unlike' : 'Like',
              );
            },
          ),

          const SizedBox(width: 4),

          // Code badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${widget.code}',
              style: const TextStyle(
                fontFamily: 'GoogleSans',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: colors.textClr.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No entries yet.\nAdd your first link or note.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 16,
              color: colors.textClr.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(AppColors colors, List<String> links) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = (availableWidth / 320).floor().clamp(1, 4);
        final cardWidth = (availableWidth - 48 - ((columns - 1) * 16)) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(links.length, (index) {
              final content = links[index];
              final isUrl = _isUrl(content);

              return SizedBox(
                width: cardWidth.clamp(280, 600).toDouble(),
                child: NoteCard(
                  index: index + 1,
                  content: content,
                  isUrl: isUrl,
                  onEdit: () => _startEditEntry(index, content),
                  onCopy: () => _copyEntry(content),
                  onShare: () => _shareEntry(content),
                  onDelete: () => _deleteEntry(index, content),
                  onTapUrl: isUrl ? () => _openUrl(content) : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildInputBar(AppColors colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = (screenWidth - 100).clamp(300.0, 600.0);

    String hintText;
    IconData confirmIcon;
    Color confirmColor;

    switch (_editMode) {
      case 0:
        hintText = 'Add a link or note...';
        confirmIcon = Icons.check_rounded;
        confirmColor = const Color(0xFF4CAF50);
      case 1:
        hintText = 'Edit entry...';
        confirmIcon = Icons.check_rounded;
        confirmColor = const Color(0xFF2196F3);
      case 2:
        hintText = 'Edit title...';
        confirmIcon = Icons.check_rounded;
        confirmColor = const Color(0xFFFF9800);
      default:
        hintText = 'Type here...';
        confirmIcon = Icons.check_rounded;
        confirmColor = const Color(0xFF4CAF50);
    }

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: barWidth,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bgClr,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.pill.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Input field
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(
                      LogicalKeyboardKey.enter,
                      control: true,
                    ): _confirmInput,
                    const SingleActivator(LogicalKeyboardKey.escape):
                        _cancelInput,
                  },
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    maxLines: null,
                    style: TextStyle(
                      fontFamily: 'GoogleSans',
                      fontSize: 14,
                      color: colors.textClr,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        fontFamily: 'GoogleSans',
                        fontSize: 14,
                        color: colors.textClr.withValues(alpha: 0.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // Confirm button
              IconButton(
                icon: Icon(confirmIcon, color: confirmColor),
                onPressed: _confirmInput,
                tooltip: 'Confirm (Ctrl+Enter)',
              ),

              // Cancel button
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade400,
                ),
                onPressed: _cancelInput,
                tooltip: 'Cancel (Esc)',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
