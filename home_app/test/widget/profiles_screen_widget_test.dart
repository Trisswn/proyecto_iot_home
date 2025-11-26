import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:iot_controller_2/smart_home_state.dart';
import 'package:iot_controller_2/profiles_screen.dart';
import 'package:iot_controller_2/profile_model.dart';
import 'package:iot_controller_2/app_colors.dart';

class MockSmartHomeState extends Mock implements SmartHomeState {}

void main() {
  group('Widget Tests - ProfilesScreen', () {
    late MockSmartHomeState mockState;

    setUp(() {
      mockState = MockSmartHomeState();
      // Stubs por defecto para evitar errores de null
      when(() => mockState.profiles).thenReturn([]);
      when(() => mockState.activeProfile).thenReturn(null);
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        home: ChangeNotifierProvider<SmartHomeState>.value(
          value: mockState,
          child: const ProfilesScreen(),
        ),
      );
    }

    testWidgets('ProfilesScreen displays empty list when no profiles', (WidgetTester tester) async {
      when(() => mockState.profiles).thenReturn([]);
      
      await tester.pumpWidget(createWidgetUnderTest());

      // Verifica que aparezca el título pero ninguna tarjeta
      expect(find.text('Perfiles de Usuario'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('ProfilesScreen displays profiles as cards', (WidgetTester tester) async {
      final profiles = [
        UserProfile(name: 'Perfil Sala', ledConfigs: UserProfile.getDefaultLedConfigs()),
        UserProfile(name: 'Perfil Cocina', ledConfigs: UserProfile.getDefaultLedConfigs()),
      ];
      when(() => mockState.profiles).thenReturn(profiles);

      await tester.pumpWidget(createWidgetUnderTest());

      // Verifica que aparezcan las tarjetas correspondientes
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('Perfil Sala'), findsOneWidget);
      expect(find.text('Perfil Cocina'), findsOneWidget);
    });

    testWidgets('Delete button calls deleteProfile', (WidgetTester tester) async {
      final profiles = [
        UserProfile(name: 'Profile to Delete', ledConfigs: UserProfile.getDefaultLedConfigs()),
      ];
      when(() => mockState.profiles).thenReturn(profiles);
      
      await tester.pumpWidget(createWidgetUnderTest());

      // Buscar y pulsar el botón de eliminar
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // Verificar que se llamó al método en el estado
      verify(() => mockState.deleteProfile(0)).called(1);
    });
  });
}