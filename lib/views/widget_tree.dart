import 'package:flutter/material.dart';
import 'package:hatch_plumbing_billing/data/notifiers.dart';
import 'package:hatch_plumbing_billing/views/pages/settings_page.dart';
import 'package:hatch_plumbing_billing/views/Widgets/navbar_widget.dart';
import 'package:hatch_plumbing_billing/views/pages/catalog_page.dart';
import 'package:hatch_plumbing_billing/views/pages/file_page.dart';

List<Widget> getWidgetTree() {
  return [
    const FilePage(),
    const CatalogPage(),
    // Add other widgets here
  ];
}

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This will be the logo'), ),
            );
          },
          tooltip: 'This will be the logo',
          icon: Icon(Icons.house),
        ),
        actions: ([
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
            icon: Icon(Icons.settings),
          ),
        ]),
        centerTitle: true,
        title: const Text('Hatch Plumbing Invoice Generator', maxLines: 2, ),
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return getWidgetTree()[selectedPage];
        },
      ),
      bottomNavigationBar: const NavBarWidget(),
    );
  }
}
