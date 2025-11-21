import 'package:flutter/material.dart';

import '../screens/camera_capture_screen_v2.dart';

/// A small, reusable Bottom Navigation scaffold that uses an IndexedStack
/// to preserve state between tabs. Tabs and their widget pages are defined
/// below as defaults; you can also pass custom pages into the constructor.
class BottomNavScaffold extends StatefulWidget {
  final List<Widget>? pages;

  const BottomNavScaffold({super.key, this.pages});

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  int _currentIndex = 0;

  static const _labels = ['Home', 'Identify', 'Collection', 'Profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.camera_alt_outlined,
    Icons.collections_outlined,
    Icons.person_outline,
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages =
        widget.pages ??
        [
          const _PlaceholderTab(title: 'Home'),
          const _PlaceholderTab(title: 'Identify'),
          const _PlaceholderTab(title: 'Collection'),
          const _PlaceholderTab(title: 'Profile'),
        ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          // When Identify (index 1) is tapped, open the camera directly
          // instead of switching to the tab page which would require an
          // extra "Open Camera" press.
          if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CameraCaptureScreenV2()),
            );
            return;
          }
          setState(() => _currentIndex = i);
        },
        selectedItemColor: theme.colorScheme.primary,
        // use withAlpha to avoid precision-loss deprecation warnings
        unselectedItemColor: theme.colorScheme.onSurface.withAlpha(153),
        type: BottomNavigationBarType.fixed,
        items: List.generate(_labels.length, (i) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: _labels[i],
          );
        }),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;

  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(child: Text(title, style: textTheme.headlineSmall)),
    );
  }
}
