import 'package:flutter/material.dart';
import 'package:moments_remembered/models/occasion.dart';
import 'package:moments_remembered/services/data_transfer_service.dart';

class ImportOccasionsScreen extends StatefulWidget {
  const ImportOccasionsScreen({super.key});

  @override
  State<ImportOccasionsScreen> createState() => _ImportOccasionsScreenState();
}

class _ImportOccasionsScreenState extends State<ImportOccasionsScreen> {
  final _controller = TextEditingController();
  final _service = DataTransferService();
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _import() {
    final occasions = _service.importText(_controller.text);
    if (occasions.isEmpty) {
      setState(() => _error = 'No valid occasions found. Try CSV or JSON with dates like Jan 9, 9 Jan, 7/12, or 2026-01-09.');
      return;
    }
    Navigator.pop(context, occasions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import occasions')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Paste a list once', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Paste CSV or JSON from Notes, WhatsApp, Drive, or a spreadsheet export. Data is saved only on this device.'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 12,
              maxLines: 18,
              decoration: const InputDecoration(
                labelText: 'CSV or JSON',
                alignLabelWithHint: true,
                hintText: 'type,title,date,person,relationship,channel,phone,notes,default_message\nBirthday,Birthday,Jan 9,Prashant,,WhatsApp,+886...,Happy memory,Happy birthday!',
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('Import occasions')),
          ],
        ),
      ),
    );
  }
}
