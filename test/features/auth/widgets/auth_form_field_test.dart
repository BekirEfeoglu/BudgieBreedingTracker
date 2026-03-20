import 'package:budgie_breeding_tracker/features/auth/widgets/auth_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('AuthFormField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders without error', (tester) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(controller: controller, label: 'Email'),
      );

      expect(find.byType(AuthFormField), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(controller: controller, label: 'Email'),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('shows hint text', (tester) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(
          controller: controller,
          label: 'Email',
          hint: 'Enter your email',
        ),
      );

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('validates required field via custom validator', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();

      await pumpWidgetSimple(
        tester,
        Form(
          key: formKey,
          child: AuthFormField(
            controller: controller,
            label: 'Email',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Field is required';
              }
              return null;
            },
          ),
        ),
      );

      // Trigger validation with empty field
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Field is required'), findsOneWidget);
    });

    testWidgets('shows password toggle when isPassword is true', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(
          controller: controller,
          label: 'Password',
          isPassword: true,
        ),
      );

      // Password starts obscured — eyeOff icon visible
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(find.byIcon(LucideIcons.eye), findsNothing);
    });

    testWidgets('does not show password toggle when isPassword is false', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(controller: controller, label: 'Email'),
      );

      expect(find.byIcon(LucideIcons.eyeOff), findsNothing);
      expect(find.byIcon(LucideIcons.eye), findsNothing);
    });

    testWidgets('toggles password visibility on icon tap', (tester) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(
          controller: controller,
          label: 'Password',
          isPassword: true,
        ),
      );

      // Initially obscured (eyeOff shown)
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);

      // Tap toggle
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Now visible (eye shown)
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
      expect(find.byIcon(LucideIcons.eyeOff), findsNothing);

      // Tap toggle again
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Obscured again
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
    });

    testWidgets('shows error text on validation failure', (tester) async {
      final formKey = GlobalKey<FormState>();
      const errorMessage = 'Invalid email format';

      await pumpWidgetSimple(
        tester,
        Form(
          key: formKey,
          child: AuthFormField(
            controller: controller,
            label: 'Email',
            validator: (_) => errorMessage,
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(controller: controller, label: 'Email'),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.pump();

      expect(controller.text, 'test@example.com');
    });

    testWidgets('shows prefix icon when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        AuthFormField(
          controller: controller,
          label: 'Email',
          prefixIcon: const Icon(LucideIcons.mail),
        ),
      );

      expect(find.byIcon(LucideIcons.mail), findsOneWidget);
    });

    testWidgets('passes no validation error when field is valid', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();

      await pumpWidgetSimple(
        tester,
        Form(
          key: formKey,
          child: AuthFormField(
            controller: controller,
            label: 'Email',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'valid@email.com');
      await tester.pump();

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isTrue);
      expect(find.text('Required'), findsNothing);
    });
  });
}
