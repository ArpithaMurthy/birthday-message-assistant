enum MessageChannel { sms, whatsapp, share }

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
    required this.month,
    required this.day,
    required this.channel,
    this.relationship = '',
    this.phoneNumber = '',
    this.notes = '',
    this.reminderDays = const [7, 1, 0],
    this.lastHandledYear,
  });

  final String id;
  final String title;
  final String personName;
  final OccasionType type;
  final int month;
  final int day;
  final String relationship;
  final MessageChannel channel;
  final String phoneNumber;
  final String notes;
  final List<int> reminderDays;
  final int? lastHandledYear;

  String get displayName => personName.isEmpty ? title : personName;

  String get calendarTitle => personName.isEmpty ? title : '$title — $personName';

  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
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

  DateTime _safeDate(int year) {
    if (month == 2 && day == 29 && !_isLeapYear(year)) {
      return DateTime(year, 2, 28);
    }
    return DateTime(year, month, day);
  }

  Occasion copyWith({int? lastHandledYear, bool clearHandledYear = false}) {
    return Occasion(
      id: id,
      title: title,
      personName: personName,
      type: type,
      month: month,
      day: day,
      relationship: relationship,
      channel: channel,
      phoneNumber: phoneNumber,
      notes: notes,
      reminderDays: reminderDays,
      lastHandledYear: clearHandledYear ? null : lastHandledYear ?? this.lastHandledYear,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'personName': personName,
        'type': type.name,
        'month': month,
        'day': day,
        'relationship': relationship,
        'channel': channel.name,
        'phoneNumber': phoneNumber,
        'notes': notes,
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
      type: OccasionType.values.where((value) => value.name == typeName).firstOrNull ?? OccasionType.custom,
      month: json['month']! as int,
      day: json['day']! as int,
      relationship: (json['relationship'] as String?) ?? '',
      channel: MessageChannel.values.byName(json['channel']! as String),
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      reminderDays: ((json['reminderDays'] as List<Object?>?) ?? [7, 1, 0]).cast<int>(),
      lastHandledYear: json['lastHandledYear'] as int?,
    );
  }
}

bool _isLeapYear(int year) => year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
