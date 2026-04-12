import 'package:budgie_breeding_tracker/features/auth/screens/budgie_login_screen.dart'
    show LoginState;
import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_branch_scene.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgieBranchScene', () {
    Widget buildSubject({
      LoginState state = LoginState.idle,
      bool isBlinking = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: _AnimatedWrapper(
            builder: (wobble, wing, hop) {
              return BudgieBranchScene(
                state: state,
                birdWobble: wobble,
                wingFlap: wing,
                hop: hop,
                isBlinking: isBlinking,
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders without error in idle state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(BudgieBranchScene), findsOneWidget);
    });

    testWidgets('contains two BudgieCharacter widgets (male and female)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(BudgieCharacter), findsNWidgets(2));
    });

    testWidgets('has correct overall SizedBox dimensions', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(BudgieBranchScene),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 260 && w.height == 130,
          ),
        ),
      );
      expect(sizedBox.width, 260);
      expect(sizedBox.height, 130);
    });

    testWidgets('renders in emailFocus state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.emailFocus));
      await tester.pump();

      expect(find.byType(BudgieBranchScene), findsOneWidget);
      expect(find.byType(BudgieCharacter), findsNWidgets(2));
    });

    testWidgets('renders in passwordFocus state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.passwordFocus));
      await tester.pump();

      expect(find.byType(BudgieBranchScene), findsOneWidget);
    });

    testWidgets('renders in loading state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.loading));
      await tester.pump();

      expect(find.byType(BudgieBranchScene), findsOneWidget);
    });

    testWidgets('renders in success state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.success));
      await tester.pump();

      expect(find.byType(BudgieBranchScene), findsOneWidget);
    });

    testWidgets('renders in error state', (tester) async {
      await tester.pumpWidget(buildSubject(state: LoginState.error));
      await tester.pump();

      expect(find.byType(BudgieBranchScene), findsOneWidget);
    });

    testWidgets('renders with blinking enabled', (tester) async {
      await tester.pumpWidget(buildSubject(isBlinking: true));
      await tester.pump();

      expect(find.byType(BudgieBranchScene), findsOneWidget);
    });

    testWidgets('contains branch decoration', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // The branch is a Container with width 230 and height 14
      final branchFinder = find.byWidgetPredicate(
        (w) => w is Container && w.constraints == null,
      );
      expect(branchFinder, findsWidgets);
    });

    testWidgets('uses Stack for layering scene elements', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Main scene stack
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('uses AnimatedBuilder for hop animation', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('disposes animation controllers without error', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Pump a different widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump();

      // No exception means controllers were properly disposed
    });
  });
}

/// Test helper that creates AnimationControllers for BudgieBranchScene.
class _AnimatedWrapper extends StatefulWidget {
  final Widget Function(
    AnimationController wobble,
    AnimationController wing,
    AnimationController hop,
  ) builder;

  const _AnimatedWrapper({required this.builder});

  @override
  State<_AnimatedWrapper> createState() => _AnimatedWrapperState();
}

class _AnimatedWrapperState extends State<_AnimatedWrapper>
    with TickerProviderStateMixin {
  late final AnimationController _wobble;
  late final AnimationController _wing;
  late final AnimationController _hop;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _wing = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _hop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _wobble.dispose();
    _wing.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_wobble, _wing, _hop);
}
