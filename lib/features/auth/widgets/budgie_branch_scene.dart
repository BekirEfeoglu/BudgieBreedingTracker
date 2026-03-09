import 'dart:math';

import 'package:flutter/material.dart';

import '../screens/budgie_login_screen.dart'
    show LoginState;
import 'budgie_character.dart';
import 'budgie_login_colors.dart';

/// Dal uzerinde tünemiş erkek ve disi muhabbet kusu sahnesi.
///
/// [LoginState]'e gore kuslarin animasyonlari degisir:
/// - idle: wobble + blink + wing flap
/// - emailFocus: baslar input'a doner
/// - passwordFocus: erkek goz kapatir, disi "ne yapiyon" bakisi
/// - loading: dikkatli, kanat durur
/// - success: sevinc ziplama
/// - error: uzgun ifade
class BudgieBranchScene extends StatelessWidget {
  final LoginState state;
  final Animation<double> birdWobble;
  final Animation<double> wingFlap;
  final Animation<double> hop;
  final bool isBlinking;

  const BudgieBranchScene({
    super.key,
    required this.state,
    required this.birdWobble,
    required this.wingFlap,
    required this.hop,
    this.isBlinking = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: hop,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -18 * sin(hop.value * pi)),
          child: child,
        );
      },
      child: SizedBox(
        width: 260,
        height: 130,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildBranch(),
            _buildLeaves(),
            _buildMaleBudgie(),
            _buildFemaleBudgie(),
          ],
        ),
      ),
    );
  }

  // -- Dal --
  Widget _buildBranch() {
    return Positioned(
      bottom: 10,
      child: Container(
        width: 230,
        height: 14,
        decoration: BoxDecoration(
          color: BudgieLoginPalette.branch,
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: BudgieLoginPalette.branchBark.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // Kabuk cizgileri
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 30,
              child: Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: BudgieLoginPalette.branchBark.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 100,
              child: Container(
                width: 15,
                height: 2,
                decoration: BoxDecoration(
                  color: BudgieLoginPalette.branchBark.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              top: 3,
              left: 170,
              child: Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: BudgieLoginPalette.branchBark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Kucuk yapraklar (dal detayi) --
  Widget _buildLeaves() {
    return Positioned(
      bottom: 18,
      left: 10,
      child: Row(
        children: [
          Transform.rotate(
            angle: -0.5,
            child: Container(
              width: 10,
              height: 16,
              decoration: BoxDecoration(
                color: BudgieLoginPalette.leaf.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Transform.rotate(
            angle: -0.3,
            child: Container(
              width: 8,
              height: 12,
              decoration: BoxDecoration(
                color: BudgieLoginPalette.leaf.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Erkek kus (sol) --
  Widget _buildMaleBudgie() {
    return Positioned(
      left: 48,
      bottom: 22,
      child: AnimatedBuilder(
        animation: Listenable.merge([birdWobble, wingFlap]),
        builder: (context, child) {
          double headRot = 0;
          bool coverEyes = false;
          bool sad = false;

          switch (state) {
            case LoginState.emailFocus:
              headRot = 0.2;
            case LoginState.passwordFocus:
              coverEyes = true;
            case LoginState.error:
              headRot = 0.3;
              sad = true;
            case LoginState.idle:
              break;
            case LoginState.loading:
              headRot = 0.1;
            case LoginState.success:
              break;
          }

          return BudgieCharacter(
            bodyColor: BudgieLoginPalette.maleBudgie,
            cheekColor: BudgieLoginPalette.maleCheck,
            headRotation: headRot,
            isCoveringEyes: coverEyes,
            isSad: sad,
            isBlinking: isBlinking,
            isLeft: true,
            wingFlapValue: state == LoginState.idle ? wingFlap.value : 0,
            bodyWobbleValue: state == LoginState.idle ? birdWobble.value : 0,
          );
        },
      ),
    );
  }

  // -- Disi kus (sag) --
  Widget _buildFemaleBudgie() {
    return Positioned(
      right: 48,
      bottom: 22,
      child: AnimatedBuilder(
        animation: Listenable.merge([birdWobble, wingFlap]),
        builder: (context, child) {
          double headRot = 0;
          bool sad = false;

          switch (state) {
            case LoginState.emailFocus:
              headRot = -0.2;
            case LoginState.passwordFocus:
              headRot = -0.15; // "ne yapiyon" bakisi
            case LoginState.error:
              headRot = -0.3;
              sad = true;
            case LoginState.idle:
              break;
            case LoginState.loading:
              headRot = -0.1;
            case LoginState.success:
              break;
          }

          return BudgieCharacter(
            bodyColor: BudgieLoginPalette.femaleBudgie,
            cheekColor: BudgieLoginPalette.femaleCheck,
            headRotation: headRot,
            isSad: sad,
            isBlinking: isBlinking,
            isLeft: false,
            wingFlapValue: state == LoginState.idle ? wingFlap.value : 0,
            bodyWobbleValue:
                state == LoginState.idle ? (birdWobble.value + 0.25) : 0,
          );
        },
      ),
    );
  }
}
