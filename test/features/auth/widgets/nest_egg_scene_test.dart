import 'package:budgie_breeding_tracker/features/auth/screens/budgie_login_screen.dart'
    show LoginState;
import 'package:budgie_breeding_tracker/features/auth/widgets/nest_egg_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NestEggScene', () {
    Widget buildSubject({
      LoginState state = LoginState.idle,
      bool isPeeking = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: _AnimatedWrapper(
            builder: (eggWobble) {
              return NestEggScene(
                state: state,
                isPeeking: isPeeking,
                eggWobble: eggWobble,
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders without error in idle state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(NestEggScene), findsOneWidget);
    });

    testWidgets('has correct SizedBox dimensions', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(NestEggScene),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 130 && w.height == 90,
          ),
        ),
      );
      expect(sizedBox.width, 130);
      expect(sizedBox.height, 90);
    });

    testWidgets('contains CustomPaint for nest texture', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('baby bird is hidden when not peeking and not success', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(isPeeking: false));
      await tester.pump();

      // Baby bird AnimatedOpacity should have opacity 0
      final opacityFinder = find.descendant(
        of: find.byType(NestEggScene),
        matching: find.byType(AnimatedOpacity),
      );
      expect(opacityFinder, findsWidgets);

      // First AnimatedOpacity is the baby bird
      final babyOpacity = tester.widget<AnimatedOpacity>(
        opacityFinder.first,
      );
      expect(babyOpacity.opacity, 0.0);
    });

    testWidgets('baby bird becomes visible when isPeeking is true', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(isPeeking: true));
      await tester.pump();

      final opacityFinder = find.descendant(
        of: find.byType(NestEggScene),
        matching: find.byType(AnimatedOpacity),
      );

      // First AnimatedOpacity is the baby bird — should be visible
      final babyOpacity = tester.widget<AnimatedOpacity>(
        opacityFinder.first,
      );
      expect(babyOpacity.opacity, 1.0);
    });

    testWidgets('baby bird is visible in success state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.success));
      await tester.pump();

      final opacityFinder = find.descendant(
        of: find.byType(NestEggScene),
        matching: find.byType(AnimatedOpacity),
      );

      final babyOpacity = tester.widget<AnimatedOpacity>(
        opacityFinder.first,
      );
      expect(babyOpacity.opacity, 1.0);
    });

    testWidgets('broken egg top is visible in success state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.success));
      await tester.pump();

      final opacityFinder = find.descendant(
        of: find.byType(NestEggScene),
        matching: find.byType(AnimatedOpacity),
      );

      // Second AnimatedOpacity is the broken egg top
      final brokenEggOpacity = tester.widget<AnimatedOpacity>(
        opacityFinder.at(1),
      );
      expect(brokenEggOpacity.opacity, 1.0);
    });

    testWidgets('broken egg top is hidden in non-success state', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(state: LoginState.idle));
      await tester.pump();

      final opacityFinder = find.descendant(
        of: find.byType(NestEggScene),
        matching: find.byType(AnimatedOpacity),
      );

      // Second AnimatedOpacity is the broken egg top — should be hidden
      final brokenEggOpacity = tester.widget<AnimatedOpacity>(
        opacityFinder.at(1),
      );
      expect(brokenEggOpacity.opacity, 0.0);
    });

    testWidgets('egg uses AnimatedContainer for state transitions', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(state: LoginState.idle));
      await tester.pump();

      // AnimatedContainer is used for the egg shape changes
      expect(
        find.descendant(
          of: find.byType(NestEggScene),
          matching: find.byType(AnimatedContainer),
        ),
        findsWidgets,
      );

      // Switch to success state — should still render
      await tester.pumpWidget(buildSubject(state: LoginState.success));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NestEggScene), findsOneWidget);
    });

    testWidgets('renders nest container with CustomPaint', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Nest uses CustomPaint for texture lines
      expect(
        find.descendant(
          of: find.byType(NestEggScene),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('renders in loading state with wobble animation', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(state: LoginState.loading));
      await tester.pump();

      expect(find.byType(NestEggScene), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('renders in error state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.error));
      await tester.pump();

      expect(find.byType(NestEggScene), findsOneWidget);
    });

    testWidgets('renders in emailFocus state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.emailFocus));
      await tester.pump();

      expect(find.byType(NestEggScene), findsOneWidget);
    });

    testWidgets('renders in passwordFocus state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.passwordFocus));
      await tester.pump();

      expect(find.byType(NestEggScene), findsOneWidget);
    });

    testWidgets('uses AnimatedPositioned for baby bird and egg', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(NestEggScene),
          matching: find.byType(AnimatedPositioned),
        ),
        findsWidgets,
      );
    });

    testWidgets('disposes cleanly when removed from tree', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump();

      // No exception means clean disposal
    });
  });
}

/// Test helper that creates an AnimationController for NestEggScene.
class _AnimatedWrapper extends StatefulWidget {
  final Widget Function(AnimationController eggWobble) builder;

  const _AnimatedWrapper({required this.builder});

  @override
  State<_AnimatedWrapper> createState() => _AnimatedWrapperState();
}

class _AnimatedWrapperState extends State<_AnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _eggWobble;

  @override
  void initState() {
    super.initState();
    _eggWobble = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _eggWobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_eggWobble);
}
