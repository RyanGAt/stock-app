import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/section_card.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  String? _selectedItemId;
  final _descriptionController = TextEditingController();
  final _hashtagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = SupabaseService(Supabase.instance.client);
    _load();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    final items = await _service.fetchItems(userId);
    setState(() {
      _items = items;
      _selectedItemId ??= _items.isNotEmpty ? _items.first['id'] as String : null;
      _syncGeneratedFields();
      _loading = false;
    });
  }

  Map<String, dynamic>? get _selectedItem {
    for (final item in _items) {
      if (item['id'] == _selectedItemId) return item;
    }
    return null;
  }

  String get _generatedTitle {
    final item = _selectedItem;
    if (item == null) return '';
    final parts = [
      item['brand'] as String?,
      item['category'] as String?,
      item['size'] as String?,
      item['colour'] as String?,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>().toList();
    final joined = parts.join(' ').trim();
    return joined.isEmpty ? 'Vintage Listing' : 'Vintage $joined';
  }

  void _syncGeneratedFields() {
    final item = _selectedItem;
    if (item == null) {
      _descriptionController.text = '';
      _hashtagsController.text = '';
      return;
    }
    final category = (item['category'] as String?)?.trim();
    final brand = (item['brand'] as String?)?.trim();
    final colour = (item['colour'] as String?)?.trim();
    final size = (item['size'] as String?)?.trim();

    _descriptionController.text =
        'This ${category?.isNotEmpty == true ? category : 'item'} by ${brand?.isNotEmpty == true ? brand : 'your favourite brand'} '
        'comes in ${colour?.isNotEmpty == true ? colour : 'a versatile colour'}'
        '${size?.isNotEmpty == true ? ', size $size' : ''}. '
        'Perfect for refreshing your wardrobe or relisting across your favourite resale platform.';

    final hashtags = <String>{
      '#vintage',
      '#reseller',
      '#sustainablefashion',
      '#style',
      '#streetwear',
      if (brand != null && brand.isNotEmpty) '#${brand.replaceAll(' ', '')}',
      if (category != null && category.isNotEmpty) '#${category.replaceAll(' ', '')}',
      if (colour != null && colour.isNotEmpty) '#${colour.replaceAll(' ', '')}',
    };
    _hashtagsController.text = hashtags.join(' ');
  }

  Future<void> _copyText(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final item = _selectedItem;
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generator', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Create ready-to-post listing copy from your saved item details.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: 'Listing copy',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedItemId,
                        decoration: const InputDecoration(labelText: 'Select item'),
                        items: _items
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry['id'] as String,
                                child: Text(entry['title'] as String? ?? 'Untitled item'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedItemId = value;
                            _syncGeneratedFields();
                          });
                        },
                      ),
                      if (item != null) ...[
                        const SizedBox(height: 20),
                        _GeneratedField(
                          label: 'Generated title',
                          value: _generatedTitle,
                          maxLines: 2,
                          onCopy: () => _copyText(_generatedTitle, 'Title'),
                        ),
                        const SizedBox(height: 20),
                        _GeneratedField(
                          label: 'Generated description',
                          controller: _descriptionController,
                          maxLines: 5,
                          onCopy: () => _copyText(_descriptionController.text, 'Description'),
                        ),
                        const SizedBox(height: 20),
                        _GeneratedField(
                          label: 'Generated hashtags',
                          controller: _hashtagsController,
                          maxLines: 3,
                          onCopy: () => _copyText(_hashtagsController.text, 'Hashtags'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}

class _GeneratedField extends StatelessWidget {
  const _GeneratedField({
    required this.label,
    required this.onCopy,
    this.value,
    this.controller,
    this.maxLines = 1,
  });

  final String label;
  final VoidCallback onCopy;
  final String? value;
  final TextEditingController? controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final child = controller == null
        ? TextFormField(
            initialValue: value,
            readOnly: true,
            maxLines: maxLines,
          )
        : TextField(
            controller: controller,
            maxLines: maxLines,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy'),
            ),
          ],
        ),
      ],
    );
  }
}
