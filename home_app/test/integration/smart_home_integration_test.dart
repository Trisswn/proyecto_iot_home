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
  group('Integration Tests - E2E with Mocks', () {
    late SmartHomeState state;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      state = SmartHomeState();
    });

    // =============== PRUEBAS E2E EXITOSAS ===============
    group('E2E Success Scenarios', () {
      test('E2E: Complete profile creation and LED state management flow',
          () async {
        // Arrange: Simular el flujo completo
        // 1. Usuario crea un perfil
        final newProfile = UserProfile(
          name: 'Living Room Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );

        // Act: Paso 1 - Agregar perfil
        state.addProfile(newProfile);
        expect(state.profiles.length, 1);

        // Act: Paso 2 - Conectar dispositivo
        state.updateConnectionState(true);
        expect(state.isConnected, true);

        // Act: Paso 3 - Establecer perfil activo
        state.setActiveProfile(newProfile);
        expect(state.activeProfile?.name, 'Living Room Profile');

        // Act: Paso 4 - Actualizar LEDs según el perfil
        state.updateAllLedStates([true, false, true]);

        // Assert: Verificar todo el flujo
        expect(state.profiles.length, 1);
        expect(state.isConnected, true);
        expect(state.activeProfile?.name, 'Living Room Profile');
        expect(state.ledStates['Sala'], true);
        expect(state.ledStates['Cocina'], false);
        expect(state.ledStates['Dormitorio'], true);
      });

      test('E2E: Profile update with LED configuration changes', () async {
        // Arrange: Crear perfil inicial
        final initialProfile = UserProfile(
          name: 'Kitchen Profile',
          ledConfigs: [
            LedConfig(areaName: 'Sala', enabled: true),
            LedConfig(areaName: 'Cocina', enabled: false),
            LedConfig(areaName: 'Dormitorio', enabled: true),
          ],
        );
        state.addProfile(initialProfile);

        // Act: Paso 1 - Activar perfil
        state.setActiveProfile(initialProfile);
        expect(state.activeProfile?.name, 'Kitchen Profile');

        // Act: Paso 2 - Actualizar perfil con nuevas configuraciones
        final updatedProfile = UserProfile(
          name: 'Kitchen Profile Updated',
          ledConfigs: [
            LedConfig(
              areaName: 'Sala',
              enabled: true,
              onInterval: 500,
              offInterval: 500,
            ),
            LedConfig(areaName: 'Cocina', enabled: true),
            LedConfig(areaName: 'Dormitorio', enabled: false),
          ],
        );
        state.updateProfile(0, updatedProfile);

        // Assert: Verificar actualización
        expect(state.profiles[0].name, 'Kitchen Profile Updated');
        expect(state.profiles[0].ledConfigs[0].onInterval, 500);
        expect(state.profiles[0].ledConfigs[1].enabled, true);
        expect(state.profiles[0].ledConfigs[2].enabled, false);
      });

      test('E2E: Sensor readings update during connected state', () async {
        // Arrange
        state.updateConnectionState(true);

        // Act: Simular lecturas de sensores en tiempo real
        state.updateSensorReadings(22.5, 55.0);
        expect(state.temperature, 22.5);
        expect(state.humidity, 55.0);

        // Act: Segunda lectura (simulando cambio de temperatura)
        state.updateSensorReadings(23.0, 56.0);
        expect(state.temperature, 23.0);
        expect(state.humidity, 56.0);

        // Assert
        expect(state.isConnected, true);
        expect(state.temperature, 23.0);
        expect(state.humidity, 56.0);
      });

      test('E2E: Multiple profiles management with active profile tracking',
          () async {
        // Arrange: Crear múltiples perfiles
        final profiles = [
          UserProfile(
            name: 'Profile 1 - Morning',
            ledConfigs: UserProfile.getDefaultLedConfigs(),
          ),
          UserProfile(
            name: 'Profile 2 - Night',
            ledConfigs: UserProfile.getDefaultLedConfigs(),
          ),
          UserProfile(
            name: 'Profile 3 - Away',
            ledConfigs: UserProfile.getDefaultLedConfigs(),
          ),
        ];

        // Act: Agregar todos los perfiles
        for (final p in profiles) {
          state.addProfile(p);
        }
        expect(state.profiles.length, 3);

        // Act: Seleccionar el segundo perfil
        state.setActiveProfile(state.profiles[1]);
        expect(state.activeProfile?.name, 'Profile 2 - Night');

        // Act: Borrar el primer perfil
        state.deleteProfile(0);
        expect(state.profiles.length, 2);

        // Assert: El perfil activo aún debe ser válido
        expect(state.activeProfile?.name, 'Profile 2 - Night');
        expect(state.profiles[0].name, 'Profile 2 - Night');
      });

      test('E2E: LED state synchronization across reconnection',
          () async {
        // Arrange: Conectar y establecer LEDs
        state.updateConnectionState(true);
        state.updateAllLedStates([true, true, false]);

        // Assert: Estados iniciales
        expect(state.ledStates['Sala'], true);
        expect(state.ledStates['Cocina'], true);
        expect(state.ledStates['Dormitorio'], false);

        // Act: Desconectar
        state.updateConnectionState(false);

        // Assert: Todos los LEDs deben estar en false tras desconectar
        expect(state.ledStates['Sala'], false);
        expect(state.ledStates['Cocina'], false);
        expect(state.ledStates['Dormitorio'], false);

        // Act: Reconectar
        state.updateConnectionState(true);

        // Act: Restaurar estados
        state.updateAllLedStates([false, true, true]);

        // Assert: Nuevos estados
        expect(state.ledStates['Sala'], false);
        expect(state.ledStates['Cocina'], true);
        expect(state.ledStates['Dormitorio'], true);
      });
    });

    // =============== PRUEBAS E2E CON ERRORES Y MANEJO DE EXCEPCIONES ===============
    group('E2E Error Handling Scenarios', () {
      test(
          'E2E: Handle invalid LED area name gracefully without crashing',
          () {
        // Arrange
        state.updateConnectionState(true);

        // Act: Intentar actualizar LED con nombre inválido
        state.setLedState('InvalidArea', true);

        // Assert: El estado debe permanecer intacto
        expect(state.isConnected, true);
        expect(state.ledStates['Sala'], false);
        expect(state.ledStates['Cocina'], false);
        expect(state.ledStates['Dormitorio'], false);
      });

      test(
          'E2E: Handle mismatched LED states list length gracefully',
          () {
        // Arrange
        state.updateConnectionState(true);
        final initialSala = state.ledStates['Sala'];

        // Act: Intentar actualizar con lista de tamaño incorrecto
        state.updateAllLedStates([true, false]); // Falta un elemento

        // Assert: Los estados no deben cambiar
        expect(state.ledStates['Sala'], initialSala);
        expect(state.ledStates['Cocina'], false);
        expect(state.ledStates['Dormitorio'], false);
      });

      test('E2E: Safe handling of active profile deletion',
          () {
        // Arrange: Crear y activar perfil
        final profile = UserProfile(
          name: 'Profile to Delete',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.addProfile(profile);
        state.setActiveProfile(profile);
        expect(state.activeProfile, isNotNull);

        // Act: Borrar el perfil activo
        state.deleteProfile(0);

        // Assert: El perfil activo debe ser null
        expect(state.activeProfile, isNull);
        expect(state.profiles.isEmpty, true);
      });

      test('E2E: Safe handling of out-of-bounds profile index',
          () {
        // Arrange
        final profile = UserProfile(
          name: 'Test Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.addProfile(profile);

        // Act: Intentar actualizar con índice inválido
        final initialCount = state.profiles.length;
        state.updateProfile(10, profile);
        state.deleteProfile(10);

        // Assert: Los perfiles no deben cambiar
        expect(state.profiles.length, initialCount);
      });

      test(
          'E2E: Status message updates on error and recovery scenarios',
          () {
        // Act: Simular error
        state.setStatusMessage('Error: No device found');
        expect(state.statusMessage, contains('Error'));

        // Act: Simular recuperación
        state.updateConnectionState(true);
        state.setStatusMessage('Connected successfully');

        // Assert
        expect(state.statusMessage, 'Connected successfully');
        expect(state.isConnected, true);
      });

      test(
          'E2E: Disconnect clears all state safely (no exceptions)',
          () {
        // Arrange: Establecer estado complejo
        state.updateConnectionState(true);
        state.updateSensorReadings(25.0, 60.0);
        state.updateAllLedStates([true, true, false]);
        final profile = UserProfile(
          name: 'Test',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        );
        state.setActiveProfile(profile);

        // Act: Desconectar (debe limpiar todo sin excepciones)
        state.updateConnectionState(false);

        // Assert: Todo debe estar en estado "limpio"
        expect(state.isConnected, false);
        expect(state.temperature.isNaN, true);
        expect(state.humidity.isNaN, true);
        expect(state.ledStates.values.every((v) => v == false), true);
        expect(state.activeProfile, isNull);
      });
    });

    // =============== PRUEBAS DE LÓGICA DE PERFILES Y CONFIGURACIÓN ===============
    group('E2E Profile Configuration Logic', () {
      test('E2E: Profile ESP32 config string generation', () {
        // Arrange: Crear perfil con configuración personalizada
        final profile = UserProfile(
          name: 'TestProfile',
          ledConfigs: [
            LedConfig(
              areaName: 'Sala',
              enabled: true,
              onInterval: 500,
              offInterval: 500,
              autoOffDuration: 0,
            ),
            LedConfig(
              areaName: 'Cocina',
              enabled: false,
              onInterval: 0,
              offInterval: 0,
              autoOffDuration: 30,
            ),
            LedConfig(
              areaName: 'Dormitorio',
              enabled: true,
              onInterval: 0,
              offInterval: 0,
              autoOffDuration: 0,
            ),
          ],
          sensorsEnabled: true,
          sensorReadInterval: 2000,
        );

        // Act
        final configString = profile.generateEsp32ConfigString();

        // Assert: Verificar formato correcto
        expect(configString.contains('NAME:TestProfile'), true);
        expect(configString.contains('||'), true);
        expect(configString.contains('L0,1,500,500,0'), true);
        expect(configString.contains('L1,0,0,0,30'), true);
        expect(configString.contains('L2,1,0,0,0'), true);
        expect(configString.contains('S,1,2000'), true);
      });

      test('E2E: Profile LED config serialization round-trip', () {
        // Arrange: Crear perfil original
        final originalProfile = UserProfile(
          name: 'Serialization Test',
          ledConfigs: [
            LedConfig(areaName: 'Sala', enabled: true, onInterval: 100),
            LedConfig(areaName: 'Cocina', enabled: false),
            LedConfig(areaName: 'Dormitorio', enabled: true),
          ],
        );

        // Act: Convertir a JSON y de vuelta
        final json = originalProfile.toJson();
        final deserializedProfile = UserProfile.fromJson(json);

        // Assert: Verificar que los datos se mantienen
        expect(deserializedProfile.name, 'Serialization Test');
        expect(deserializedProfile.ledConfigs.length, 3);
        expect(deserializedProfile.ledConfigs[0].areaName, 'Sala');
        expect(deserializedProfile.ledConfigs[0].enabled, true);
        expect(deserializedProfile.ledConfigs[0].onInterval, 100);
        expect(deserializedProfile.ledConfigs[1].enabled, false);
      });
    });
  });
}
