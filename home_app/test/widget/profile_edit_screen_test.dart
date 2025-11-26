import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:iot_controller_2/smart_home_state.dart';
import 'package:iot_controller_2/profile_edit_screen.dart';
import 'package:iot_controller_2/profile_model.dart';
import 'package:iot_controller_2/app_colors.dart';

// Mock del estado
class MockSmartHomeState extends Mock implements SmartHomeState {}

// Fake necesario para Mocktail
class FakeUserProfile extends Fake implements UserProfile {}

void main() {
  late MockSmartHomeState mockState;

  setUpAll(() {
    // Registramos el valor de respaldo para evitar errores de Mocktail
    registerFallbackValue(FakeUserProfile());
  });

  setUp(() {
    mockState = MockSmartHomeState();
    // Stubs críticos para evitar errores de "Null is not a subtype..."
    when(() => mockState.profiles).thenReturn([]); 
    when(() => mockState.activeProfile).thenReturn(null);
    when(() => mockState.addProfile(any())).thenReturn(null);
    when(() => mockState.updateProfile(any(), any())).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: ChangeNotifierProvider<SmartHomeState>.value(
        value: mockState,
        child: const ProfileEditScreen(),
      ),
    );
  }

  testWidgets('ProfileEditScreen renders form elements', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Nuevo Perfil'), findsOneWidget);
    expect(find.text('Nombre del Perfil'), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsOneWidget);
  });

  testWidgets('Validation error shows when name is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pump(); 

    expect(find.text('Por favor, introduce un nombre.'), findsOneWidget);
    verifyNever(() => mockState.addProfile(any()));
  });

  testWidgets('Switching LED mode changes input fields', (WidgetTester tester) async {
    // TRUCO CLAVE: Aumentar el tamaño de la pantalla para ver todo sin scroll
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createWidgetUnderTest());

    // Encontramos el primer botón "Parpadeo" (del primer LED) y lo pulsamos
    final blinkButton = find.text('Parpadeo').first;
    await tester.tap(blinkButton);
    await tester.pumpAndSettle();

    // Verificamos que aparezcan los campos numéricos
    expect(find.text('Encendido (ms)'), findsWidgets);
    expect(find.text('Apagado (ms)'), findsWidgets);

    // Limpieza del tamaño de pantalla
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Saving valid form calls addProfile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;

    when(() => mockState.profiles).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());

    // Llenar nombre
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del Perfil'), 'Mi Casa');
    
    // Guardar
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    // Verificar que se llamó a addProfile
    verify(() => mockState.addProfile(any())).called(1);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Toggling Sensors switch shows/hides interval input', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createWidgetUnderTest());

    // 1. Verificar estado inicial (Switch activado por defecto, input visible)
    // Buscamos el input específico de intervalo
    expect(find.text('Intervalo Lectura (ms)'), findsOneWidget);

    // 2. Encontrar el Switch de sensores y desactivarlo
    // Buscamos el Switch que está dentro de la tarjeta de Sensores
    final sensorSwitchFinder = find.byWidgetPredicate((widget) {
      if (widget is! Switch) return false;
      // Verificamos si este switch tiene cerca el texto "Habilitar lectura sensores"
      final finder = find.ancestor(
        of: find.byWidget(widget),
        matching: find.byWidgetPredicate((w) => w is Row && w.children.any((c) => c is Text && (c).data == 'Habilitar lectura sensores'))
      );
      return finder.evaluate().isNotEmpty;
    });

    // Si el finder complejo falla, usamos el último switch (generalmente sensores está al final)
    final targetSwitch = sensorSwitchFinder.evaluate().isNotEmpty 
        ? sensorSwitchFinder 
        : find.byType(Switch).last;

    await tester.tap(targetSwitch);
    await tester.pumpAndSettle();

    // 3. Verificar que el input ahora es invisible (Opacity 0.0)
    final opacityWidget = tester.widget<Opacity>(
      find.ancestor(
        of: find.widgetWithText(TextFormField, 'Intervalo Lectura (ms)'),
        matching: find.byType(Opacity)
      )
    );
    expect(opacityWidget.opacity, 0.0);

    addTearDown(tester.view.resetPhysicalSize);
  });
}