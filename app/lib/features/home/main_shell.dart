import 'package:flutter/material.dart';

import '../academics/presentation/academics_tab.dart';
import '../planner/presentation/planner_tab.dart';
import '../qa/presentation/qa_feed_screen.dart';
import '../profile/presentation/profile_tab.dart';
import 'home_tab.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Bottom-navigation shell. New feature tabs are added to [_destinations] in later phases.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _destinations = [
    _Destination('Home', Icons.home_outlined, Icons.home, HomeTab()),
    _Destination('Academics', Icons.school_outlined, Icons.school, AcademicsTab()),
    _Destination('Planner', Icons.event_note_outlined, Icons.event_note, PlannerTab()),
    _Destination('Q&A', Icons.forum_outlined, Icons.forum, QaFeedScreen()),
    _Destination('Profile', Icons.person_outline, Icons.person, ProfileTab()),
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: [for (final d in _destinations) d.page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}
