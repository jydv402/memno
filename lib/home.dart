import 'package:flutter/material.dart';
import 'package:memno/components/main_tile.dart';
import 'package:memno/functionality/code_gen.dart';
import 'package:memno/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Memno"),
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () => context.read<CodeGen>().display(),
                icon: const Icon(Icons.print)),
            Switch(
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
            ),
          ],
        ),
      ),
      body: const MainTile(),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          context.read<CodeGen>().generateCode();
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
