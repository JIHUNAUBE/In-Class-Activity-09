
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'cards_page.dart';

class FoldersPage extends StatefulWidget {
  final DatabaseHelper helper;

  const FoldersPage({
    super.key,
    required this.helper,
  });

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  List<Map<String, dynamic>> folders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> loadFolders() async {
    try {
      final result = await widget.helper.getFoldersWithCounts();

      if (!mounted) return;

      setState(() {
        folders = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Error loading folders: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> addFolder() async {
    String folderName = '';

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              folderName = value;
            },
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(dialogContext).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = folderName.trim();

                FocusManager.instance.primaryFocus?.unfocus();

                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || name == null) return;

    if (name.isEmpty) {
      showMessage('Folder name cannot be empty.');
      return;
    }

    try {
      await widget.helper.insertFolder(name);

      if (!mounted) return;

      await loadFolders();

      if (!mounted) return;

      showMessage('Folder created successfully.');
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Could not create folder. Check for duplicates.',
      );
    }
  }

  Future<void> deleteFolder(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            'Delete "$name" and all cards inside it? '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.helper.deleteFolder(id);

      if (!mounted) return;

      await loadFolders();

      if (!mounted) return;

      showMessage('Folder deleted.');
    } catch (e) {
      if (!mounted) return;

      showMessage('Error deleting folder: $e');
    }
  }

  Future<void> openFolder(int id, String name) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return CardsPage(
            helper: widget.helper,
            folderId: id,
            folderName: name,
          );
        },
      ),
    );

    if (!mounted) return;

    await loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Folders',
            onPressed: loadFolders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : folders.isEmpty
              ? const Center(
                  child: Text(
                    'No folders yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];

                    final id = folder['id'] as int;
                    final name = folder['name'] as String;
                    final count =
                        (folder['card_count'] as num).toInt();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.folder,
                          color: Colors.orange,
                        ),
                        title: Text(name),
                        subtitle: Text('$count cards'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete Folder',
                          onPressed: () {
                            deleteFolder(id, name);
                          },
                        ),
                        onTap: () {
                          openFolder(id, name);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: addFolder,
        tooltip: 'Add Folder',
        child: const Icon(Icons.add),
      ),
    );
  }
}
