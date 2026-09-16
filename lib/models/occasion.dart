enum MessageChannel { share, whatsapp, line, sms }

extension MessageChannelLabel on MessageChannel {
  String get label => switch (this) {
        MessageChannel.share => 'Share',
        MessageChannel.whatsapp => 'WhatsApp',
        MessageChannel.line => 'LINE',
        MessageChannel.sms => 'SMS / iMessage',
      };
}

enum MessageTone { warm, playful, short, formal }

enum OccasionType { birthday, anniversary, newYear, holiday, custom }

extension OccasionTypeLabel on OccasionType {
  String get label => switch (this) {
        OccasionType.birthday => 'Birthday',
        OccasionType.anniversary => 'Anniversary',
        OccasionType.newYear => 'New Year',
        OccasionType.holiday => 'Holiday',
        OccasionType.custom => 'Custom occasion',
      };

  String get defaultTitle => switch (this) {
        OccasionType.birthday => 'Birthday',
        OccasionType.anniversary => 'Anniversary',
        OccasionType.newYear => 'New Year',
        OccasionType.holiday => 'Holiday',
        OccasionType.custom => 'Important occasion',
      };
}

class Occasion {
  const Occasion({
    required this.id,
    required this.title,
    required this.personName,
    required this.type,
    this.year,
    required this.month,
    required this.day,
    required this.channel,
    this.module = 'Occasions',
    this.relationship = '',
    this.phoneNumber = '',
    this.notes = '',
    this.defaultMessage = '',
    this.repeat = 'yearly',
    this.actionUrl = '',
    this.reminderDays = const [7, 1, 0],
    this.lastHandledYear,
  });

  final String id;
  final String title;
  final String personName;
  final OccasionType type;
  final int? year;
  final int month;
  final int day;
  final String module;
  final String relationship;
  final MessageChannel channel;
  final String phoneNumber;
  final String notes;
  final String defaultMessage;
  final String repeat;
  final String actionUrl;
  final List<int> reminderDays;
  final int? lastHandledYear;

  String get displayName => personName.isEmpty ? title : personName;

  String get calendarTitle => personName.isEmpty ? title : '$title — $personName';

  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
    if (repeat == 'none' && year != null) {
      return _safeDate(year!);
    }
    if (repeat == 'monthly') {
      var candidate = _safeDate(now.year, month: now.month);
      final today = DateTime(now.year, now.month, now.day);
      if (candidate.isBefore(today)) {
        final nextMonth = DateTime(now.year, now.month + 1);
        candidate = _safeDate(nextMonth.year, month: nextMonth.month);
      }
      return candidate;
    }
    var year = now.year;
    var candidate = _safeDate(year);
    final today = DateTime(now.year, now.month, now.day);
    if (candidate.isBefore(today)) {
      year += 1;
      candidate = _safeDate(year);
    }
    return candidate;
  }

  int daysUntil([DateTime? from]) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextOccurrence(now).difference(today).inDays;
  }

  bool isHandledFor(int year) => lastHandledYear == year;

  DateTime _safeDate(int targetYear, {int? month}) {
    final targetMonth = month ?? this.month;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    if (day > lastDay) {
      return DateTime(targetYear, targetMonth, lastDay);
    }
    return DateTime(targetYear, targetMonth, day);
  }

  Occasion copyWith({String? id, int? lastHandledYear, bool clearHandledYear = false}) {
    return Occasion(
      id: id ?? this.id,
      title: title,
      personName: personName,
      type: type,
      year: year,
      month: month,
      day: day,
      module: module,
      relationship: relationship,
      channel: channel,
      phoneNumber: phoneNumber,
      notes: notes,
      defaultMessage: defaultMessage,
      repeat: repeat,
      actionUrl: actionUrl,
      reminderDays: reminderDays,
      lastHandledYear: clearHandledYear ? null : lastHandledYear ?? this.lastHandledYear,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'personName': personName,
        'type': type.name,
        'year': year,
        'month': month,
        'day': day,
        'module': module,
        'relationship': relationship,
        'channel': channel.name,
        'phoneNumber': phoneNumber,
        'notes': notes,
        'defaultMessage': defaultMessage,
        'repeat': repeat,
        'actionUrl': actionUrl,
        'reminderDays': reminderDays,
        'lastHandledYear': lastHandledYear,
      };

  factory Occasion.fromJson(Map<String, Object?> json) {
    final legacyName = (json['name'] as String?) ?? '';
    final typeName = (json['type'] as String?) ?? OccasionType.birthday.name;
    return Occasion(
      id: json['id']! as String,
      title: (json['title'] as String?) ?? OccasionType.birthday.defaultTitle,
      personName: (json['personName'] as String?) ?? legacyName,
      type: _occasionTypeFromJson(typeName),
      year: json['year'] as int?,
      month: json['month']! as int,
      day: json['day']! as int,
      module: (json['module'] as String?) ?? (json['category'] as String?) ?? _moduleFromType(typeName),
      relationship: (json['relationship'] as String?) ?? '',
      channel: _channelFromJson(json['channel']),
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      defaultMessage: ((json['defaultMessage'] as String?) ?? (json['default_message'] as String?) ?? '').trim(),
      repeat: (json['repeat'] as String?) ?? _repeatFromType(typeName),
      actionUrl: ((json['actionUrl'] as String?) ?? (json['action_url'] as String?) ?? (json['url'] as String?) ?? '').trim(),
      reminderDays: ((json['reminderDays'] as List<Object?>?) ?? [7, 1, 0]).cast<int>(),
      lastHandledYear: json['lastHandledYear'] as int?,
    );
  }
}

bool _isLeapYear(int year) => year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

MessageChannel _channelFromJson(Object? value) {
  final normalized = value?.toString().trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '') ?? '';
  return switch (normalized) {
    'whatsapp' => MessageChannel.whatsapp,
    'line' => MessageChannel.line,
    'sms' || 'imessage' || 'smsimessage' => MessageChannel.sms,
    _ => MessageChannel.share,
  };
}

OccasionType _occasionTypeFromJson(String typeName) {
  for (final value in OccasionType.values) {
    if (value.name == typeName) return value;
  }
  return OccasionType.custom;
}

String _moduleFromType(String typeName) {
  return {'birthday', 'anniversary', 'newYear', 'holiday', 'custom'}.contains(typeName) ? 'Occasions' : 'Life admin';
}

String _repeatFromType(String typeName) {
  return {'birthday', 'anniversary', 'newYear', 'holiday'}.contains(typeName) ? 'yearly' : 'none';
}
