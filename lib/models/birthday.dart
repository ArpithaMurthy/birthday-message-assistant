enum MessageChannel { sms, whatsapp, share }

enum MessageTone { warm, playful, short, formal }

class Birthday {
  const Birthday({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    required this.relationship,
    required this.channel,
    this.phoneNumber = '',
    this.notes = '',
    this.reminderDays = const [7, 1, 0],
    this.lastHandledYear,
  });

  final String id;
  final String name;
  final int month;
  final int day;
  final String relationship;
  final MessageChannel channel;
  final String phoneNumber;
  final String notes;
  final List<int> reminderDays;
  final int? lastHandledYear;

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

  Birthday copyWith({int? lastHandledYear, bool clearHandledYear = false}) {
    return Birthday(
      id: id,
      name: name,
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
        'name': name,
        'month': month,
        'day': day,
        'relationship': relationship,
        'channel': channel.name,
        'phoneNumber': phoneNumber,
        'notes': notes,
        'reminderDays': reminderDays,
        'lastHandledYear': lastHandledYear,
      };

  factory Birthday.fromJson(Map<String, Object?> json) => Birthday(
        id: json['id']! as String,
        name: json['name']! as String,
        month: json['month']! as int,
        day: json['day']! as int,
        relationship: json['relationship']! as String,
        channel: MessageChannel.values.byName(json['channel']! as String),
        phoneNumber: (json['phoneNumber'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
        reminderDays: ((json['reminderDays'] as List<Object?>?) ?? [7, 1, 0]).cast<int>(),
        lastHandledYear: json['lastHandledYear'] as int?,
      );
}

bool _isLeapYear(int year) => year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
