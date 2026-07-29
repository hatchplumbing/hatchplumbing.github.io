// lib/house_details_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HousePage extends StatefulWidget {
  final PlatformFile pdfFile;

  const HousePage({super.key, required this.pdfFile});

  @override
  _HousePageState createState() => _HousePageState();
}

class _HousePageState extends State<HousePage> {
  int _currentIndex = 0;
  final List<String> _sections = ['Rough-in', 'Top-out', 'Trim'];

  final _houseDataBox = Hive.box('houseDataBox');
  final TextEditingController _customItemController = TextEditingController();

  // Replaced the hardcoded defaults with dynamic, empty lists
  final Map<String, List<String>> _globalDefaults = {
    'Rough-in': [],
    'Top-out': [],
    'Trim': [],
  };

  List<String> _checkedDefaults = [];
  List<Map<String, dynamic>> _customItems = [];

  @override
  void initState() {
    super.initState();
    _loadGlobalDefaults(); // Load the user's saved defaults first
    _loadSectionData();
  }

  /// Pulls the user's custom global defaults from the Hive database
  void _loadGlobalDefaults() {
    for (String section in _sections) {
      List<dynamic>? savedDefaults = _houseDataBox.get(
        'global_defaults_$section',
      );
      if (savedDefaults != null) {
        _globalDefaults[section] = List<String>.from(savedDefaults);
      }
    }
  }

  void _loadSectionData() {
    String currentSection = _sections[_currentIndex];
    String houseId = widget.pdfFile.name;
    String storageKey = "${houseId}_$currentSection";

    Map<dynamic, dynamic>? savedData = _houseDataBox.get(storageKey);

    if (savedData != null) {
      setState(() {
        _checkedDefaults = List<String>.from(
          savedData['checkedDefaults'] ?? [],
        );
        _customItems = List<Map<String, dynamic>>.from(
          (savedData['customItems'] ?? []).map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      });
    } else {
      setState(() {
        _checkedDefaults = [];
        _customItems = [];
      });
    }
  }

  void _saveSectionData() {
    String currentSection = _sections[_currentIndex];
    String houseId = widget.pdfFile.name;
    String storageKey = "${houseId}_$currentSection";

    _houseDataBox.put(storageKey, {
      'checkedDefaults': _checkedDefaults,
      'customItems': _customItems,
    });
  }

  /// Adds a custom item ONLY to the current house and section
  void _addCustomItem() {
    if (_customItemController.text.trim().isNotEmpty) {
      setState(() {
        _customItems.add({
          'text': _customItemController.text.trim(),
          'isChecked': false,
        });
      });
      _customItemController.clear();
      _saveSectionData();
    }
  }

  /// Saves an item as a permanent default for ALL houses in this section
  void _addGlobalDefault() {
    String text = _customItemController.text.trim();
    if (text.isNotEmpty) {
      String currentSection = _sections[_currentIndex];

      setState(() {
        // Prevent exact duplicates
        if (!_globalDefaults[currentSection]!.contains(text)) {
          _globalDefaults[currentSection]!.add(text);
        }
      });

      // Save the updated default list to Hive
      _houseDataBox.put(
        'global_defaults_$currentSection',
        _globalDefaults[currentSection],
      );
      _customItemController.clear();
    }
  }

  /// Deletes a global default (with a safety prompt)
  Future<void> _deleteGlobalDefault(String itemText) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Default Item?'),
        content: Text(
          'Are you sure you want to delete "$itemText"?\n\nThis will remove it from the default checklist for ALL houses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      String currentSection = _sections[_currentIndex];
      setState(() {
        _globalDefaults[currentSection]!.remove(itemText);
        // Clean it up from checked lists just in case
        _checkedDefaults.remove(itemText);
      });

      _houseDataBox.put(
        'global_defaults_$currentSection',
        _globalDefaults[currentSection],
      );
      _saveSectionData();
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentSection = _sections[_currentIndex];
    List<String> currentDefaults = _globalDefaults[currentSection] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('House: ${widget.pdfFile.name}'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(file: widget.pdfFile),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('View Start Letter'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const Divider(thickness: 2),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '$currentSection Checklist',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12.0),
              children: [
                // 1. Render Global Default Items
                ...currentDefaults.map((itemText) {
                  bool isChecked = _checkedDefaults.contains(itemText);
                  return CheckboxListTile(
                    title: Text(itemText),
                    subtitle: const Text(
                      'Default Item',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: isChecked,
                    activeColor: Colors.blueGrey,
                    secondary: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () => _deleteGlobalDefault(itemText),
                      tooltip: 'Delete Global Default',
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _checkedDefaults.add(itemText);
                        } else {
                          _checkedDefaults.remove(itemText);
                        }
                      });
                      _saveSectionData();
                    },
                  );
                }),

                // 2. Render Custom Items (House Specific)
                ..._customItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> customItem = entry.value;
                  return CheckboxListTile(
                    title: Text(
                      customItem['text'],
                      style: const TextStyle(color: Colors.blue),
                    ),
                    subtitle: const Text(
                      'Custom Item (This house only)',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: customItem['isChecked'],
                    activeColor: Colors.blue,
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _customItems.removeAt(index));
                        _saveSectionData();
                      },
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        _customItems[index]['isChecked'] = value ?? false;
                      });
                      _saveSectionData();
                    },
                  );
                }),

                // 3. Dual-Action Input Field
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    bottom: 24.0,
                    left: 8,
                    right: 8,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _customItemController,
                        decoration: const InputDecoration(
                          hintText: 'Input Item...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.home_outlined),
                              label: const Text('This House Only'),
                              onPressed: _addCustomItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue.shade900,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.public),
                              label: Text('$currentSection Default'),
                              onPressed: _addGlobalDefault,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green.shade900,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pretend the $currentSection invoice just got generated',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: Text('Generate $currentSection Invoice'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadSectionData();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.plumbing),
            label: 'Rough-in',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.architecture),
            label: 'Top-out',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bathtub), label: 'Trim'),
        ],
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final PlatformFile file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: file.bytes != null
          ? SfPdfViewer.memory(file.bytes!)
          : const Center(
              child: Text(
                'Corrupted File: PDF byte data is missing.',
                style: TextStyle(color: Colors.red),
              ),
            ),
    );
  }
}
