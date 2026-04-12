import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

/// Returns the display color for a [BirdGender].
Color birdGenderColor(BirdGender gender) => switch (gender) {
  BirdGender.male => AppColors.genderMale,
  BirdGender.female => AppColors.genderFemale,
  BirdGender.unknown => AppColors.genderUnknown,
};

/// Small icon widget showing the bird's gender.
class BirdGenderIcon extends StatelessWidget {
  final BirdGender gender;
  final double size;

  const BirdGenderIcon({super.key, required this.gender, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return switch (gender) {
      BirdGender.male => AppIcon(
        AppIcons.male,
        size: size,
        color: AppColors.genderMale,
      ),
      BirdGender.female => AppIcon(
        AppIcons.female,
        size: size,
        color: AppColors.genderFemale,
      ),
      BirdGender.unknown => Icon(
        LucideIcons.helpCircle,
        size: size,
        color: AppColors.genderUnknown,
      ),
    };
  }
}
