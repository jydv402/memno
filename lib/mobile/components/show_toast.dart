import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:material_ui/material_ui.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Shows a transient confirmation toast sliding from the top of the screen,
/// colored by the app palette and auto-dismissed after 2 seconds.
///
/// Safe to call for any outcome message (saved, copied, deleted, errors
/// surfaced as short strings); it never blocks input and needs no cleanup.
void showToastMsg(BuildContext context, String msg) {
  final colors = Provider.of<AppColors>(context, listen: false);
  DelightToastBar(
    autoDismiss: true,
    snackbarDuration: const Duration(seconds: 2),
    position: DelightSnackbarPosition.top,
    builder: (context) => ToastCard(
      color: colors.toastBg,
      title: Text(
        msg,
        style: TextStyle(fontFamily: 'GoogleSans', color: colors.toastText),
      ),
    ),
  ).show(context);
}
