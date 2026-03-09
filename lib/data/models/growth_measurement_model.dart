import 'package:freezed_annotation/freezed_annotation.dart';

part 'growth_measurement_model.freezed.dart';
part 'growth_measurement_model.g.dart';

@freezed
abstract class GrowthMeasurement with _$GrowthMeasurement {
  const GrowthMeasurement._();
  const factory GrowthMeasurement({
    required String id,
    required String chickId,
    required double weight,
    required DateTime measurementDate,
    required String userId,
    double? height,
    double? wingLength,
    double? tailLength,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GrowthMeasurement;

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) =>
      _$GrowthMeasurementFromJson(json);
}
