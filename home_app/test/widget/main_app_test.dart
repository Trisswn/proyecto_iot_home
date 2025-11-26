import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot_controller_2/main.dart';
import 'package:iot_controller_2/smart_home_state.dart';
import 'package:iot_controller_2/bluetooth_control_screen.dart';

void main() {
  testWidgets('Main App initializes properly and applies Theme', (WidgetTester tester) async {
    // Configurar Mock de SharedPreferences
    SharedPreferences.setMockInitialValues({});


    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SmartHomeState(),
        child: const MyApp(),
      ),
    );
    
    await tester.pumpAndSettle();

    // Verificar que el MaterialApp principal existe
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verificar que el Provider se puede encontrar
    final context = tester.element(find.byType(BluetoothControlScreen)); 
    expect(Provider.of<SmartHomeState>(context, listen: false), isNotNull);

    //Verificar propiedades del Tema (ej. Material 3 activo)
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);

    // Verificar que la pantalla inicial carga su título
    expect(find.text('Panel de Control'), findsOneWidget);
  });
}