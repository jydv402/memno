import 'package:flutter/material.dart';
import 'package:memno/theme/app_colors.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<AppColors>(context);
    return Hero(
      tag: 'fab_to_page',
      child: Scaffold(
          backgroundColor: colors.bgClr,
          appBar: AppBar(
            backgroundColor: colors.bgClr,
            foregroundColor: colors.fgClr,
            title:
                const Text("Settings", style: TextStyle(fontFamily: 'Product')),
          ),
          body: ListView(
            children: [
              Container(
                height: 100,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50), color: colors.box),
                child: SwitchListTile(
                  title: Text("Dark Mode",
                      style: TextStyle(
                          fontFamily: 'Product',
                          fontSize: 18,
                          color: colors.textClr)),
                  value: context.watch<AppColors>().isDarkMode,
                  onChanged: (_) async {
                    await colors.toggleTheme();
                  },
                ),
              ),
            ],
          )),
    );
  }
}
