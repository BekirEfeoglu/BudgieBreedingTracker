import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';

part 'chick_model.freezed.dart';
part 'chick_model.g.dart';

@freezed
abstract class Chick with _$Chick {
  const Chick._();

  const factory Chick({
    required String id,
    required String userId,
    @Default(BirdGender.unknown)
    @JsonKey(unknownEnumValue: BirdGender.unknown)
    BirdGender gender,
    @Default(ChickHealthStatus.healthy)
    @JsonKey(unknownEnumValue: ChickHealthStatus.unknown)
    ChickHealthStatus healthStatus,
    String? clutchId,
    String? eggId,
    String? birdId,
    String? name,
    String? ringNumber,
    @Default(10) int bandingDay,
    DateTime? bandingDate,
    String? notes,
    String? photoUrl,
    double? hatchWeight,
    DateTime? hatchDate,
    DateTime? weanDate,
    DateTime? deathDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
  }) = _Chick;

  factory Chick.fromJson(Map<String, dynamic> json) => _$ChickFromJson(json);
}

extension ChickX on Chick {
  ({int weeks, int days, int totalDays})? get age {
    if (hatchDate == null) return null;
    final totalDays = DateTime.now().difference(hatchDate!).inDays;
    return (weeks: totalDays ~/ 7, days: totalDays % 7, totalDays: totalDays);
  }

  DevelopmentStage get developmentStage {
    final a = age;
    if (a == null) return DevelopmentStage.newborn;
    if (a.totalDays <= 7) return DevelopmentStage.newborn;
    if (a.totalDays <= 21) return DevelopmentStage.nestling;
    if (a.totalDays <= 35) return DevelopmentStage.fledgling;
    return DevelopmentStage.juvenile;
  }

  bool get isWeaned => weanDate != null;

  bool get isBanded => bandingDate != null;

  DateTime? get plannedBandingDate =>
      hatchDate != null ? hatchDate!.add(Duration(days: bandingDay)) : null;
}
