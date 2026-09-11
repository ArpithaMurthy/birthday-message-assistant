import 'dart:convert';

import 'package:moments_remembered/models/birthday.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BirthdayRepository {
  static const _storageKey = 'birthdays.v1';

  Future<List<Birthday>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return [];
    final values = jsonDecode(encoded) as List<Object?>;
    return values
        .map((value) => Birthday.fromJson((value as Map<Object?, Object?>).cast<String, Object?>()))
        .toList();
  }

  Future<void> save(List<Birthday> birthdays) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(birthdays.map((birthday) => birthday.toJson()).toList()),
    );
  }
}
