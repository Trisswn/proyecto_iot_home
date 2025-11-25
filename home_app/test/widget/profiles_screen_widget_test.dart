import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:iot_controller_2/smart_home_state.dart';
import 'package:iot_controller_2/profiles_screen.dart';
import 'package:iot_controller_2/profile_model.dart';

void main() {
  group('Widget Tests - ProfilesScreen', () {
    Widget createWidgetUnderTest({required SmartHomeState state}) {
      return MaterialApp(
        home: ChangeNotifierProvider<SmartHomeState>.value(
          value: state,
          child: const ProfilesScreen(),
        ),
      );
    }

    testWidgets('ProfilesScreen should display AppBar with title',
        (WidgetTester tester) async {
      final state = SmartHomeState();

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.text('Perfiles de Usuario'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('ProfilesScreen should display add button in AppBar',
        (WidgetTester tester) async {
      final state = SmartHomeState();

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('ProfilesScreen should display empty list when no profiles',
        (WidgetTester tester) async {
      final state = SmartHomeState();
      expect(state.profiles.isEmpty, true);

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.byType(Card), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ProfilesScreen should display profiles as cards',
        (WidgetTester tester) async {
      final state = SmartHomeState();
      final profile1 = UserProfile(
        name: 'Perfil Sala',
        ledConfigs: UserProfile.getDefaultLedConfigs(),
      );
      final profile2 = UserProfile(
        name: 'Perfil Cocina',
        ledConfigs: UserProfile.getDefaultLedConfigs(),
      );
      state.addProfile(profile1);
      state.addProfile(profile2);

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.byType(Card), findsWidgets);
      expect(find.text('Perfil Sala'), findsOneWidget);
      expect(find.text('Perfil Cocina'), findsOneWidget);
    });

    testWidgets('ProfilesScreen should display edit and delete buttons',
        (WidgetTester tester) async {
      final state = SmartHomeState();
      final profile = UserProfile(
        name: 'Test Profile',
        ledConfigs: UserProfile.getDefaultLedConfigs(),
      );
      state.addProfile(profile);

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('Delete button should remove profile when pressed',
        (WidgetTester tester) async {
      final state = SmartHomeState();
      final profile = UserProfile(
        name: 'Profile to Delete',
        ledConfigs: UserProfile.getDefaultLedConfigs(),
      );
      state.addProfile(profile);
      expect(state.profiles.length, 1);

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(state.profiles.length, 0);
      expect(find.text('Profile to Delete'), findsNothing);
    });

    testWidgets('Profile card should display person icon',
        (WidgetTester tester) async {
      final state = SmartHomeState();
      final profile = UserProfile(
        name: 'Test Profile',
        ledConfigs: UserProfile.getDefaultLedConfigs(),
      );
      state.addProfile(profile);

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('Profile should have correct styling', (WidgetTester tester) async {
      final state = SmartHomeState();
      final profile = UserProfile(
        name: 'Styled Profile',
        ledConfigs: UserProfile.getDefaultLedConfigs(),
      );
      state.addProfile(profile);

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Styled Profile'), findsOneWidget);
    });

    testWidgets('Multiple profiles should display in order',
        (WidgetTester tester) async {
      final state = SmartHomeState();
      final profiles = [
        UserProfile(
          name: 'First Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        ),
        UserProfile(
          name: 'Second Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        ),
        UserProfile(
          name: 'Third Profile',
          ledConfigs: UserProfile.getDefaultLedConfigs(),
        ),
      ];
      for (final p in profiles) {
        state.addProfile(p);
      }

      await tester.pumpWidget(createWidgetUnderTest(state: state));

      expect(find.byType(Card), findsWidgets);
      expect(find.text('First Profile'), findsOneWidget);
      expect(find.text('Second Profile'), findsOneWidget);
      expect(find.text('Third Profile'), findsOneWidget);
    });
  });
}
