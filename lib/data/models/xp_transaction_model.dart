import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';

part 'xp_transaction_model.freezed.dart';
part 'xp_transaction_model.g.dart';

@freezed
abstract class XpTransaction with _$XpTransaction {
  const XpTransaction._();

  const factory XpTransaction({
    required String id,
    required String userId,
    @JsonKey(unknownEnumValue: XpAction.unknown)
    @Default(XpAction.unknown)
    XpAction action,
    @Default(0) int amount,
    String? referenceId,
    DateTime? createdAt,
  }) = _XpTransaction;

  factory XpTransaction.fromJson(Map<String, dynamic> json) => _$XpTransactionFromJson(json);
}
