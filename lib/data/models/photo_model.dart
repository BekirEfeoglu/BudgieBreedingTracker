import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';

part 'photo_model.freezed.dart';
part 'photo_model.g.dart';

@freezed
abstract class Photo with _$Photo {
  const Photo._();

  const factory Photo({
    required String id,
    required String userId,
    @JsonKey(unknownEnumValue: PhotoEntityType.bird)
    required PhotoEntityType entityType,
    required String entityId,
    required String fileName,
    String? filePath,
    int? fileSize,
    String? mimeType,
    @Default(false) bool isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Photo;

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
}
