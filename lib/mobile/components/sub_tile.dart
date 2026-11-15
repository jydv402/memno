import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:memno/mobile/pages/inner_page.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/date_utils.dart';
import 'package:memno/logic/functionality/note_operations.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

import 'package:memno/mobile/components/pill_button.dart';

/// The home-screen note tile: the open-container card that opens a note
/// page when tapped, and hosts the delete-confirm swap.
///
/// [SubTileStack] renders one note as a rounded card holding an action
/// pill bar (formatted date, like toggle, delete), the note title, the
/// `#code`, and an entry-count badge that also opens the page. Tapping
/// the card body plays an open-container transition to [InnerPage]. The
/// delete action swaps the whole card for [ShowDltPrompt], which cascades
/// the deletion through [deleteNoteWithPreviews] on confirmation.
class SubTileStack extends StatefulWidget {
  /// Creates the tile for note page [code]; [date] and [isLiked] come
  /// from the note record snapshot the list passed down.
  const SubTileStack({
    super.key,
    required this.code,
    required this.date,
    required this.isLiked,
  });

  /// Six-digit code of the note page this tile represents.
  final int code;

  /// Raw stored date string of the note; parsed for display with
  /// [formatNoteDate], so it must be a `DateTime.toString()` value.
  final String date;

  /// Whether the note is currently favorited, deciding the heart icon
  /// and label until the like toggle notifies the provider.
  final bool isLiked;

  @override
  State<SubTileStack> createState() => _SubTileStackState();
}

class _SubTileStackState extends State<SubTileStack> {
  bool showDltConfirm = false;

  @override
  Widget build(BuildContext context) {
    int length = context.read<CodeGen>().getLinkListLength(widget.code);
    double radius = 50;
    final colors = Provider.of<AppColors>(context);

    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      openBuilder: (context, _) => InnerPage(code: widget.code),
      closedElevation: 0,
      closedColor: Colors.transparent,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      middleColor: Theme.of(context).scaffoldBackgroundColor,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      closedBuilder: (context, openContainer) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: colors.box,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: !showDltConfirm
                    ? ClipRRect(
                        key: const ValueKey('content_card'),
                        borderRadius: BorderRadius.circular(radius),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(radius),
                          onTap: () {
                            Provider.of<AppSettings>(
                              context,
                              listen: false,
                            ).triggerHaptic();
                            openContainer();
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 24,
                            children: [
                              // Row 1: Action Bar (Date, Like, Delete)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      const SizedBox(width: 12),
                                      // Date Display
                                      PillButton(
                                        icon: Icons.calendar_month_outlined,
                                        label: formatNoteDate(
                                          DateTime.parse(widget.date),
                                        ),
                                        onPressed: () {
                                          Provider.of<AppSettings>(
                                            context,
                                            listen: false,
                                          ).triggerHaptic();
                                        },
                                      ),
                                      // Like Button
                                      PillButton(
                                        key: ValueKey(widget.code),
                                        icon: widget.isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        iconColor: widget.isLiked
                                            ? colors.likeClr
                                            : colors.textClr,
                                        label: widget.isLiked
                                            ? "Liked"
                                            : "Like",
                                        onPressed: () {
                                          Provider.of<AppSettings>(
                                            context,
                                            listen: false,
                                          ).triggerHaptic();
                                          context.read<CodeGen>().toggleLike(
                                            widget.code,
                                          );
                                          if (widget.isLiked) {
                                            showToastMsg(
                                              context,
                                              "#${widget.code} removed from favorites",
                                            );
                                          } else {
                                            showToastMsg(
                                              context,
                                              "#${widget.code} added to favorites",
                                            );
                                          }
                                        },
                                      ),
                                      // Delete Button
                                      PillButton(
                                        icon: Icons.delete_outline_rounded,
                                        label: "Delete",
                                        onPressed: () {
                                          Provider.of<AppSettings>(
                                            context,
                                            listen: false,
                                          ).triggerHaptic();
                                          setState(() {
                                            showDltConfirm = true;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 26),
                                    ],
                                  ),
                                ),
                              ),
                              // Row 2: HeadText
                              HeadText(code: widget.code),
                              // Row 3: CodeText and LengthIndicator
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: CodeText(code: widget.code),
                                    ),
                                    const SizedBox(width: 8),
                                    LengthIndicator(
                                      radius: radius,
                                      length: length,
                                      code: widget.code,
                                      onTap: () {
                                        Provider.of<AppSettings>(
                                          context,
                                          listen: false,
                                        ).triggerHaptic();
                                        openContainer();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ShowDltPrompt(
                        key: const ValueKey('delete_prompt'),
                        length: length,
                        radius: radius,
                        onProceed: () {
                          final codeProvider = context.read<CodeGen>();
                          final previewMap = context.read<PreviewMap>();
                          deleteNoteWithPreviews(
                            codeProvider,
                            previewMap,
                            widget.code,
                          );
                          setState(() {
                            showDltConfirm = false;
                          });
                          showToastMsg(context, "Code #${widget.code} deleted");
                        },
                        onCancel: () {
                          setState(() {
                            showDltConfirm = false;
                          });
                          showToastMsg(context, "Action cancelled");
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The in-tile delete confirmation, replacing the card content while
/// active.
///
/// [ShowDltPrompt] asks the user to confirm with the current item count
/// visible, and offers No and Yes buttons rendered as [ContainerButton]s.
/// The caller keeps the card state and reacts through [onProceed] (run
/// the delete cascade) and [onCancel] (restore the card).
class ShowDltPrompt extends StatelessWidget {
  /// Creates the prompt; [length] and [radius] style the message and
  /// buttons, the callbacks decide the outcome.
  const ShowDltPrompt({
    super.key,
    required this.length,
    required this.radius,
    required this.onProceed,
    required this.onCancel,
  });

  /// Current entry count of the note, shown in the warning text so the
  /// user knows how much they are deleting.
  final int length;

  /// Corner radius passed through to the No and Yes buttons so they
  /// match the card's pill shape.
  final double radius;

  /// Invoked by the Yes button after the haptic; performs the deletion.
  final VoidCallback onProceed;

  /// Invoked by the No button after the haptic; restores the card.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "You sure you want to delete?\nCurrently contains $length items",
            style: TextStyle(
              color: colors.textClr,
              fontSize: 16,
              fontFamily: 'GoogleSans',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ContainerButton(onTap: onCancel, radius: radius, text: "No"),
              const SizedBox(width: 20),
              ContainerButton(onTap: onProceed, radius: radius, text: "Yes"),
            ],
          ),
        ],
      ),
    );
  }
}

/// A rounded filled button with centered text, sized for dialog rows.
///
/// [ContainerButton] is the Yes/No button of [ShowDltPrompt]: a
/// 120-logical-pixel-wide pill in the palette's pill color whose tap
/// fires a light haptic through [AppSettings] before [onTap].
class ContainerButton extends StatelessWidget {
  /// Creates the button with its tap action, corner radius, and label.
  const ContainerButton({
    super.key,
    required this.onTap,
    required this.radius,
    required this.text,
  });

  /// Action performed after the haptic fires.
  final VoidCallback onTap;

  /// Corner radius of the pill in logical pixels.
  final double radius;

  /// Button label, typically `Yes` or `No`.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return InkWell(
      onTap: () {
        Provider.of<AppSettings>(context, listen: false).triggerHaptic();
        onTap();
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.pill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textClr, fontFamily: 'GoogleSans'),
        ),
      ),
    );
  }
}

