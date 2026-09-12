import 'dart:convert';

import 'package:moments_remembered/models/occasion.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OccasionRepository {
  static const _storageKey = 'occasions.v2';
  static const _legacyStorageKey = 'birthdays.v1';

  Future<List<Occasion>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey) ?? preferences.getString(_legacyStorageKey);
    if (encoded == null) return [];
    final values = jsonDecode(encoded) as List<Object?>;
    final occasions = values
        .map((value) => Occasion.fromJson((value as Map<Object?, Object?>).cast<String, Object?>()))
        .toList();
    if (!preferences.containsKey(_storageKey)) await save(occasions);
    return occasions;
  }

  Future<void> save(List<Occasion> occasions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(occasions.map((occasion) => occasion.toJson()).toList()),
    );
  }
}
