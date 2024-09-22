import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';

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
          style: TextStyle(fontFamily: 'Product', color: colors.toastText),
        )),
  ).show(context);
}
