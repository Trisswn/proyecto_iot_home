import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {
  final Map<String, String> _store = {};

  @override
  String? getString(String key) => _store[key];

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _store.clear();
    return true;
  }

  @override
  bool containsKey(String key) => _store.containsKey(key);

  @override
  Set<String> getKeys() => _store.keys.toSet();
}

void setupSharedPreferencesMock() {
  final mockPrefs = MockSharedPreferences();
  SharedPreferences.setMockInitialValues({});
  when(() => SharedPreferences.getInstance())
      .thenAnswer((_) async => mockPrefs);
}
