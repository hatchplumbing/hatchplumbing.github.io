import 'package:flutter/material.dart';
import 'package:hatch_plumbing_billing/data/notifiers.dart';
import 'package:hatch_plumbing_billing/views/widget_tree.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Add this import


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive and open a storage box for our ZIP workspace
  await Hive.initFlutter();
  await Hive.openBox('workspaceBox'); 
  await Hive.openBox('houseDataBox');  
  runApp(const MyApp()); // (Replace with your actual root app widget)
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
   return ValueListenableBuilder(valueListenable: isDarkModeNotifier, builder: (context, isDarkMode, child) {
       return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          
          brightness: isDarkModeNotifier.value ? Brightness.dark : Brightness.light,
        ),
      ),
      home: WidgetTree()
    );
    });
  }
}
