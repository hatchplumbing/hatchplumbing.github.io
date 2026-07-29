// lib/data/folder_tree.dart

/// Represents a file or folder fetched dynamically from Microsoft 365 Graph API.
class FileNode {
  final String id; // The unique Microsoft Graph Item ID
  final String name; // The display name of the file/folder
  final bool isDirectory; // True if it's a folder, False if it's a PDF
  final List<FileNode> children; // Child items (empty if not loaded or if it's a file)
  
  bool isExpanded; // UI state: is the folder open?
  bool isSelected; // UI state: is the folder/file highlighted?
  bool isLoaded; // Data state: have we fetched this folder's children from the API?
  FileNode? parent; // Reference to the parent folder for traversing back up

  FileNode({
    required this.id,
    required this.name,
    required this.isDirectory,
    List<FileNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
    this.isLoaded = false,
    this.parent,
  }) : children = children ?? [];

  /// Recursively clears the selection state for this node and all its children.
  /// Used when tapping a new file/folder so only one item is highlighted.
  static void clearSelection(FileNode node) {
    node.isSelected = false;
    for (var child in node.children) {
      clearSelection(child);
    }
  }

  /// Sorts the children of this node.
  /// Rule 1: Folders always appear at the top.
  /// Rule 2: Items are sorted alphabetically (case-insensitive).
  void sortChildren() {
    if (!isDirectory || children.isEmpty) return;
    
    children.sort((a, b) {
      // Folders come first
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      
      // Then sort alphabetically
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  /// Helper to get the full breadcrumb path of the node.
  /// (e.g., "Workspace Root / Invoices / 2026 / Smith_House.pdf")
  String getFullPath() {
    if (parent == null || id == 'root') {
      return name;
    }
    return '${parent!.getFullPath()} / $name';
  }
}