import '../../../core/enums/gamification_enums.dart';

abstract final class XpConstants {
  static const Map<XpAction, int> xpValues = {
    XpAction.dailyLogin: 5,
    XpAction.addBird: 10,
    XpAction.createBreeding: 15,
    XpAction.recordChick: 10,
    XpAction.addHealthRecord: 5,
    XpAction.completeProfile: 20,
    XpAction.sharePost: 5,
    XpAction.addComment: 3,
    XpAction.receiveLike: 1,
    XpAction.createListing: 10,
    XpAction.sendMessage: 2,
  };

  static const Map<XpAction, int> dailyLimits = {
    XpAction.dailyLogin: 1,
    XpAction.completeProfile: 1,
    XpAction.sendMessage: 5,
  };

  static int getXpAmount(XpAction action) => xpValues[action] ?? 0;

  static int? getDailyLimit(XpAction action) => dailyLimits[action];
}