/// The selectable `#code` line of the note tile, in large type.
///
/// [CodeText] renders the note code as `#NNNNNN` in a selectable text so
/// users can long-press-copy it straight from the home grid.
class CodeText extends StatelessWidget {
  /// Creates the display for [code].
  const CodeText({super.key, required this.code});

  /// Six-digit note code rendered after a `#` prefix.
  final int code;
  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return SelectableText(
      "#$code",
      style: TextStyle(
        color: colors.textClr,
        fontSize: 26,
        fontWeight: FontWeight.w400,
        fontFamily: 'GoogleSans',
      ),
      textAlign: TextAlign.start,
    );
  }
}

/// The note title line of the tile, read live from the note provider.
///
/// [HeadText] subscribes to [CodeGen] and renders the current title of
/// [code] at 36 px in a single horizontal-scrolling line, so long titles
/// scroll instead of wrapping the card.
class HeadText extends StatelessWidget {
  /// Creates the title display for note page [code].
  const HeadText({super.key, required this.code});

  /// Six-digit code whose title is read from [CodeGen] on every build.
  final int code;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    String head = Provider.of<CodeGen>(context).getHeadForCode(code);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Text(
        "\t\t\t$head\t\t\t",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textClr,
          fontSize: 36,
          fontWeight: FontWeight.w500,
          fontFamily: 'GoogleSans',
        ),
      ),
    );
  }
}

/// The pill-shaped entry-count badge that doubles as an open-page button.
///
/// [LengthIndicator] shows how many entries the note holds (singular and
/// plural handled) with an outward-arrow icon, and opens the note page
/// on tap after a light haptic fires through [AppSettings].
class LengthIndicator extends StatelessWidget {
  /// Creates the badge for note page [code].
  const LengthIndicator({
    super.key,
    required this.radius,
    required this.length,
    required this.code,
    required this.onTap,
  });

  /// Diameter of the circular badge in logical pixels.
  final double radius;

  /// Entry count displayed inside the badge.
  final int length;

  /// Six-digit code of the note page the badge belongs to; the badge's
  /// own rendering shows only [length], and the page identity is kept on
  /// the widget so callers can key and reason about it.
  final int code;

  /// Invoked after the haptic when the badge is tapped; opens the page.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return InkWell(
      onTap: () {
        Provider.of<AppSettings>(context, listen: false).triggerHaptic();
        onTap();
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.pill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_outward_rounded, color: colors.iconClr, size: 14),
            const Spacer(),
            Text(
              length == 1 ? "$length  Entry" : "$length Entries",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'GoogleSans', color: colors.textClr),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
