import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';

part 'nest_model.freezed.dart';
part 'nest_model.g.dart';

@freezed
abstract class Nest with _$Nest {
  const Nest._();

  const factory Nest({
    required String id,
    required String userId,
    String? name,
    String? location,
    @JsonKey(unknownEnumValue: NestStatus.unknown)
    @Default(NestStatus.available) NestStatus status,
    String? notes,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Nest;

  factory Nest.fromJson(Map<String, dynamic> json) => _$NestFromJson(json);
}
