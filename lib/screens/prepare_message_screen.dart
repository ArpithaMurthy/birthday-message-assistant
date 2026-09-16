import 'package:flutter/material.dart';
import 'package:moments_remembered/models/occasion.dart';
import 'package:moments_remembered/services/message_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PrepareMessageScreen extends StatefulWidget {
  const PrepareMessageScreen({required this.occasion, super.key});

  final Occasion occasion;

  @override
  State<PrepareMessageScreen> createState() => _PrepareMessageScreenState();
}

class _PrepareMessageScreenState extends State<PrepareMessageScreen> {
  final _service = MessageService();
  late final TextEditingController _message;
  MessageTone _tone = MessageTone.warm;
  bool _openedComposer = false;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(text: _service.draft(widget.occasion, _tone));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _changeTone(MessageTone tone) {
    setState(() {
      _tone = tone;
      _message.text = _service.draft(widget.occasion, tone);
    });
  }

  Future<void> _open() async {
    final opened = await _service.openComposer(widget.occasion, _message.text.trim());
    if (!mounted) return;
    setState(() => _openedComposer = opened);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No compatible messaging app was found. Try the Share channel.')));
    }
  }

  void _complete() {
    Navigator.pop(context, widget.occasion.copyWith(lastHandledYear: widget.occasion.nextOccurrence().year));
  }

  Future<void> _openActionLink() async {
    final uri = Uri.tryParse(widget.occasion.actionUrl.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final channelLabel = widget.occasion.channel.label;
    return Scaffold(
      appBar: AppBar(title: Text(widget.occasion.calendarTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Make it sound like you', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Choose a starting point, then edit every word before opening your messaging app.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MessageTone.values.map((tone) => ChoiceChip(label: Text(tone.name[0].toUpperCase() + tone.name.substring(1)), selected: tone == _tone, onSelected: (_) => _changeTone(tone))).toList(),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _message,
              minLines: 7,
              maxLines: 12,
              decoration: const InputDecoration(labelText: 'Your message', alignLabelWithHint: true),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _open, icon: const Icon(Icons.send_outlined), label: Text('Open $channelLabel')),
            if (widget.occasion.actionUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _openActionLink, icon: const Icon(Icons.open_in_new), label: const Text('Open action link')),
            ],
            const SizedBox(height: 10),
            Text('Nothing is sent automatically. You review and press Send in the selected app.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            if (_openedComposer) ...[
              const SizedBox(height: 22),
              OutlinedButton.icon(onPressed: _complete, icon: const Icon(Icons.check_circle_outline), label: const Text('Mark as handled')),
            ],
          ],
        ),
      ),
    );
  }
}
