import 'package:flutter/material.dart';
import 'package:moments_remembered/models/occasion.dart';
import 'package:uuid/uuid.dart';

class OccasionForm extends StatefulWidget {
  const OccasionForm({super.key});

  @override
  State<OccasionForm> createState() => _OccasionFormState();
}

class _OccasionFormState extends State<OccasionForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController(text: OccasionType.birthday.defaultTitle);
  final _personName = TextEditingController();
  final _relationship = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  final _defaultMessage = TextEditingController();
  final _actionUrl = TextEditingController();
  DateTime _date = DateTime(DateTime.now().year, 1, 1);
  String _module = 'Occasions';
  String _repeat = 'yearly';
  OccasionType _type = OccasionType.birthday;
  MessageChannel _channel = MessageChannel.share;
  static const _moduleDefaults = {
    'Occasions': OccasionType.birthday,
    'Documents & renewals': OccasionType.custom,
    'Visa & admin': OccasionType.custom,
    'Home maintenance': OccasionType.custom,
    'Subscriptions & bills': OccasionType.custom,
    'Gift planning': OccasionType.custom,
    'Job search': OccasionType.custom,
    'Family care': OccasionType.custom,
  };

  @override
  void dispose() {
    _title.dispose();
    _personName.dispose();
    _relationship.dispose();
    _phone.dispose();
    _notes.dispose();
    _defaultMessage.dispose();
    _actionUrl.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: 'Choose the occasion date',
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _changeType(OccasionType? type) {
    if (type == null) return;
    final oldDefault = _type.defaultTitle;
    setState(() {
      _type = type;
      if (_title.text.trim().isEmpty || _title.text == oldDefault) {
        _title.text = type.defaultTitle;
      }
      if (type == OccasionType.newYear) _date = DateTime(DateTime.now().year, 1, 1);
    });
  }

  void _changeModule(String? module) {
    if (module == null) return;
    final defaultType = _moduleDefaults[module] ?? OccasionType.custom;
    setState(() {
      _module = module;
      _type = defaultType;
      _title.text = defaultType == OccasionType.custom ? module : defaultType.defaultTitle;
      _repeat = module == 'Subscriptions & bills'
          ? 'monthly'
          : module == 'Occasions'
              ? 'yearly'
              : 'none';
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Occasion(
        id: const Uuid().v4(),
        title: _title.text.trim(),
        personName: _personName.text.trim(),
        type: _type,
        month: _date.month,
        day: _date.day,
        module: _module,
        relationship: _relationship.text.trim(),
        phoneNumber: _phone.text.trim(),
        notes: _notes.text.trim(),
        defaultMessage: _defaultMessage.text.trim(),
        repeat: _repeat,
        actionUrl: _actionUrl.text.trim(),
        channel: _channel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add an occasion')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('What do you want to remember?', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _module,
                decoration: const InputDecoration(labelText: 'Module', prefixIcon: Icon(Icons.dashboard_customize_outlined)),
                items: _moduleDefaults.keys.map((module) => DropdownMenuItem(value: module, child: Text(module))).toList(),
                onChanged: _changeModule,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<OccasionType>(
                key: ValueKey(_type),
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.event_outlined)),
                items: OccasionType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
                onChanged: _changeType,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Occasion title', hintText: 'Birthday, wedding anniversary, Diwali…', prefixIcon: Icon(Icons.celebration_outlined)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Add an occasion title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _personName,
                decoration: const InputDecoration(labelText: 'Person or group (optional)', hintText: 'Maya, Mum and Dad, Team…', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _relationship,
                decoration: const InputDecoration(labelText: 'Relationship/category (optional)', hintText: 'Friend, passport, home, subscription…', prefixIcon: Icon(Icons.favorite_border)),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Date'),
                subtitle: Text('${_date.day}/${_date.month}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _chooseDate,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<MessageChannel>(
                initialValue: _channel,
                decoration: const InputDecoration(labelText: 'Preferred channel', prefixIcon: Icon(Icons.send_outlined)),
                items: MessageChannel.values.map((channel) => DropdownMenuItem(value: channel, child: Text(channel.label))).toList(),
                onChanged: (value) => setState(() => _channel = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number (optional)', hintText: 'Include country code for WhatsApp', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey(_repeat),
                initialValue: _repeat,
                decoration: const InputDecoration(labelText: 'Repeat', prefixIcon: Icon(Icons.repeat_outlined)),
                items: const [
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'none', child: Text('One time')),
                ],
                onChanged: (value) => setState(() => _repeat = value ?? 'none'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _actionUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Action link (optional)', hintText: 'https://...', prefixIcon: Icon(Icons.link_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Personal note (optional)', hintText: 'A memory or detail to mention', prefixIcon: Icon(Icons.edit_note)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _defaultMessage,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Default message (optional)',
                  hintText: 'Use this exact draft when preparing this occasion',
                  prefixIcon: Icon(Icons.message_outlined),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Save occasion')),
            ],
          ),
        ),
      ),
    );
  }
}
