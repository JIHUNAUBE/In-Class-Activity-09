import 'package:flutter/material.dart';
import 'database_helper.dart';

class CardsPage extends StatefulWidget {
  final DatabaseHelper helper;
  final int folderId;
  final String folderName;

  const CardsPage({
    super.key,
    required this.helper,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  List<Map<String, dynamic>> cards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  Future<void> loadCards() async {
    try {
      final result = await widget.helper.getCards(widget.folderId);
      if (!mounted) return;
      setState(() {
        cards = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Error loading cards: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> showCardForm({Map<String, dynamic>? card}) async {
    final isEditing = card != null;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CardFormDialog(
        helper: widget.helper,
        folderId: widget.folderId,
        card: card,
      ),
    );

    if (!mounted) return;
    if (saved == true) {
      await loadCards();
      if (!mounted) return;
      showMessage(isEditing ? 'Card updated successfully.' : 'Card added successfully.');
    }
  }

  Future<void> deleteCard(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Card?'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await widget.helper.deleteCard(id);
      await loadCards();
      if (!mounted) return;
      showMessage('Card deleted.');
    } catch (e) {
      showMessage('Delete failed: $e');
    }
  }

  IconData getSuitIcon(String suit) {
    switch (suit) {
      case 'Hearts':
        return Icons.favorite;
      case 'Diamonds':
        return Icons.diamond;
      case 'Clubs':
        return Icons.filter_vintage;
      case 'Spades':
        return Icons.style;
      default:
        return Icons.credit_card;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadCards,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
              ? const Center(
                  child: Text(
                    'No cards yet.\nTap + to add a card.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final id = card['id'] as int;
                    final title = card['title'] as String;
                    final suit = card['suit'] as String;
                    final notes = card['notes'] as String? ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(getSuitIcon(suit), color: Colors.deepOrange),
                        title: Text(title),
                        subtitle: Text(notes.isEmpty ? suit : '$suit\n$notes'),
                        isThreeLine: notes.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showCardForm(card: card),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteCard(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCardForm(),
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardFormDialog extends StatefulWidget {
  final DatabaseHelper helper;
  final int folderId;
  final Map<String, dynamic>? card;

  const _CardFormDialog({
    required this.helper,
    required this.folderId,
    this.card,
  });

  @override
  State<_CardFormDialog> createState() => _CardFormDialogState();
}

class _CardFormDialogState extends State<_CardFormDialog> {
  static const suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController notesController;
  late final TextEditingController imageController;
  late String selectedSuit;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.card?['title'] as String? ?? '');
    notesController = TextEditingController(text: widget.card?['notes'] as String? ?? '');
    imageController = TextEditingController(text: widget.card?['image_ref'] as String? ?? '');
    final currentSuit = widget.card?['suit'] as String?;
    selectedSuit = suits.contains(currentSuit) ? currentSuit! : suits.first;
  }

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    imageController.dispose();
    super.dispose();
  }

  Future<void> saveCard() async {
    if (isSaving || !(formKey.currentState?.validate() ?? false)) return;
    setState(() => isSaving = true);

    try {
      final title = titleController.text.trim();
      final notes = notesController.text.trim();
      final imageRef = imageController.text.trim();
      if (widget.card != null) {
        await widget.helper.updateCard(
          id: widget.card!['id'] as int,
          title: title,
          suit: selectedSuit,
          folderId: widget.folderId,
          notes: notes,
          imageRef: imageRef.isEmpty ? null : imageRef,
        );
      } else {
        await widget.helper.insertCard(
          title: title,
          suit: selectedSuit,
          folderId: widget.folderId,
          notes: notes,
          imageRef: imageRef.isEmpty ? null : imageRef,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.card == null ? 'Add Card' : 'Edit Card'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Card Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedSuit,
                decoration: const InputDecoration(
                  labelText: 'Suit',
                  border: OutlineInputBorder(),
                ),
                items: suits
                    .map((suit) => DropdownMenuItem(value: suit, child: Text(suit)))
                    .toList(),
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => selectedSuit = value);
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'Image Reference (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : saveCard,
          child: Text(isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
