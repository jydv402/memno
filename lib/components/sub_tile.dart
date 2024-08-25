import 'package:flutter/material.dart';
import 'package:memno/components/inner_page.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:provider/provider.dart';

Widget subTile(BuildContext context, int code, String date, bool isLiked) {
  int length = context.read<CodeGen>().getLinkListLength(code);
  double radius = 50;

  return Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
    child: GestureDetector(
      key: ValueKey(code),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => InnerPage(
            code: code,
          ),
        ));
      },
      child: Stack(
        children: [
          //Background Container
          BgContainer(radius: radius),
          //Code Text
          CodeText(code: code),
          //Length indicator
          LengthIndicator(radius: radius, length: length),
          //Date Time Indicator
          DateTimeIndicator(date: date),
          //Like Button
          LikeButton(code: code, isLiked: isLiked),
          //Delete Button
          DltButton(code: code),
        ],
      ),
    ),
  );
}

class BgContainer extends StatelessWidget {
  const BgContainer({
    super.key,
    required this.radius,
  });

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(radius),
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
    return Positioned(
      top: 100,
      left: 26,
      child: Text(
        "#$code",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
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
  });

  final double radius;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          length == 1 ? "$length entry" : "$length entries",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class DltButton extends StatelessWidget {
  const DltButton({
    super.key,
    required this.code,
  });

  final int code;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10,
      top: 14,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          onPressed: () {
            //call the clearList func
            context.read<CodeGen>().clearList(code);
          },
          child: Icon(Icons.close_rounded,
              color: Theme.of(context).colorScheme.onPrimary)),
    );
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
    return Positioned(
      right: 76,
      top: 14,
      child: ElevatedButton(
        key: ValueKey(code),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        onPressed: () {
          context.read<CodeGen>().toggleLike(code);
        },
        child: isLiked == true
            ? const Icon(Icons.favorite_rounded, color: Colors.red)
            : const Icon(Icons.favorite_border_rounded, color: Colors.white),
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
    return Positioned(
        top: 26,
        left: 26,
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 8),
            Text(
              "${date.substring(8, 10)} ${months[int.parse(date.substring(5, 7)) - 1]} ${date.substring(0, 4)}, ${date.substring(11, 16)}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ));
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
