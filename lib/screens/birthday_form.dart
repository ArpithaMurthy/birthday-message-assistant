import 'package:flutter/material.dart';
import 'package:moments_remembered/models/birthday.dart';
import 'package:uuid/uuid.dart';

class BirthdayForm extends StatefulWidget {
  const BirthdayForm({super.key});

  @override
  State<BirthdayForm> createState() => _BirthdayFormState();
}

class _BirthdayFormState extends State<BirthdayForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _relationship = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime(1990);
  MessageChannel _channel = MessageChannel.sms;

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Choose their birthday',
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Birthday(
        id: const Uuid().v4(),
        name: _name.text.trim(),
        month: _date.month,
        day: _date.day,
        relationship: _relationship.text.trim(),
        phoneNumber: _phone.text.trim(),
        notes: _notes.text.trim(),
        channel: _channel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add someone')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Who do you want to remember?', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Add a name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _relationship,
                decoration: const InputDecoration(labelText: 'Relationship', hintText: 'Friend, sister, colleague…', prefixIcon: Icon(Icons.favorite_border)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Add a relationship' : null,
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Birthday'),
                subtitle: Text('${_date.day}/${_date.month}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _chooseDate,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<MessageChannel>(
                initialValue: _channel,
                decoration: const InputDecoration(labelText: 'Preferred channel', prefixIcon: Icon(Icons.send_outlined)),
                items: MessageChannel.values.map((channel) => DropdownMenuItem(value: channel, child: Text(channel.name == 'sms' ? 'SMS / iMessage' : channel.name == 'whatsapp' ? 'WhatsApp' : 'Share sheet'))).toList(),
                onChanged: (value) => setState(() => _channel = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number (optional)', hintText: 'Include country code for WhatsApp', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Personal note (optional)', hintText: 'A memory, interest, or detail for the message', prefixIcon: Icon(Icons.edit_note)),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Save birthday')),
            ],
          ),
        ),
      ),
    );
  }
}
