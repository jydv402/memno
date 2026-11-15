import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:provider/provider.dart';

/// The tall lime title capsule at the top of a note page, with an edit
/// button tucked into its bottom-right corner.
///
/// [InnerPageTopBar] shows the note title at 48 px; a horizontal scroll
/// view swallows overflow instead of wrapping so long titles stay one
/// line. [onPressed] opens the title editor after a light haptic fires
/// through [AppSettings].
class InnerPageTopBar extends StatelessWidget {
  /// Note title text as stored; rendered with tab indent as authored.
  final String head;

  /// Invoked by the edit button after the haptic; omit for a read-only
  /// bar such as the embedded preview mode.
  final VoidCallback? onPressed;

  /// Creates the bar for [head]; [onPressed] may be null.
  const InnerPageTopBar({super.key, required this.head, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Container(
      alignment: Alignment.centerLeft,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(2, 0, 2, 4),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: colors.accnt,
      ),
      child: Stack(
        children: [
          // Title text
          Positioned(
            top: 42,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Text(
                "\t\t$head",
                style: const TextStyle(
                  fontFamily: 'GoogleSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Edit title button
          Positioned(
            bottom: 10,
            right: 10,
            child: IconButton(
              tooltip: "Edit title",
              onPressed: () {
                Provider.of<AppSettings>(
                  context,
                  listen: false,
                ).triggerHaptic();
                onPressed?.call();
              },
              icon: const Icon(Icons.mode_edit_outline_outlined),
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
