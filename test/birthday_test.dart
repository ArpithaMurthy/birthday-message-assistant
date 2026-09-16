import 'package:flutter_test/flutter_test.dart';
import 'package:moments_remembered/models/occasion.dart';
import 'package:moments_remembered/services/calendar_service.dart';
import 'package:moments_remembered/services/data_transfer_service.dart';
import 'package:moments_remembered/services/message_service.dart';

void main() {
  const birthday = Occasion(
    id: '1',
    title: 'Birthday',
    personName: 'Ada Lovelace',
    type: OccasionType.birthday,
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
    const leapBirthday = Occasion(id: '2', title: 'Birthday', personName: 'Lea', type: OccasionType.birthday, month: 2, day: 29, relationship: 'Friend', channel: MessageChannel.share);
    expect(leapBirthday.nextOccurrence(DateTime(2027)), DateTime(2027, 2, 28));
  });

  test('drafts remain editable and include the first name', () {
    final message = MessageService().draft(birthday, MessageTone.warm);
    expect(message, contains('Ada'));
    expect(message, contains('Happy birthday'));
    expect(message, contains('I wish you lots of happiness, good health, joy and many wonderful moments'));
  });

  test('default message overrides generated drafts', () {
    const occasion = Occasion(
      id: 'default',
      title: 'Birthday',
      personName: 'Maya',
      type: OccasionType.birthday,
      month: 9,
      day: 20,
      channel: MessageChannel.whatsapp,
      defaultMessage: 'Happy birthday Maya from my saved template!',
    );

    expect(MessageService().draft(occasion, MessageTone.formal), 'Happy birthday Maya from my saved template!');
  });

  test('creates occasion-specific anniversary drafts', () {
    const anniversary = Occasion(id: '3', title: 'Wedding anniversary', personName: 'Maya', type: OccasionType.anniversary, month: 5, day: 12, channel: MessageChannel.share);
    expect(MessageService().draft(anniversary, MessageTone.short), contains('Happy anniversary, Maya'));
  });

  test('exports yearly calendar events with alarms', () {
    final calendar = CalendarService().buildCalendar([birthday]);
    expect(calendar, contains('RRULE:FREQ=YEARLY'));
    expect(calendar, contains('SUMMARY:Birthday — Ada Lovelace'));
    expect(calendar, contains('TRIGGER:-P7D'));
    expect(calendar, contains('TRIGGER:-P1D'));
    expect(calendar, contains('TRIGGER:PT9H'));
  });

  test('imports CSV with friendly dates and channels', () {
    final occasions = DataTransferService().importText('''
type,title,date,person,relationship,channel,phone,notes,default_message
Birthday,Birthday,Jan 9,Prashant Msft,,WhatsApp,+886912345678,,Happy birthday Prashant!
Anniversary,Wedding anniversary,Dec 11th,atta mava,,LINE,,,
Birthday,Birthday,7/12,Anvay,,Share,,,
''');

    expect(occasions, hasLength(3));
    expect(occasions.first.month, 1);
    expect(occasions.first.day, 9);
    expect(occasions.first.channel, MessageChannel.whatsapp);
    expect(occasions.first.defaultMessage, 'Happy birthday Prashant!');
    expect(occasions[1].type, OccasionType.anniversary);
    expect(occasions[1].channel, MessageChannel.line);
  });

  test('exports backup JSON with default messages', () {
    final backup = DataTransferService().exportJson([
      birthday.copyWith(id: 'backup'),
    ]);

    expect(backup, contains('"schemaVersion": 1'));
    expect(backup, contains('"personName": "Ada Lovelace"'));
  });

  test('round-trips LINE channel and default message through JSON', () {
    final restored = Occasion.fromJson({
      'id': 'line',
      'title': 'Birthday',
      'personName': 'Maya',
      'type': 'birthday',
      'month': 9,
      'day': 20,
      'channel': 'line',
      'defaultMessage': 'Happy birthday Maya!',
    });

    expect(restored.channel, MessageChannel.line);
    expect(restored.defaultMessage, 'Happy birthday Maya!');
  });
}
