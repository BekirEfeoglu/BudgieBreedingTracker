import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'genetics_history_model.freezed.dart';
part 'genetics_history_model.g.dart';

@freezed
abstract class GeneticsHistory with _$GeneticsHistory {
  const GeneticsHistory._();

  const factory GeneticsHistory({
    required String id,
    required String userId,

    /// JSON-encoded father genotype: mutationId -> alleleState.
    required Map<String, String> fatherGenotype,

    /// JSON-encoded mother genotype: mutationId -> alleleState.
    required Map<String, String> motherGenotype,

    /// Optional bird ID if father was selected from collection.
    String? fatherBirdId,

    /// Optional bird ID if mother was selected from collection.
    String? motherBirdId,

    /// JSON-encoded list of offspring results.
    required String resultsJson,

    /// Calculation engine version at the time of save.
    /// Null for entries saved before versioning was introduced.
    int? calculationVersion,

    /// User notes about this calculation.
    String? notes,

    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
  }) = _GeneticsHistory;

  /// Whether this entry was saved with an older calculation engine.
  bool get isStale =>
      calculationVersion == null ||
      calculationVersion != GeneticsConstants.calculationVersion;

  factory GeneticsHistory.fromJson(Map<String, dynamic> json) =>
      _$GeneticsHistoryFromJson(json);
}
