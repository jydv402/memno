import 'package:flutter/material.dart';
import 'package:memno/components/inner_page.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';

Widget subTile(BuildContext context, int code, String date, bool isLiked) {
  int length = context.read<CodeGen>().getLinkListLength(code);
  double radius = 50;

  return Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
    child: SubTileStack(
        code: code,
        date: date,
        isLiked: isLiked,
        length: length,
        radius: radius),
  );
}

class SubTileStack extends StatefulWidget {
  const SubTileStack(
      {super.key,
      required this.code,
      required this.date,
      required this.isLiked,
      required this.length,
      required this.radius});

  final int code;
  final String date;
  final bool isLiked;
  final int length;
  final double radius;

  @override
  State<SubTileStack> createState() => _SubTileStackState();
}

class _SubTileStackState extends State<SubTileStack> {
  bool showDltConfirm = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //Background Container
        BgContainer(
            radius: widget.radius,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InnerPage(code: widget.code),
                ),
              );
            }),
        if (!showDltConfirm) ...[
          //Code Text
          CodeText(code: widget.code),
          //Length indicator
          LengthIndicator(
            radius: widget.radius,
            length: widget.length,
            code: widget.code,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InnerPage(code: widget.code),
                ),
              );
            },
          ),
          //Date Time Indicator
          DateTimeIndicator(date: widget.date),
          //Like Button
          LikeButton(code: widget.code, isLiked: widget.isLiked),
          //Delete Button
          DltButton(
            code: widget.code,
            onPressed: () {
              setState(() {
                showDltConfirm = true;
              });
            },
          ),
        ] else ...[
          ShowDltPrompt(
            length: widget.length,
            radius: widget.radius,
            onProceed: () {
              context.read<CodeGen>().clearList(widget.code);
              setState(() {
                showDltConfirm = false;
              });
            },
            onCancel: () {
              setState(() {
                showDltConfirm = false;
              });
            },
          )
        ]
      ],
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
          Text("You sure you want to delete?\nCurrently contains $length items",
              style: TextStyle(
                  color: colors.textClr, fontSize: 16, fontFamily: 'Product'),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ContainerButton(onTap: onCancel, radius: radius, text: "No"),
              const SizedBox(width: 20),
              ContainerButton(onTap: onProceed, radius: radius, text: "Yes"),
            ],
          )
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
    return GestureDetector(
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
            style: TextStyle(color: colors.textClr, fontFamily: 'Product'),
          )),
    );
  }
}

class BgContainer extends StatelessWidget {
  const BgContainer({
    super.key,
    required this.radius,
    required this.onTap,
  });

  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: colors.box,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class CodeText extends StatelessWidget {
  const CodeText({
    super.key,
    required this.code,
  });

  final int code;
  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Positioned(
      bottom: 16,
      left: 26,
      child: SelectableText(
        "#$code",
        style: TextStyle(
            color: colors.textClr,
            fontSize: 28,
            fontWeight: FontWeight.w400,
            fontFamily: 'Product'),
        textAlign: TextAlign.center,
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
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.pill,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_outward_rounded,
                  color: colors.iconClr, size: 14),
              const Spacer(),
              Text(
                length == 1 ? "$length  Entry" : "$length Entries",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Product',
                  color: colors.textClr,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class DateTimeIndicator extends StatelessWidget {
  const DateTimeIndicator({
    super.key,
    required this.date,
  });

  final String date;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Positioned(
        top: 28,
        left: 26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: colors.iconClr,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              getFormattedDate(DateTime.parse(date)),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textClr, fontFamily: 'Product'),
            ),
          ],
        ));
  }
}

class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.code,
    required this.isLiked,
  });

  final int code;
  final bool isLiked;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Positioned(
      right: 84,
      top: 16,
      child: ElevatedButton(
        key: ValueKey(code),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.btnClr,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        onPressed: () {
          context.read<CodeGen>().toggleLike(code);
        },
        child: isLiked == true
            ? const Icon(Icons.favorite_rounded, color: Colors.red)
            : Icon(Icons.favorite_border_rounded, color: colors.btnIcon),
      ),
    );
  }
}

class DltButton extends StatelessWidget {
  const DltButton({
    super.key,
    required this.code,
    required this.onPressed,
  });

  final int code;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Positioned(
      right: 14,
      top: 16,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.btnClr,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          onPressed: onPressed,
          child: Icon(Icons.close_rounded, color: colors.btnIcon)),
    );
  }
}

class DeleteConfirmation extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DeleteConfirmation(
      {super.key, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to delete this item?',
            style: TextStyle(
                color: colors.textClr,
                fontWeight: FontWeight.bold,
                fontFamily: 'Product'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(backgroundColor: colors.pill),
                child: Text(
                  'Cancel',
                  style:
                      TextStyle(color: colors.textClr, fontFamily: 'Product'),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(backgroundColor: colors.pill),
                child: Text(
                  'Delete',
                  style:
                      TextStyle(color: colors.textClr, fontFamily: 'Product'),
                ),
              ),
            ],
          ),
        ],
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
  if (date.hour > 12) {
    return "${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour - 12}:${date.minute} pm";
  } else {
    return "${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour}:${date.minute} am";
  }
}
