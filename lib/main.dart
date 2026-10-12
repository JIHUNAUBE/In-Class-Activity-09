
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'folders_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();
  await helper.init();

  runApp(FestivalApp(helper: helper));
}

class FestivalApp extends StatelessWidget {
  final DatabaseHelper helper;

  const FestivalApp({
    super.key,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fall Festival Roster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
        useMaterial3: true,
      ),
      home: RosterPage(helper: helper),
    );
  }
}

class RosterPage extends StatefulWidget {
  final DatabaseHelper helper;

  const RosterPage({
    super.key,
    required this.helper,
  });

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> records = [];

  bool loading = true;
  bool saving = false;
  int? editingId;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final data = await widget.helper.queryAllRows();

      if (!mounted) return;

      setState(() {
        records = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage('Error loading records: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> saveRecord() async {
    if (saving) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final age = int.parse(ageController.text.trim());

    setState(() => saving = true);

    try {
      if (editingId == null) {
        final id = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (!mounted) return;
        showMessage('Record added! ID: $id');
      } else {
        final affected = await widget.helper.update({
          DatabaseHelper.columnId: editingId,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (!mounted) return;

        if (affected == 0) {
          showMessage('No matching record was updated.');
          return;
        }

        showMessage('Record updated successfully!');
      }

      cancelEdit();
      await loadRecords();
    } catch (e) {
      if (mounted) {
        showMessage('Error saving record: $e');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void startEdit(Map<String, dynamic> record) {
    setState(() {
      editingId = record[DatabaseHelper.columnId] as int;

      nameController.text =
          record[DatabaseHelper.columnName].toString();

      ageController.text =
          record[DatabaseHelper.columnAge].toString();
    });
  }

  void cancelEdit() {
    nameController.clear();
    ageController.clear();

    setState(() {
      editingId = null;
    });
  }

  Future<void> deleteRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Are you sure you want to delete record ID $id?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final affected = await widget.helper.delete(id);

      if (!mounted) return;

      if (affected == 0) {
        showMessage('Record was not found.');
        return;
      }

      if (editingId == id) {
        cancelEdit();
      }

      await loadRecords();

      if (mounted) {
        showMessage('Record deleted successfully!');
      }
    } catch (e) {
      if (mounted) {
        showMessage('Error deleting record: $e');
      }
    }
  }

  void openFolders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoldersPage(
          helper: widget.helper,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        title: const Text('Fall Festival Roster'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Card Folders',
            icon: const Icon(Icons.folder_open),
            onPressed: openFolders,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter guest name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        hintText: 'Enter guest age (0-130)',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Age is required';
                        }

                        final age =
                            int.tryParse(value.trim());

                        if (age == null ||
                            age < 0 ||
                            age > 130) {
                          return 'Enter a whole-number age from 0 to 130';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : saveRecord,
                      icon: Icon(
                        editingId == null
                            ? Icons.add
                            : Icons.save,
                      ),
                      label: Text(
                        editingId == null ? 'Add' : 'Save',
                      ),
                    ),
                  ),
                  if (editingId != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving ? null : cancelEdit,
                        child: const Text('Cancel Edit'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : loadRecords,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: openFolders,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Card Folders'),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Records: ${records.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : records.isEmpty
                        ? const Center(
                            child: Text(
                              'No festival guests yet.\n'
                              'Add your first guest!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];

                              final id = record[
                                  DatabaseHelper.columnId] as int;

                              final name = record[
                                      DatabaseHelper.columnName]
                                  .toString();

                              final age = record[
                                      DatabaseHelper.columnAge]
                                  .toString();

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('$id'),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'ID: $id | Age: $age',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            startEdit(record),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            deleteRecord(id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
