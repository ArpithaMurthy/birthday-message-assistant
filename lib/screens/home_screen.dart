import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moments_remembered/models/birthday.dart';
import 'package:moments_remembered/screens/birthday_form.dart';
import 'package:moments_remembered/screens/prepare_message_screen.dart';
import 'package:moments_remembered/services/birthday_repository.dart';
import 'package:moments_remembered/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _remindersEnabledKey = 'reminders.enabled.v1';
  final _repository = BirthdayRepository();
  final _notifications = NotificationService();
  List<Birthday> _birthdays = [];
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
    final birthdays = await _repository.load();
    birthdays.sort((left, right) => left.daysUntil().compareTo(right.daysUntil()));
    if (!mounted) return;
    setState(() {
      _birthdays = birthdays;
      _remindersEnabled = remindersEnabled;
      _loading = false;
    });
    if (remindersEnabled) await _notifications.rescheduleAll(birthdays);
  }

  Future<void> _persist() async {
    _birthdays.sort((left, right) => left.daysUntil().compareTo(right.daysUntil()));
    await _repository.save(_birthdays);
    if (_remindersEnabled) await _notifications.rescheduleAll(_birthdays);
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
    await _notifications.rescheduleAll(_birthdays);
    if (!mounted) return;
    setState(() => _remindersEnabled = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminders are enabled on this device.')));
  }

  Future<void> _addBirthday() async {
    final birthday = await Navigator.push<Birthday>(context, MaterialPageRoute(builder: (_) => const BirthdayForm()));
    if (birthday == null) return;
    _birthdays.add(birthday);
    await _persist();
  }

  Future<void> _prepare(Birthday birthday) async {
    final updated = await Navigator.push<Birthday>(context, MaterialPageRoute(builder: (_) => PrepareMessageScreen(birthday: birthday)));
    if (updated == null) return;
    final index = _birthdays.indexWhere((item) => item.id == updated.id);
    _birthdays[index] = updated;
    await _persist();
  }

  Future<void> _remove(Birthday birthday) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: Text('Remove ${birthday.name}?'), content: const Text('Their birthday and local history will be removed from this device.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))])) ?? false;
    if (!confirmed) return;
    _birthdays.removeWhere((item) => item.id == birthday.id);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _birthdays.where((birthday) => birthday.daysUntil() <= 30).toList();
    final later = _birthdays.where((birthday) => birthday.daysUntil() > 30).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Moments Remembered'), actions: [IconButton(onPressed: _addBirthday, tooltip: 'Add birthday', icon: const Icon(Icons.person_add_alt_1_outlined))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addBirthday, icon: const Icon(Icons.add), label: const Text('Add someone')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _birthdays.isEmpty
              ? _EmptyState(onAdd: _addBirthday)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                    children: [
                      Text('Thoughtfulness, on time.', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text('Private reminders and messages prepared by you.', style: Theme.of(context).textTheme.bodyMedium),
                      if (!_remindersEnabled) ...[
                        const SizedBox(height: 18),
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Enable birthday reminders', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              const Text('Your device can remind you even when this app is closed. Birthdays stay on this device.'),
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
                        ...upcoming.map((birthday) => _BirthdayCard(birthday: birthday, onPrepare: () => _prepare(birthday), onRemove: () => _remove(birthday))),
                      ],
                      if (later.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Text('LATER', style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.4)),
                        const SizedBox(height: 10),
                        ...later.map((birthday) => _BirthdayCard(birthday: birthday, onPrepare: () => _prepare(birthday), onRemove: () => _remove(birthday))),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.birthday, required this.onPrepare, required this.onRemove});
  final Birthday birthday;
  final VoidCallback onPrepare;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final days = birthday.daysUntil();
    final occurrence = birthday.nextOccurrence();
    final handled = birthday.isHandledFor(occurrence.year);
    final timing = days == 0 ? 'Today' : days == 1 ? 'Tomorrow' : 'In $days days';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 25, child: Text(birthday.name.trim().substring(0, 1).toUpperCase())),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(birthday.name, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text('${birthday.relationship} · ${DateFormat('d MMM').format(occurrence)}'), const SizedBox(height: 6), Text(handled ? 'Handled for ${occurrence.year}' : timing, style: TextStyle(color: handled ? Colors.green.shade700 : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700))])),
            PopupMenuButton<String>(onSelected: (value) => value == 'prepare' ? onPrepare() : onRemove(), itemBuilder: (_) => [const PopupMenuItem(value: 'prepare', child: Text('Prepare message')), const PopupMenuItem(value: 'remove', child: Text('Remove'))]),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cake_outlined, size: 64, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 20), Text('Never let “I meant to message” happen again.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 10), const Text('Add a birthday. This device will remind you early and help prepare a message that still sounds like you.', textAlign: TextAlign.center), const SizedBox(height: 24), FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add the first birthday'))])));
}
