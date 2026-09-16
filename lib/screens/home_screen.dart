import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moments_remembered/models/occasion.dart';
import 'package:moments_remembered/screens/import_occasions_screen.dart';
import 'package:moments_remembered/screens/occasion_form.dart';
import 'package:moments_remembered/screens/prepare_message_screen.dart';
import 'package:moments_remembered/services/calendar_service.dart';
import 'package:moments_remembered/services/data_transfer_service.dart';
import 'package:moments_remembered/services/notification_service.dart';
import 'package:moments_remembered/services/occasion_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _remindersEnabledKey = 'reminders.enabled.v1';
  final _repository = OccasionRepository();
  final _notifications = NotificationService();
  final _calendar = CalendarService();
  final _dataTransfer = DataTransferService();
  final _uuid = const Uuid();
  List<Occasion> _occasions = [];
  bool _loading = true;
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _notifications.initialize();
    final preferences = await SharedPreferences.getInstance();
    final remindersEnabled = preferences.getBool(_remindersEnabledKey) ?? false;
    final occasions = await _repository.load();
    occasions.sort((left, right) => left.daysUntil().compareTo(right.daysUntil()));
    if (!mounted) return;
    setState(() {
      _occasions = occasions;
      _remindersEnabled = remindersEnabled;
      _loading = false;
    });
    if (remindersEnabled) await _notifications.rescheduleAll(occasions);
  }

  Future<void> _persist() async {
    _occasions.sort((left, right) => left.daysUntil().compareTo(right.daysUntil()));
    await _repository.save(_occasions);
    if (_remindersEnabled) await _notifications.rescheduleAll(_occasions);
    if (mounted) setState(() {});
  }

  Future<void> _enableReminders() async {
    final granted = await _notifications.requestPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications were not enabled. You can allow them in device settings.')));
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_remindersEnabledKey, true);
    await _notifications.rescheduleAll(_occasions);
    if (!mounted) return;
    setState(() => _remindersEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminders are enabled on this device.')));
  }

  Future<void> _addOccasion() async {
    final occasion = await Navigator.push<Occasion>(context, MaterialPageRoute(builder: (_) => const OccasionForm()));
    if (occasion == null) return;
    _occasions.add(occasion);
    await _persist();
  }

  Future<void> _importOccasions() async {
    final imported = await Navigator.push<List<Occasion>>(context, MaterialPageRoute(builder: (_) => const ImportOccasionsScreen()));
    if (imported == null || imported.isEmpty) return;
    final existingIds = _occasions.map((occasion) => occasion.id).toSet();
    _occasions.addAll(imported.map((occasion) => existingIds.contains(occasion.id) ? occasion.copyWith(id: _uuid.v4(), clearHandledYear: true) : occasion));
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${imported.length} occasion${imported.length == 1 ? '' : 's'}.')));
  }

  Future<void> _exportBackup() async {
    final content = _dataTransfer.exportJson(_occasions);
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
      name: 'tinytools-life-admin-data.json',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: const ['tinytools-life-admin-data.json'],
        subject: 'TinyTools Life Admin backup',
        text: 'Private local backup of my occasion reminders.',
      ),
    );
  }

  Future<void> _prepare(Occasion occasion) async {
    final updated = await Navigator.push<Occasion>(context, MaterialPageRoute(builder: (_) => PrepareMessageScreen(occasion: occasion)));
    if (updated == null) return;
    final index = _occasions.indexWhere((item) => item.id == updated.id);
    _occasions[index] = updated;
    await _persist();
  }

  Future<void> _remove(Occasion occasion) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Remove ${occasion.calendarTitle}?'),
            content: const Text('This occasion and its local history will be removed from this device.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    _occasions.removeWhere((item) => item.id == occasion.id);
    await _persist();
  }

  Future<void> _exportCalendar() async {
    await _calendar.export(_occasions);
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _occasions.where((occasion) => occasion.daysUntil() <= 30).toList();
    final later = _occasions.where((occasion) => occasion.daysUntil() > 30).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('TinyTools'),
        actions: [
          if (_occasions.isNotEmpty) IconButton(onPressed: _exportCalendar, tooltip: 'Export to calendar', icon: const Icon(Icons.calendar_month_outlined)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') _importOccasions();
              if (value == 'backup') _exportBackup();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'import', child: Text('Import list')),
              PopupMenuItem(value: 'backup', child: Text('Export backup')),
            ],
          ),
          IconButton(onPressed: _addOccasion, tooltip: 'Add reminder', icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addOccasion, icon: const Icon(Icons.add), label: const Text('Add reminder')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _occasions.isEmpty
              ? _EmptyState(onAdd: _addOccasion, onImport: _importOccasions)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                    children: [
                      Text('Thoughtfulness, on time.', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text('Private reminders for birthdays, anniversaries, holidays, and the moments that matter.', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(onPressed: _addOccasion, icon: const Icon(Icons.add), label: const Text('Add')),
                          OutlinedButton.icon(onPressed: _importOccasions, icon: const Icon(Icons.upload_file), label: const Text('Import')),
                          OutlinedButton.icon(onPressed: _exportBackup, icon: const Icon(Icons.ios_share), label: const Text('Backup')),
                        ],
                      ),
                      if (!_remindersEnabled) ...[
                        const SizedBox(height: 18),
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Enable occasion reminders', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              const Text('Your device can remind you even when this app is closed. Occasions stay on this device.'),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(onPressed: _enableReminders, icon: const Icon(Icons.notifications_active_outlined), label: const Text('Enable reminders')),
                            ]),
                          ),
                        ),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text('COMING UP', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.4)),
                        const SizedBox(height: 10),
                        ...upcoming.map((occasion) => _OccasionCard(occasion: occasion, onPrepare: () => _prepare(occasion), onRemove: () => _remove(occasion))),
                      ],
                      if (later.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text('LATER', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.4)),
                        const SizedBox(height: 10),
                        ...later.map((occasion) => _OccasionCard(occasion: occasion, onPrepare: () => _prepare(occasion), onRemove: () => _remove(occasion))),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _OccasionCard extends StatelessWidget {
  const _OccasionCard({required this.occasion, required this.onPrepare, required this.onRemove});
  final Occasion occasion;
  final VoidCallback onPrepare;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final days = occasion.daysUntil();
    final occurrence = occasion.nextOccurrence();
    final handled = occasion.isHandledFor(occurrence.year);
    final timing = days == 0 ? 'Today' : days == 1 ? 'Tomorrow' : 'In $days days';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 25, child: Icon(occasion.type == OccasionType.birthday ? Icons.cake_outlined : Icons.celebration_outlined)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(occasion.calendarTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                  Text('${occasion.module} · ${occasion.type.label}${occasion.relationship.isEmpty ? '' : ' · ${occasion.relationship}'} · ${DateFormat('d MMM').format(occurrence)} · ${occasion.channel.label}'),
                const SizedBox(height: 6),
                Text(handled ? 'Handled for ${occurrence.year}' : timing, style: TextStyle(color: handled ? Colors.green.shade700 : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'prepare' ? onPrepare() : onRemove(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'prepare', child: Text('Prepare message')),
                PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.onImport});
  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.celebration_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text('Remember the moments that matter.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            const Text('Add a birthday, anniversary, holiday, or custom occasion. This device will remind you and help prepare a thoughtful message.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add one occasion')),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.upload_file), label: const Text('Import a list')),
          ]),
        ),
      );
}
