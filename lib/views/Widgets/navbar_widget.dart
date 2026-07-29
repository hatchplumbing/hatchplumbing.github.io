import 'package:flutter/material.dart';
import 'package:hatch_plumbing_billing/data/notifiers.dart';

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: selectedPageNotifier, builder: (context, selectedPage, child) {
      return BottomNavigationBar(
        currentIndex: selectedPage,
        onTap: (index) {
          selectedPageNotifier.value = index;
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Catalog'),
          // Add other navigation items here
        ],
      );
    });
  }
}
