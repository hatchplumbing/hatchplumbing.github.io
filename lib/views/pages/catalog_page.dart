import 'package:flutter/material.dart';
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text('Catalog Page\nThis will be a list of prices that you will be able to edit.'),
        ],
      ),
    );
  }
}
