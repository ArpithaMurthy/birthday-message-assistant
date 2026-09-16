import 'dart:convert';

import 'package:moments_remembered/models/occasion.dart';
import 'package:uuid/uuid.dart';

class DataTransferService {
  static const _uuid = Uuid();

  List<Occasion> importText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];
    final rows = trimmed.startsWith('{') || trimmed.startsWith('[') ? _jsonRows(trimmed) : _csvRows(trimmed);
    return rows.map(_occasionFromRow).whereType<Occasion>().toList();
  }

  String exportJson(List<Occasion> occasions) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'occasions': occasions.map((occasion) => occasion.toJson()).toList(),
    });
  }

  List<Map<String, Object?>> _jsonRows(String text) {
    final decoded = jsonDecode(text);
    if (decoded is List) return decoded.whereType<Map>().map((item) => item.cast<String, Object?>()).toList();
    if (decoded is Map && decoded['occasions'] is List) {
      return (decoded['occasions'] as List).whereType<Map>().map((item) => item.cast<String, Object?>()).toList();
    }
    return [];
  }

  List<Map<String, Object?>> _csvRows(String text) {
    final table = _parseCsv(text);
    if (table.isEmpty) return [];
    final headers = table.first.map(_normalizeHeader).toList();
    return table.skip(1).map((row) {
      return {
        for (var index = 0; index < headers.length; index += 1)
          if (headers[index].isNotEmpty) headers[index]: index < row.length ? row[index] : '',
      };
    }).toList();
  }

  Occasion? _occasionFromRow(Map<String, Object?> row) {
    final date = _parseDate(row['date']);
    if (date == null) return null;
    final type = _type(row['type']);
    return Occasion(
      id: _string(row['id']).isEmpty ? _uuid.v4() : _string(row['id']),
      title: _string(row['title']).isEmpty ? type.defaultTitle : _string(row['title']),
      personName: _string(row['person']).isEmpty ? _string(row['personName']) : _string(row['person']),
      type: type,
      month: date.month,
      day: date.day,
      relationship: _string(row['relationship']),
      channel: _channel(row['channel']),
      phoneNumber: _string(row['phone']).isEmpty ? _string(row['phoneNumber']) : _string(row['phone']),
      notes: _string(row['notes']),
      defaultMessage: _string(row['defaultMessage']).isEmpty ? _string(row['default_message']) : _string(row['defaultMessage']),
    );
  }

  DateTime? _parseDate(Object? value) {
    final raw = _string(value).toLowerCase();
    if (raw.isEmpty) return null;
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(raw);
    if (iso != null) return _safeDate(iso.group(1), iso.group(2), iso.group(3));
    final months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    var match = RegExp(r'^([a-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s*(\d{4}))?$').firstMatch(raw);
    if (match != null && months.containsKey(match.group(1))) {
      return _safeDate(match.group(3) ?? DateTime.now().year.toString(), months[match.group(1)].toString(), match.group(2));
    }
    match = RegExp(r'^(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)(?:,?\s*(\d{4}))?$').firstMatch(raw);
    if (match != null && months.containsKey(match.group(2))) {
      return _safeDate(match.group(3) ?? DateTime.now().year.toString(), months[match.group(2)].toString(), match.group(1));
    }
    match = RegExp(r'^(\d{1,2})[\/.-](\d{1,2})(?:[\/.-](\d{2,4}))?$').firstMatch(raw);
    if (match != null) {
      return _safeDate(match.group(3) ?? DateTime.now().year.toString(), match.group(1), match.group(2));
    }
    return null;
  }

  DateTime? _safeDate(String? year, String? month, String? day) {
    if (year == null || month == null || day == null) return null;
    var parsedYear = int.tryParse(year);
    final parsedMonth = int.tryParse(month);
    final parsedDay = int.tryParse(day);
    if (parsedYear == null || parsedMonth == null || parsedDay == null) return null;
    if (parsedYear < 100) parsedYear += 2000;
    if (parsedMonth == 2 && parsedDay == 29) return DateTime(2024, 2, 29);
    final date = DateTime(parsedYear, parsedMonth, parsedDay);
    if (date.year != parsedYear || date.month != parsedMonth || date.day != parsedDay) return null;
    return date;
  }

  OccasionType _type(Object? value) {
    final normalized = _normalizeHeader(_string(value));
    return switch (normalized) {
      'anniversary' || 'wedding_anniversary' => OccasionType.anniversary,
      'new_year' || 'newyear' => OccasionType.newYear,
      'holiday' => OccasionType.holiday,
      'custom' || 'custom_occasion' => OccasionType.custom,
      _ => OccasionType.birthday,
    };
  }

  MessageChannel _channel(Object? value) {
    final normalized = _normalizeHeader(_string(value)).replaceAll('_', '');
    return switch (normalized) {
      'whatsapp' => MessageChannel.whatsapp,
      'line' => MessageChannel.line,
      'sms' || 'imessage' || 'smsimessage' => MessageChannel.sms,
      _ => MessageChannel.share,
    };
  }

  List<List<String>> _parseCsv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = '';
    var quoted = false;
    for (var index = 0; index < text.length; index += 1) {
      final char = text[index];
      final next = index + 1 < text.length ? text[index + 1] : '';
      if (char == '"' && quoted && next == '"') {
        cell += '"';
        index += 1;
      } else if (char == '"') {
        quoted = !quoted;
      } else if (char == ',' && !quoted) {
        row.add(cell.trim());
        cell = '';
      } else if ((char == '\n' || char == '\r') && !quoted) {
        if (char == '\r' && next == '\n') index += 1;
        row.add(cell.trim());
        cell = '';
        if (row.any((value) => value.isNotEmpty)) rows.add(row);
        row = [];
      } else {
        cell += char;
      }
    }
    row.add(cell.trim());
    if (row.any((value) => value.isNotEmpty)) rows.add(row);
    return rows;
  }

  String _normalizeHeader(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');

  String _string(Object? value) => value?.toString().trim() ?? '';
}
