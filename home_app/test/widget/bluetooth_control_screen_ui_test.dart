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
    // Solución "Found 0 widgets": Aumentar tamaño de pantalla física para ver todo el contenido
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
    
    // Mensaje de placeholder de sensores
    expect(find.text('Conecta el dispositivo para ver los sensores.'), findsOneWidget);
    
    // Solución error "icon is not defined": Usar find.byIcon
    expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);

    // Limpieza
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Shows "Connected" state with sensor data', (WidgetTester tester) async {
    // Aumentar tamaño de pantalla
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
    
    // Verificar datos de sensores
    expect(find.text('24.5'), findsOneWidget);
    expect(find.text('60.0'), findsOneWidget);
    
    // Verificar servo
    expect(find.text('Puerta Automática'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}