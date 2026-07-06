import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:memno/mobile/pages/inner_page.dart';
import 'package:memno/mobile/components/show_toast.dart';
import 'package:memno/logic/functionality/code_gen.dart';
import 'package:memno/logic/functionality/preview_map.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:memno/mobile/components/pill_button.dart';

class SubTileStack extends StatefulWidget {
  const SubTileStack({
    super.key,
    required this.code,
    required this.date,
    required this.isLiked,
  });

  final int code;
  final String date;
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
      openColor: colors.bgClr,
      middleColor: colors.bgClr,
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
                          onTap: openContainer,
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
                                        label: getFormattedDate(
                                          DateTime.parse(widget.date),
                                        ),
                                        onPressed: () {},
                                      ),
                                      // Like Button
                                      PillButton(
                                        key: ValueKey(widget.code),
                                        icon: widget.isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        iconColor: widget.isLiked
                                            ? Colors.red
                                            : colors.textClr,
                                        label: widget.isLiked
                                            ? "Liked"
                                            : "Like",
                                        onPressed: () {
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
                                      onTap: openContainer,
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
                          final linksToDelete = codeProvider.getLinksForCode(
                            widget.code,
                          );
                          for (final link in linksToDelete) {
                            previewMap.deletePreviewForLink(link);
                          }
                          codeProvider.clearList(widget.code);
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

class ShowDltPrompt extends StatelessWidget {
  const ShowDltPrompt({
    super.key,
    required this.length,
    required this.radius,
    required this.onProceed,
    required this.onCancel,
  });

  final int length;
  final double radius;
  final VoidCallback onProceed;
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

class ContainerButton extends StatelessWidget {
  const ContainerButton({
    super.key,
    required this.onTap,
    required this.radius,
    required this.text,
  });

  final VoidCallback onTap;
  final double radius;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return InkWell(
      onTap: onTap,
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

class CodeText extends StatelessWidget {
  const CodeText({super.key, required this.code});

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

class HeadText extends StatelessWidget {
  const HeadText({super.key, required this.code});

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

class LengthIndicator extends StatelessWidget {
  const LengthIndicator({
    super.key,
    required this.radius,
    required this.length,
    required this.code,
    required this.onTap,
  });

  final double radius;
  final int length;
  final int code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return InkWell(
      onTap: onTap,
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

const List months = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

String getFormattedDate(DateTime date) {
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'pm' : 'am';
  final hour12 = date.hour == 0
      ? 12
      : date.hour > 12
      ? date.hour - 12
      : date.hour;
  return "${date.day} ${months[date.month - 1]} ${date.year}, $hour12:$minute $suffix";
}
