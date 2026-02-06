import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/section_card.dart';

class ListingGeneratorScreen extends StatefulWidget {
  const ListingGeneratorScreen({super.key});

  @override
  State<ListingGeneratorScreen> createState() => _ListingGeneratorScreenState();
}

class _ListingGeneratorScreenState extends State<ListingGeneratorScreen> {
  late final SupabaseService _service;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _selectedItem;

  @override
  void initState() {
    super.initState();
    _service = SupabaseService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final items = await _service.fetchItems(userId);
    setState(() {
      _items = items;
      _selectedItem = items.isNotEmpty ? items.first : null;
      _loading = false;
    });
  }

  String _buildTitle() {
    final item = _selectedItem;
    if (item == null) return '';
    return '${item['brand'] ?? ''} ${item['category'] ?? ''} ${item['size'] ?? ''}'.trim();
  }

  String _buildDescription() {
    final item = _selectedItem;
    if (item == null) return '';
    return [
      item['description'],
      'Size: ${item['size'] ?? 'N/A'}',
      'Colour: ${item['colour'] ?? 'N/A'}',
      'Brand: ${item['brand'] ?? 'N/A'}',
    ].where((value) => value != null && value.toString().isNotEmpty).join('\n');
  }

  String _buildHashtags() {
    final item = _selectedItem;
    if (item == null) return '';
    final tags = [
      item['brand'],
      item['category'],
      item['colour'],
      item['size'],
      'vinted',
      'secondhand',
    ].whereType<String>().where((value) => value.isNotEmpty).map((value) => '#${value.replaceAll(' ', '')}');
    return tags.join(' ');
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final title = _buildTitle();
    final description = _buildDescription();
    final hashtags = _buildHashtags();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Listing Generator', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        DropdownButton<Map<String, dynamic>>(
          value: _selectedItem,
          items: _items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item['title'] ?? ''),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedItem = value),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Generated Title',
          child: Row(
            children: [
              Expanded(child: Text(title)),
              TextButton(onPressed: () => _copyToClipboard(title), child: const Text('Copy')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Generated Description',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(description)),
              TextButton(onPressed: () => _copyToClipboard(description), child: const Text('Copy')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Hashtags',
          child: Row(
            children: [
              Expanded(child: Text(hashtags)),
              TextButton(onPressed: () => _copyToClipboard(hashtags), child: const Text('Copy')),
            ],
          ),
        ),
      ],
    );
  }
}
