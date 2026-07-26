import 'package:flutter/material.dart';
import 'package:memno/logic/theme/app_colors.dart';
import 'package:memno/logic/theme/app_settings.dart';
import 'package:memno/mobile/components/pill_button.dart';
import 'package:provider/provider.dart';

/// Custom floating action bar for adding/editing/deleting links or title.
class CustomInnerFAB extends StatelessWidget {
  const CustomInnerFAB({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    required this.onCollapse,
    required this.controller,
    required this.isEditMode,
    required this.fabFocus,
    this.isEmbedded = false,
  });
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onCollapse;
  final TextEditingController controller;
  final int isEditMode;
  final FocusNode fabFocus;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillButton(
            label: "Collapse",
            icon: Icons.keyboard_arrow_down_rounded,
            onPressed: onCollapse,
            backgroundColor: colors.accnt,
            foregroundColor: Colors.black,
            iconColor: Colors.black,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            height: 130,
            decoration: BoxDecoration(
              color: colors.bgClr,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: colors.fgClr, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text field for link or title input
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(42),
                      color: colors.box,
                    ),
                    child: TextField(
                      autocorrect: true,
                      autofillHints: [
                        AutofillHints.url,
                        AutofillHints.email,
                        AutofillHints.username,
                        AutofillHints.password,
                      ],
                      focusNode: fabFocus,
                      controller: controller,
                      minLines: null,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        color: colors.fgClr,
                        fontFamily: 'GoogleSans',
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                // Confirm and cancel buttons
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).triggerHaptic();
                          onConfirm();
                        },
                        icon: Icon(
                          isEditMode == 0
                              ? Icons.add_rounded
                              : Icons.check_rounded,
                          color: colors.accnt,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Provider.of<AppSettings>(
                            context,
                            listen: false,
                          ).triggerHaptic();
                          onCancel();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.red,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
