import 'package:flutter_test/flutter_test.dart';
import 'package:moments_remembered/models/birthday.dart';
import 'package:moments_remembered/services/message_service.dart';

void main() {
  const birthday = Birthday(
    id: '1',
    name: 'Ada Lovelace',
    month: 12,
    day: 10,
    relationship: 'Friend',
    channel: MessageChannel.sms,
  );

  test('calculates the next birthday in the current year', () {
    expect(birthday.nextOccurrence(DateTime(2026, 9, 11)), DateTime(2026, 12, 10));
    expect(birthday.daysUntil(DateTime(2026, 12, 9)), 1);
  });

  test('rolls a past birthday into the next year', () {
    expect(birthday.nextOccurrence(DateTime(2026, 12, 11)), DateTime(2027, 12, 10));
  });

  test('uses February 28 for leap-day birthdays in ordinary years', () {
    const leapBirthday = Birthday(id: '2', name: 'Lea', month: 2, day: 29, relationship: 'Friend', channel: MessageChannel.share);
    expect(leapBirthday.nextOccurrence(DateTime(2027)), DateTime(2027, 2, 28));
  });

  test('drafts remain editable and include the first name', () {
    final message = MessageService().draft(birthday, MessageTone.warm);
    expect(message, contains('Ada'));
    expect(message, contains('Happy birthday'));
  });
}
