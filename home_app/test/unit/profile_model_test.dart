import 'package:flutter_test/flutter_test.dart';
import 'package:iot_controller_2/profile_model.dart';

void main() {
  group('LedConfig Unit Tests', () {
    test('should correctly identify modes', () {
      final manual = LedConfig(areaName: 'Sala', enabled: true);
      expect(manual.isManualMode, true);
      expect(manual.isBlinkingMode, false);
      expect(manual.isAutoOffMode, false);

      final blink = LedConfig(areaName: 'Sala', onInterval: 100, offInterval: 100);
      expect(blink.isBlinkingMode, true);
      expect(blink.isManualMode, false);

      final autoOff = LedConfig(areaName: 'Sala', autoOffDuration: 10);
      expect(autoOff.isAutoOffMode, true);
      expect(autoOff.isManualMode, false);
    });

    test('toJson and fromJson should work correctly', () {
      final config = LedConfig(areaName: 'Test', onInterval: 500);
      final json = config.toJson();
      final newConfig = LedConfig.fromJson(json);

      expect(newConfig.areaName, 'Test');
      expect(newConfig.onInterval, 500);
    });
  });

  group('UserProfile Unit Tests', () {
    test('generateEsp32ConfigString formats correctly', () {
      final profile = UserProfile(
        name: 'TestProfile',
        ledConfigs: [
          LedConfig(areaName: 'L1', enabled: true, onInterval: 100, offInterval: 100), // Blink
          LedConfig(areaName: 'L2', enabled: false), // Disabled
          LedConfig(areaName: 'L3', enabled: true, autoOffDuration: 60), // AutoOff
        ],
        sensorsEnabled: true,
        sensorReadInterval: 5000,
      );

      final configStr = profile.generateEsp32ConfigString();
      
      // Verificamos que la cadena contenga la estructura esperada por el Arduino
      expect(configStr, contains('NAME:TestProfile||'));
      // L0: Enabled(1), On(100), Off(100), Auto(0)
      expect(configStr, contains('L0,1,100,100,0')); 
      // L1: Enabled(0), On(0), Off(0), Auto(0)
      expect(configStr, contains('L1,0,0,0,0'));
      // L2: Enabled(1), On(0), Off(0), Auto(60)
      expect(configStr, contains('L2,1,0,0,60'));
      // Sensors: Enabled(1), Interval(5000)
      expect(configStr, contains('S,1,5000'));
    });

    test('fromJson handles missing ledConfigs gracefully', () {
      final json = {
        'name': 'Incomplete Profile',
        'sensorsEnabled': true,
        // 'ledConfigs' falta intencionalmente
      };

      final profile = UserProfile.fromJson(json);
      
      expect(profile.name, 'Incomplete Profile');
      // Debe haber cargado los defaults
      expect(profile.ledConfigs.length, 3); 
      expect(profile.ledConfigs[0].areaName, 'Sala');
    });
  });
}