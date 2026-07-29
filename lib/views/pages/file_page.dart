// lib/views/pages/file_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:file_picker/file_picker.dart';

import 'package:hatch_plumbing_billing/views/pages/settings_page.dart';
import 'package:hatch_plumbing_billing/data/folder_tree.dart';
import 'package:hatch_plumbing_billing/views/pages/house_page.dart';

// --- CRITICAL FIX FOR GRAY SCREEN ---
// This key must be global so the entire app and Microsoft Auth share the same router.
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  _FilePageState createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  FileNode? _rootNode;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  late final AadOAuth oauth;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Microsoft Config here using the global key
    final Config config = Config(
      tenant: 'YOUR_TENANT_ID', 
      clientId: 'YOUR_CLIENT_ID', 
      scope: 'openid profile offline_access Files.Read.All', 
      redirectUri: 'hatchplumbing.github.io', // Change if using a different port or deploying
      navigatorKey: globalNavigatorKey, // Uses the global key to prevent crashes
      webUseRedirect: true, // Crucial for web to prevent popup blockers
    );

    oauth = AadOAuth(config);

    // 2. Delay the auth check slightly to let Flutter finish building the UI first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    try {
      final hasCachedToken = await oauth.hasCachedAccountInformation;
      if (hasCachedToken) {
        setState(() => _isAuthenticated = true);
        await _fetchRootDrive();
      }
    } catch (e) {
      debugPrint("Auth Check Error: $e");
    }
  }

  Future<void> _login() async {
    try {
      await oauth.login();
      final accessToken = await oauth.getAccessToken();
      if (accessToken != null) {
        setState(() => _isAuthenticated = true);
        await _fetchRootDrive();
      }
    } catch (e) {
      _showError('Login failed: $e');
    }
  }

  Future<void> _logout() async {
    await oauth.logout();
    setState(() {
      _isAuthenticated = false;
      _rootNode = null;
    });
  }

  Future<void> _fetchRootDrive() async {
    setState(() => _isLoading = true);
    
    final token = await oauth.getAccessToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root/children');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final rootFolder = FileNode(
          id: 'root',
          name: 'Workspace Root',
          isDirectory: true,
          isExpanded: true,
          isLoaded: true,
        );

        _parseGraphItemsIntoFolder(rootFolder, data['value']);

        setState(() {
          _rootNode = rootFolder;
          _isLoading = false;
        });
      } else {
        _showError('Failed to fetch workspace: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Network error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFolderChildren(FileNode folderNode) async {
    if (folderNode.isLoaded) return; 

    setState(() => _isLoading = true);
    final token = await oauth.getAccessToken();
    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/${folderNode.id}/children');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _parseGraphItemsIntoFolder(folderNode, data['value']);
        
        setState(() {
          folderNode.isLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Failed to load folder contents: $e');
      setState(() => _isLoading = false);
    }
  }

  void _parseGraphItemsIntoFolder(FileNode parentFolder, List<dynamic> graphItems) {
    for (var item in graphItems) {
      final isFolder = item.containsKey('folder');
      
      if (!isFolder && !item['name'].toString().toLowerCase().endsWith('.pdf')) {
        continue; 
      }

      parentFolder.children.add(FileNode(
        id: item['id'],
        name: item['name'],
        isDirectory: isFolder,
        parent: parentFolder,
      ));
    }

    parentFolder.sortChildren(); // Uses the sort function we added to FileNode
  }

  Future<void> _openPdf(FileNode pdfNode) async {
    setState(() => _isLoading = true);
    final token = await oauth.getAccessToken();
    
    // Graph API endpoint for downloading the file bytes
    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/${pdfNode.id}/content');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        final platformFile = PlatformFile(
          name: pdfNode.name,
          size: bytes.length,
          bytes: bytes,
        );

        setState(() => _isLoading = false);
        
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HousePage(pdfFile: platformFile),
            ),
          );
        }
      } else {
        _showError('Failed to download PDF.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Network error downloading PDF: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.business_center),
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout of M365',
              onPressed: _logout,
            ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
          ),
        ],
        centerTitle: true,
        title: const Text('Hatch Workspace'),
      ),
      body: Stack(
        children: [
          if (!_isAuthenticated && !_isLoading)
            Center(
              child: ElevatedButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login),
                label: const Text('Login with Microsoft 365'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ),

          if (_isAuthenticated && _rootNode != null)
            ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "Connected to Microsoft 365 Workspace. Tap a PDF to open the checklist.",
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
                FolderTreeWidget(
                  node: _rootNode!,
                  depth: 0,
                  onFolderTapped: (node) async {
                    FileNode.clearSelection(_rootNode!);
                    node.isSelected = true;
                    node.isExpanded = !node.isExpanded;
                    if (node.isExpanded) {
                      await _fetchFolderChildren(node);
                    } else {
                      setState(() {});
                    }
                  },
                  onPdfTapped: (node) => _openPdf(node),
                ),
              ],
            ),

          if (_isLoading) 
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// --- FOLDER TREE UI WIDGET ---
class FolderTreeWidget extends StatelessWidget {
  final FileNode node;
  final int depth;
  final Function(FileNode) onFolderTapped;
  final Function(FileNode) onPdfTapped;

  const FolderTreeWidget({
    super.key,
    required this.node,
    required this.depth,
    required this.onFolderTapped,
    required this.onPdfTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + (depth * 24.0), right: 16.0),
          tileColor: node.isSelected ? Colors.blue.withValues(alpha: 0.12) : null,
          leading: Icon(
            node.isDirectory
                ? (node.isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded)
                : Icons.picture_as_pdf_rounded,
            color: node.isDirectory ? Colors.amber.shade700 : Colors.red.shade600,
          ),
          title: Text(
            node.name,
            style: TextStyle(fontWeight: node.isDirectory ? FontWeight.bold : FontWeight.normal),
          ),
          trailing: node.isDirectory && node.children.isNotEmpty
              ? Icon(node.isExpanded ? Icons.expand_less : Icons.expand_more)
              : null,
          onTap: () {
            if (node.isDirectory) {
              onFolderTapped(node);
            } else {
               onPdfTapped(node);
            }
          },
        ),
        if (node.isDirectory && node.isExpanded)
          ...node.children.map(
            (childNode) => FolderTreeWidget(
              node: childNode,
              depth: depth + 1,
              onFolderTapped: onFolderTapped,
              onPdfTapped: onPdfTapped,
            ),
          ),
      ],
    );
  }
}