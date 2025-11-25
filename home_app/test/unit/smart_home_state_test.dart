import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot_controller_2/smart_home_state.dart';
import 'package:iot_controller_2/profile_model.dart';

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

void main() {
  group('SmartHomeState - Unit Tests', () {
    late SmartHomeState state;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      state = SmartHomeState();
    });

    group('Connection State Tests', () {
      test('Initial connection state should be false', () {
        final isConnected = state.isConnected;
        expect(isConnected, false);
      });

      test('updateConnectionState should set isConnected to true', () {
        expect(state.isConnected, false);
        state.updateConnectionState(true);
        expect(state.isConnected, true);
      });

      test('updateConnectionState(true) should update status message', () {
        final initialMessage = state.statusMessage;
        state.updateConnectionState(true);
        final connectedMessage = state.statusMessage;
        expect(initialMessage, contains('Busca'));
        expect(connectedMessage, isNotEmpty);
      });

      test(
          'updateConnectionState(false) should reset temperature and humidity',
          () {
        state.updateSensorReadings(25.0, 60.0);
        state.updateConnectionState(false);
        expect(state.temperature.isNaN, true);
        expect(state.humidity.isNaN, true);
      });

      test('updateConnectionState(false) should reset all LED states to false',
          () {
        state.setLedState('Sala', true);
        state.setLedState('Cocina', true);
        expect(state.ledStates['Sala'], true);
        expect(state.ledStates['Cocina'], true);
        state.updateConnectionState(false);
        expect(state.ledStates['Sala'], false);
        expect(state.ledStates['Cocina'], false);
        expect(state.ledStates['Dormitorio'], false);
      });

      test('updateConnectionState(false) should clear active profile', () {
        final profile = UserProfile(
          name: 'Test Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.setActiveProfile(profile);
        expect(state.activeProfile, isNotNull);
        state.updateConnectionState(false);
        expect(state.activeProfile, isNull);
      });
    });

    group('LED State Tests', () {
      test('setLedState should turn on LED for valid area', () {
        expect(state.ledStates['Sala'], false);
        state.setLedState('Sala', true);
        expect(state.ledStates['Sala'], true);
      });

      test('setLedState should turn off LED for valid area', () {
        state.setLedState('Sala', true);
        expect(state.ledStates['Sala'], true);
        state.setLedState('Sala', false);
        expect(state.ledStates['Sala'], false);
      });

      test('setLedState should not affect other LEDs', () {
        expect(state.ledStates['Cocina'], false);
        state.setLedState('Sala', true);
        expect(state.ledStates['Sala'], true);
        expect(state.ledStates['Cocina'], false);
        expect(state.ledStates['Dormitorio'], false);
      });

      test('updateAllLedStates should update all LED states correctly', () {
        final allTrue = [true, true, true];
        state.updateAllLedStates(allTrue);
        expect(state.ledStates['Sala'], true);
        expect(state.ledStates['Cocina'], true);
        expect(state.ledStates['Dormitorio'], true);
      });

      test('updateAllLedStates with mixed states', () {
        final mixedStates = [true, false, true];
        state.updateAllLedStates(mixedStates);
        expect(state.ledStates['Sala'], true);
        expect(state.ledStates['Cocina'], false);
        expect(state.ledStates['Dormitorio'], true);
      });

      test('ledAreaNames should return list of all LED area names', () {
        final areaNames = state.ledAreaNames;
        expect(areaNames.length, 3);
        expect(areaNames.contains('Sala'), true);
        expect(areaNames.contains('Cocina'), true);
        expect(areaNames.contains('Dormitorio'), true);
      });

      test('ledStates should return unmodifiable map', () {
        final ledStates = state.ledStates;
        expect(
          () => ledStates['Sala'] = true,
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('Sensor Readings Tests', () {
      test('Initial temperature should be NaN', () {
        final temp = state.temperature;
        expect(temp.isNaN, true);
      });

      test('Initial humidity should be NaN', () {
        final humidity = state.humidity;
        expect(humidity.isNaN, true);
      });

      test('updateSensorReadings should set valid temperature and humidity', () {
        const tempValue = 25.5;
        const humidityValue = 65.0;
        state.updateSensorReadings(tempValue, humidityValue);
        expect(state.temperature, tempValue);
        expect(state.humidity, humidityValue);
      });

      test('updateSensorReadings with extreme temperature values', () {
        const maxTemp = 100.0;
        const minTemp = -50.0;
        state.updateSensorReadings(maxTemp, 50.0);
        expect(state.temperature, maxTemp);
        state.updateSensorReadings(minTemp, 50.0);
        expect(state.temperature, minTemp);
      });

      test('updateSensorReadings with extreme humidity values', () {
        const maxHumidity = 100.0;
        const minHumidity = 0.0;
        state.updateSensorReadings(25.0, maxHumidity);
        expect(state.humidity, maxHumidity);
        state.updateSensorReadings(25.0, minHumidity);
        expect(state.humidity, minHumidity);
      });

      test('setStatusMessage should update status message', () {
        const newMessage = 'Conectado al dispositivo';
        state.setStatusMessage(newMessage);
        expect(state.statusMessage, newMessage);
      });
    });

    group('Profile Tests', () {
      test('Initial profiles list should be empty', () {
        final profiles = state.profiles;
        expect(profiles.isEmpty, true);
      });

      test('addProfile should add profile to list', () {
        final profile = UserProfile(
          name: 'Test Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.addProfile(profile);
        expect(state.profiles.length, 1);
        expect(state.profiles[0].name, 'Test Profile');
      });

      test('addProfile should initialize LED configs if empty', () {
        final profile = UserProfile(
          name: 'Empty Configs Profile',
          ledConfigs: [],
        );
        state.addProfile(profile);
        expect(state.profiles[0].ledConfigs.isNotEmpty, true);
        expect(state.profiles[0].ledConfigs.length, 3);
      });

      test('deleteProfile should remove profile from list', () {
        final profile1 = UserProfile(
          name: 'Profile 1',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        final profile2 = UserProfile(
          name: 'Profile 2',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.addProfile(profile1);
        state.addProfile(profile2);
        expect(state.profiles.length, 2);
        state.deleteProfile(0);
        expect(state.profiles.length, 1);
        expect(state.profiles[0].name, 'Profile 2');
      });

      test('deleteProfile should clear active profile if it was deleted', () {
        final profile = UserProfile(
          name: 'Profile to Delete',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.addProfile(profile);
        state.setActiveProfile(profile);
        expect(state.activeProfile, isNotNull);
        state.deleteProfile(0);
        expect(state.activeProfile, isNull);
      });

      test('setActiveProfile should set the active profile', () {
        final profile = UserProfile(
          name: 'Active Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.setActiveProfile(profile);
        expect(state.activeProfile, profile);
        expect(state.activeProfile?.name, 'Active Profile');
      });

      test('updateProfile should update profile at specific index', () {
        final profile1 = UserProfile(
          name: 'Original',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        final updatedProfile = UserProfile(
          name: 'Updated',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.addProfile(profile1);
        state.updateProfile(0, updatedProfile);
        expect(state.profiles[0].name, 'Updated');
      });
    });
  });
}
