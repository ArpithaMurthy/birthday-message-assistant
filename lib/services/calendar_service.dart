import 'dart:convert';
import 'dart:typed_data';

import 'package:moments_remembered/models/occasion.dart';
import 'package:share_plus/share_plus.dart';

class CalendarService {
  Future<void> export(List<Occasion> occasions) async {
    final content = buildCalendar(occasions);
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      mimeType: 'text/calendar',
      name: 'moments-remembered.ics',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: const ['moments-remembered.ics'],
        subject: 'Moments Remembered calendar',
        text: 'Import these private recurring occasions into your calendar.',
      ),
    );
  }

  String buildCalendar(List<Occasion> occasions) {
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Moments Remembered//Occasions//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:Moments Remembered',
    ];
    final stamp = _dateTime(DateTime.now().toUtc());
    for (final occasion in occasions) {
      final next = occasion.nextOccurrence();
      final start = '${next.year.toString().padLeft(4, '0')}${next.month.toString().padLeft(2, '0')}${next.day.toString().padLeft(2, '0')}';
      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${_escape(occasion.id)}@moments-remembered.local',
        'DTSTAMP:$stamp',
        'DTSTART;VALUE=DATE:$start',
        'RRULE:FREQ=YEARLY',
        'SUMMARY:${_escape(occasion.calendarTitle)}',
        if (occasion.notes.trim().isNotEmpty) 'DESCRIPTION:${_escape(occasion.notes.trim())}',
        ...occasion.reminderDays.expand((days) => [
              'BEGIN:VALARM',
              'TRIGGER:${days == 0 ? 'PT9H' : '-P${days}D'}',
              'ACTION:DISPLAY',
              'DESCRIPTION:${_escape(occasion.calendarTitle)}',
              'END:VALARM',
            ]),
        'END:VEVENT',
      ]);
    }
    lines.add('END:VCALENDAR');
    return '${lines.join('\r\n')}\r\n';
  }

  String _dateTime(DateTime value) => '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}T${value.hour.toString().padLeft(2, '0')}${value.minute.toString().padLeft(2, '0')}${value.second.toString().padLeft(2, '0')}Z';

  String _escape(String value) => value.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,').replaceAll('\n', '\\n');
}
