import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:iot_controller_2/smart_home_state.dart';
import 'package:iot_controller_2/bluetooth_control_screen.dart';
import 'package:iot_controller_2/profile_model.dart';

class MockSmartHomeState extends Mock implements SmartHomeState {}

void main() {
  late MockSmartHomeState mockState;

  setUp(() {
    mockState = MockSmartHomeState();
    // Valores por defecto seguros
    when(() => mockState.ledAreaNames).thenReturn(['Sala', 'Cocina', 'Dormitorio']);
    when(() => mockState.ledStates).thenReturn({'Sala': false, 'Cocina': false, 'Dormitorio': false});
    when(() => mockState.profiles).thenReturn([]);
    when(() => mockState.activeProfile).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<SmartHomeState>.value(
        value: mockState,
        child: const BluetoothControlScreen(),
      ),
    );
  }

  testWidgets('Shows "Desconectado" state correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Arrange
    when(() => mockState.isConnected).thenReturn(false);
    when(() => mockState.statusMessage).thenReturn('Desconectado');
    when(() => mockState.temperature).thenReturn(double.nan);
    when(() => mockState.humidity).thenReturn(double.nan);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.text('Desconectado'), findsWidgets);
    expect(find.text('Buscar y Conectar'), findsOneWidget);
    expect(find.text('Conecta el dispositivo para ver los sensores.'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Shows "Connected" state with sensor data', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Arrange
    when(() => mockState.isConnected).thenReturn(true);
    when(() => mockState.statusMessage).thenReturn('Conectado');
    when(() => mockState.temperature).thenReturn(24.5);
    when(() => mockState.humidity).thenReturn(60.0);
    
    final profile = UserProfile(name: 'Test', ledConfigs: UserProfile.getDefaultLedConfigs());
    when(() => mockState.activeProfile).thenReturn(profile);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.text('Conectado'), findsOneWidget);
    expect(find.text('Desconectar'), findsOneWidget);
    expect(find.text('24.5'), findsOneWidget);
    expect(find.text('60.0'), findsOneWidget);
    
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Displays Servo Control and handles tap UI logic', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Arrange: Conectado
    when(() => mockState.isConnected).thenReturn(true);
    when(() => mockState.statusMessage).thenReturn('Listo');
    when(() => mockState.activeProfile).thenReturn(null); 
    // Simular temperatura/humedad para evitar errores de renderizado
    when(() => mockState.temperature).thenReturn(20.0);
    when(() => mockState.humidity).thenReturn(50.0);

    await tester.pumpWidget(createWidgetUnderTest());

    // Assert: Botón de Puerta visible
    expect(find.text('Puerta Automática'), findsOneWidget);
    expect(find.text('Abrir/Cerrar'), findsOneWidget);

    // Act: Tocar botón
    // Esto intentará llamar a _writeToServoCharacteristic. 
    // Como no estamos mockeando FlutterBluePlus a nivel de canal, esto podría generar 
    // una excepción controlada o un log, pero lo importante es que el código UI se ejecuta.
    await tester.tap(find.text('Abrir/Cerrar'));
    await tester.pump();
    
    // No esperamos un resultado específico (como un dialogo) porque requeriría mockear FBP,
    // pero aseguramos que el widget es interactivo y no crashea la prueba.
    
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Handles LED tap when disabled by profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    
    // Arrange: Conectado pero LED 'Sala' deshabilitado en perfil
    when(() => mockState.isConnected).thenReturn(true);
    when(() => mockState.statusMessage).thenReturn('Conectado');
    when(() => mockState.temperature).thenReturn(20.0);
    when(() => mockState.humidity).thenReturn(50.0);

    final profile = UserProfile(
      name: 'Test Restricted', 
      ledConfigs: [
        LedConfig(areaName: 'Sala', enabled: false), // Deshabilitado
        LedConfig(areaName: 'Cocina', enabled: true),
        LedConfig(areaName: 'Dormitorio', enabled: true),
      ]
    );
    when(() => mockState.activeProfile).thenReturn(profile);
    // Asegurar que ledStates coincida con las keys
    when(() => mockState.ledStates).thenReturn({'Sala': false, 'Cocina': false, 'Dormitorio': false});

    await tester.pumpWidget(createWidgetUnderTest());

    // Assert: Estado visual debe indicar deshabilitado
    expect(find.text('Deshab. (Perfil)'), findsOneWidget);

    // Act: Tocar tarjeta de Sala (que está deshabilitada)
    await tester.tap(find.text('Sala'));
    await tester.pump(); // Dejar que el SnackBar aparezca

    // Assert: Debe mostrar SnackBar de advertencia
    expect(find.text('LED deshabilitado por el perfil.'), findsOneWidget);
    
    addTearDown(tester.view.resetPhysicalSize);
  });
}