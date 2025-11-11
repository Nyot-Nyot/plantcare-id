import 'package:flutter/material.dart';

import '../widgets/bottom_nav.dart';
import 'tabs/collection_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/identify_tab.dart';
import 'tabs/profile_tab.dart';

/// A simple wrapper screen that wires the app's primary tabs into the
/// BottomNavScaffold. Keeps wiring centralized so main.dart stays small.
class MainTabbedScreen extends StatelessWidget {
  const MainTabbedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pass the real pages so BottomNavScaffold will preserve their state.
    return const BottomNavScaffold(
      pages: [HomeTab(), IdentifyTab(), CollectionTab(), ProfileTab()],
    );
  }
}
