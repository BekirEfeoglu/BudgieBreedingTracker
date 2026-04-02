# Messaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Yetistiriciler arasi 1-1 ve grup mesajlasma, Supabase Realtime ile anlik mesaj teslimi.

**Architecture:** Marketplace pattern'i izlenir (custom RemoteSource + Repository), Supabase Realtime istisna olarak eklenir. 3 Freezed model (Conversation, Message, ConversationParticipant), 3 Supabase tablosu. Realtime sadece messaging modulu icinde kullanilir — diger moduller etkilenmez.

**Tech Stack:** Flutter, Riverpod 3, GoRouter, Supabase (PostgreSQL + Realtime + Presence + Storage), Freezed 3, easy_localization

**Spec:** `docs/superpowers/specs/2026-04-02-community-social-features-design.md` — Feature 2

---

### Task 1: Enum Dosyasi

**Files:**
- Create: `lib/core/enums/messaging_enums.dart`

- [ ] **Step 1: Enum dosyasini olustur**

```dart
enum ConversationType {
  direct,
  group,
  unknown;

  String toJson() => name;

  static ConversationType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return ConversationType.unknown;
    }
  }
}

enum MessageType {
  text,
  image,
  birdCard,
  listingCard,
  unknown;

  String toJson() => name;

  static MessageType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return MessageType.unknown;
    }
  }
}

enum ParticipantRole {
  owner,
  admin,
  member,
  unknown;

  String toJson() => name;

  static ParticipantRole fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return ParticipantRole.unknown;
    }
  }
}
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/core/enums/messaging_enums.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/core/enums/messaging_enums.dart
git commit -m "feat(messaging): add conversation, message, and participant role enums"
```

---

### Task 2: Freezed Models (3 model)

**Files:**
- Create: `lib/data/models/conversation_model.dart`
- Create: `lib/data/models/message_model.dart`
- Create: `lib/data/models/conversation_participant_model.dart`

- [ ] **Step 1: Conversation model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
abstract class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    required String id,
    @JsonKey(unknownEnumValue: ConversationType.unknown)
    @Default(ConversationType.direct)
    ConversationType type,
    String? name,
    String? imageUrl,
    required String creatorId,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    String? lastMessageUserId,
    @Default(0) int participantCount,
    @JsonKey(includeFromJson: false) @Default(0) int unreadCount,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

extension ConversationX on Conversation {
  bool get isGroup => type == ConversationType.group;
  bool get isDirect => type == ConversationType.direct;
  bool get hasUnread => unreadCount > 0;
}
```

- [ ] **Step 2: Message model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    @Default('') String senderName,
    String? senderAvatarUrl,
    String? content,
    @JsonKey(unknownEnumValue: MessageType.unknown)
    @Default(MessageType.text)
    MessageType messageType,
    String? imageUrl,
    String? referenceId,
    @Default({}) Map<String, dynamic> referenceData,
    @Default([]) List<String> readBy,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

extension MessageX on Message {
  bool get isText => messageType == MessageType.text;
  bool get isImage => messageType == MessageType.image;
  bool get isBirdCard => messageType == MessageType.birdCard;
  bool get isListingCard => messageType == MessageType.listingCard;
  bool isReadBy(String userId) => readBy.contains(userId);
}
```

- [ ] **Step 3: ConversationParticipant model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

part 'conversation_participant_model.freezed.dart';
part 'conversation_participant_model.g.dart';

@freezed
abstract class ConversationParticipant with _$ConversationParticipant {
  const ConversationParticipant._();

  const factory ConversationParticipant({
    required String conversationId,
    required String userId,
    @JsonKey(unknownEnumValue: ParticipantRole.unknown)
    @Default(ParticipantRole.member)
    ParticipantRole role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    @Default(false) bool isMuted,
    @Default(false) bool isLeft,
  }) = _ConversationParticipant;

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) =>
      _$ConversationParticipantFromJson(json);
}

extension ConversationParticipantX on ConversationParticipant {
  bool get isOwner => role == ParticipantRole.owner;
  bool get isAdmin => role == ParticipantRole.admin || role == ParticipantRole.owner;
  bool get isActive => !isLeft;
}
```

- [ ] **Step 4: Code generation calistir**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generated files without errors

- [ ] **Step 5: Analiz calistir**

Run: `flutter analyze lib/data/models/conversation_model.dart lib/data/models/message_model.dart lib/data/models/conversation_participant_model.dart`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/conversation_model.dart lib/data/models/message_model.dart lib/data/models/conversation_participant_model.dart
git commit -m "feat(messaging): add Conversation, Message, and ConversationParticipant freezed models"
```

---

### Task 3: Model Serialization Testleri

**Files:**
- Create: `test/data/models/conversation_model_test.dart`
- Create: `test/data/models/message_model_test.dart`

- [ ] **Step 1: Conversation model testi**

Testler: toJson/fromJson round-trip, unknown ConversationType, isGroup/isDirect/hasUnread extension, default values.

- [ ] **Step 2: Message model testi**

Testler: toJson/fromJson round-trip, unknown MessageType, isText/isImage/isBirdCard/isListingCard extension, isReadBy, default values.

- [ ] **Step 3: Testleri calistir**

Run: `flutter test test/data/models/conversation_model_test.dart test/data/models/message_model_test.dart`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add test/data/models/conversation_model_test.dart test/data/models/message_model_test.dart
git commit -m "test(messaging): add model serialization tests"
```

---

### Task 4: Supabase Constants + Migration

**Files:**
- Modify: `lib/core/constants/supabase_constants.dart`
- Create: `supabase/migrations/20260402110000_create_messaging_tables.sql`

- [ ] **Step 1: Supabase constants ekle**

```dart
  // Messaging
  static const String conversationsTable = 'conversations';
  static const String conversationParticipantsTable = 'conversation_participants';
  static const String messagesTable = 'messages';
```

Storage bucket:
```dart
  static const String messagePhotosBucket = 'message-photos';
```

- [ ] **Step 2: Migration dosyasini olustur**

```sql
-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL DEFAULT 'direct'
    CHECK (type IN ('direct', 'group')),
  name TEXT,
  image_url TEXT,
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_message_content TEXT,
  last_message_at TIMESTAMPTZ,
  last_message_user_id UUID,
  participant_count INTEGER NOT NULL DEFAULT 0,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);

-- RLS: Only participants can see conversations
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversations_participant_read" ON conversations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_participants.conversation_id = conversations.id
      AND conversation_participants.user_id = auth.uid()
      AND conversation_participants.is_left = false
    )
  );

CREATE POLICY "conversations_insert" ON conversations
  FOR INSERT WITH CHECK (creator_id = auth.uid());

CREATE POLICY "conversations_update" ON conversations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_participants.conversation_id = conversations.id
      AND conversation_participants.user_id = auth.uid()
      AND conversation_participants.is_left = false
    )
  );

-- Conversation Participants table
CREATE TABLE IF NOT EXISTS conversation_participants (
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member'
    CHECK (role IN ('owner', 'admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_read_at TIMESTAMPTZ,
  is_muted BOOLEAN NOT NULL DEFAULT false,
  is_left BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);

ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "participants_own_read" ON conversation_participants
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "participants_conversation_read" ON conversation_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversation_participants.conversation_id
      AND cp.user_id = auth.uid()
      AND cp.is_left = false
    )
  );

CREATE POLICY "participants_insert" ON conversation_participants
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversation_participants.conversation_id
      AND cp.user_id = auth.uid()
      AND cp.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "participants_update" ON conversation_participants
  FOR UPDATE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversation_participants.conversation_id
      AND cp.user_id = auth.uid()
      AND cp.role IN ('owner', 'admin')
    )
  );

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL DEFAULT '',
  sender_avatar_url TEXT,
  content TEXT,
  message_type TEXT NOT NULL DEFAULT 'text'
    CHECK (message_type IN ('text', 'image', 'birdCard', 'listingCard')),
  image_url TEXT,
  reference_id UUID,
  reference_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  read_by JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Only conversation participants can see messages
CREATE POLICY "messages_participant_read" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_participants.conversation_id = messages.conversation_id
      AND conversation_participants.user_id = auth.uid()
    )
  );

CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_participants.conversation_id = messages.conversation_id
      AND conversation_participants.user_id = auth.uid()
      AND conversation_participants.is_left = false
    )
  );

CREATE POLICY "messages_update" ON messages
  FOR UPDATE USING (sender_id = auth.uid());

-- Enable Realtime for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Updated_at trigger for conversations
CREATE OR REPLACE FUNCTION update_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_conversations_updated_at();

-- Auto-update conversation last_message on new message
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations SET
    last_message_content = NEW.content,
    last_message_at = NEW.created_at,
    last_message_user_id = NEW.sender_id,
    updated_at = now()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER messages_update_conversation
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();

-- Auto-update participant_count on participant changes
CREATE OR REPLACE FUNCTION update_conversation_participant_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations SET
    participant_count = (
      SELECT COUNT(*) FROM conversation_participants
      WHERE conversation_id = COALESCE(NEW.conversation_id, OLD.conversation_id)
      AND is_left = false
    )
  WHERE id = COALESCE(NEW.conversation_id, OLD.conversation_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER participants_count_update
  AFTER INSERT OR UPDATE OR DELETE ON conversation_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_participant_count();
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/supabase_constants.dart supabase/migrations/20260402110000_create_messaging_tables.sql
git commit -m "feat(messaging): add supabase constants and database migration"
```

---

### Task 5: Remote Sources

**Files:**
- Create: `lib/data/remote/api/conversation_remote_source.dart`
- Create: `lib/data/remote/api/message_remote_source.dart`

- [ ] **Step 1: Conversation remote source**

Methods: `fetchConversations(userId)`, `fetchById(id)`, `create(data)`, `update(id, data)`, `fetchParticipants(conversationId)`, `addParticipant(data)`, `updateParticipant(conversationId, userId, data)`, `findDirectConversation(userId1, userId2)`.

Uses `SupabaseConstants.conversationsTable`, `SupabaseConstants.conversationParticipantsTable`.

- [ ] **Step 2: Message remote source**

Methods: `fetchMessages(conversationId, {limit, before})`, `insert(data)`, `markAsRead(messageId, userId)`, `softDelete(id)`.

Uses `SupabaseConstants.messagesTable`.

**Realtime subscription methods** (unique to messaging):
- `subscribeToMessages(conversationId, onMessage)` — returns `RealtimeChannel`
- `subscribeToConversationUpdates(userId, onUpdate)` — returns `RealtimeChannel`
- `unsubscribe(channel)` — removes channel

- [ ] **Step 3: Register providers in `remote_source_providers.dart`**

```dart
final conversationRemoteSourceProvider = Provider<ConversationRemoteSource>((ref) {
  return ConversationRemoteSource(ref.watch(supabaseClientProvider));
});

final messageRemoteSourceProvider = Provider<MessageRemoteSource>((ref) {
  return MessageRemoteSource(ref.watch(supabaseClientProvider));
});
```

- [ ] **Step 4: Analiz + Commit**

```bash
git add lib/data/remote/api/conversation_remote_source.dart lib/data/remote/api/message_remote_source.dart lib/data/remote/api/remote_source_providers.dart
git commit -m "feat(messaging): add conversation and message remote sources with realtime support"
```

---

### Task 6: Repository

**Files:**
- Create: `lib/data/repositories/messaging_repository.dart`
- Modify: `lib/data/repositories/repository_providers.dart`

- [ ] **Step 1: Repository olustur**

```dart
class MessagingRepository {
  final ConversationRemoteSource _conversationSource;
  final MessageRemoteSource _messageSource;

  const MessagingRepository({
    required ConversationRemoteSource conversationSource,
    required MessageRemoteSource messageSource,
  }) : _conversationSource = conversationSource,
       _messageSource = messageSource;
```

Methods:
- `getConversations(userId)` — fetch + parse to models
- `getConversationById(id)` — single conversation
- `getOrCreateDirectConversation(userId1, userId2, username1, username2)` — find existing or create new
- `createGroupConversation(creatorId, name, participantIds)` — create group + add participants
- `getMessages(conversationId, {limit, before})` — paginated messages
- `sendMessage(data)` — insert message
- `markAsRead(messageId, userId)` — update readBy
- `getParticipants(conversationId)` — list participants
- `addParticipant(conversationId, userId, role)` — add to group
- `leaveConversation(conversationId, userId)` — set isLeft=true
- `updateParticipantRole(conversationId, userId, role)` — change role
- `muteConversation(conversationId, userId, muted)` — toggle mute
- `subscribeToMessages(conversationId, onMessage)` — realtime
- `subscribeToConversationUpdates(userId, onUpdate)` — realtime
- `unsubscribe(channel)` — cleanup

- [ ] **Step 2: Repository provider kaydi**

```dart
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(
    conversationSource: ref.watch(conversationRemoteSourceProvider),
    messageSource: ref.watch(messageRemoteSourceProvider),
  );
});
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/messaging_repository.dart lib/data/repositories/repository_providers.dart
git commit -m "feat(messaging): add messaging repository with realtime support"
```

---

### Task 7: Feature Providers

**Files:**
- Create: `lib/features/messaging/providers/messaging_providers.dart`

- [ ] **Step 1: Provider dosyasini olustur**

Providers:
- `isMessagingEnabledProvider` — feature flag
- `conversationsProvider(userId)` — FutureProvider.family, fetches all conversations
- `conversationByIdProvider(id)` — FutureProvider.family
- `messagesProvider({conversationId, userId})` — FutureProvider.family, paginated
- `conversationSearchQueryProvider` — NotifierProvider for search
- `filteredConversationsProvider(conversations)` — Provider.family for search filtering
- `unreadCountProvider(userId)` — Provider computing total unread from conversations list

- [ ] **Step 2: Commit**

```bash
git add lib/features/messaging/providers/messaging_providers.dart
git commit -m "feat(messaging): add messaging feature providers"
```

---

### Task 8: Form Providers + Realtime Providers

**Files:**
- Create: `lib/features/messaging/providers/messaging_form_providers.dart`
- Create: `lib/features/messaging/providers/messaging_realtime_providers.dart`

- [ ] **Step 1: Form providers**

`MessagingFormState` + `MessagingFormNotifier`:
- `sendMessage(conversationId, senderId, senderName, content, messageType, ...)` — send message
- `createGroupConversation(creatorId, name, participantIds)` — create group
- `startDirectConversation(userId1, userId2, username1, username2)` — find or create 1-1
- `leaveGroup(conversationId, userId)` — leave group
- `addMember(conversationId, userId)` — add to group
- `toggleMute(conversationId, userId, muted)` — mute/unmute

- [ ] **Step 2: Realtime providers**

`MessagingRealtimeNotifier extends Notifier<List<Message>>`:
- `build()` — returns empty list
- `subscribe(conversationId)` — starts realtime subscription, adds new messages to state
- `unsubscribe()` — cleanup
- Uses `ref.onDispose()` for automatic cleanup

`TypingIndicatorNotifier extends Notifier<Set<String>>`:
- Tracks who is typing via Presence API
- `startTyping(conversationId, userId)` — broadcast typing
- `stopTyping(conversationId, userId)` — stop broadcast
- Timeout: auto-stop after 5 seconds

- [ ] **Step 3: Commit**

```bash
git add lib/features/messaging/providers/messaging_form_providers.dart lib/features/messaging/providers/messaging_realtime_providers.dart
git commit -m "feat(messaging): add form and realtime providers"
```

---

### Task 9: Lokalizasyon

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: messaging bolumunu 3 dile ekle**

~70 key: sohbet listesi, mesaj alanlari, grup yonetimi, online/offline/yaziyor, bos durum, hata mesajlari, grup form, uye yonetimi, bildirim metinleri.

Key ornekleri: `messaging.title`, `messaging.new_message`, `messaging.new_group`, `messaging.group_name`, `messaging.add_members`, `messaging.type_message`, `messaging.send`, `messaging.typing`, `messaging.online`, `messaging.offline`, `messaging.no_conversations`, `messaging.no_messages`, `messaging.mute`, `messaging.unmute`, `messaging.leave_group`, `messaging.confirm_leave`, `messaging.group_settings`, `messaging.members`, `messaging.add_member`, `messaging.remove_member`, `messaging.make_admin`, `messaging.photo_message`, `messaging.bird_card_message`, `messaging.listing_card_message`, `messaging.message_deleted`, `messaging.read`, `messaging.delivered`, `messaging.search_hint`, `messaging.no_results`, `messaging.max_members`, `messaging.blocked_user`, etc.

- [ ] **Step 2: L10n sync kontrolu**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All keys in sync

- [ ] **Step 3: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(messaging): add localization keys for tr/en/de"
```

---

### Task 10: Routes

**Files:**
- Modify: `lib/router/route_names.dart`
- Create: `lib/router/routes/messaging_routes.dart`
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Route sabitleri**

```dart
  // Messaging
  static const messages = '/messages';
  static const messageDetail = '/messages/:id';
  static const messageGroupForm = '/messages/group/form';
```

- [ ] **Step 2: Route builder**

```dart
List<RouteBase> buildMessagingRoutes() => [
  GoRoute(
    path: AppRoutes.messages,
    builder: (context, state) => const MessagesScreen(),
    routes: [
      GoRoute(path: 'group/form', builder: (context, state) => const GroupFormScreen()),
      GoRoute(
        path: ':id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          if (!isValidRouteId(id)) return const NotFoundScreen();
          return MessageDetailScreen(conversationId: id);
        },
      ),
    ],
  ),
];
```

- [ ] **Step 3: Router entegrasyonu**

`...buildMessagingRoutes(),` marketplace routes'un altina ekle.

- [ ] **Step 4: Commit**

```bash
git add lib/router/route_names.dart lib/router/routes/messaging_routes.dart lib/router/app_router.dart
git commit -m "feat(messaging): add route names, route builder, and router integration"
```

---

### Task 11: Conversations List Screen

**Files:**
- Create: `lib/features/messaging/screens/messages_screen.dart`

- [ ] **Step 1: Sohbet listesi ekrani**

ConsumerWidget with:
- AppBar: title "messaging.title".tr(), action: new group button
- Body: FutureProvider conversations list
- FAB: new message (start direct conversation)
- RefreshIndicator
- AsyncValue.when with loading/error/empty/data states
- ConversationTile widget for each conversation
- Search bar for filtering conversations

- [ ] **Step 2: Commit**

```bash
git add lib/features/messaging/screens/messages_screen.dart
git commit -m "feat(messaging): add conversations list screen"
```

---

### Task 12: Conversation Tile Widget

**Files:**
- Create: `lib/features/messaging/widgets/conversation_tile.dart`

- [ ] **Step 1: Sohbet karti widget'i**

StatelessWidget showing:
- Avatar (group image or user avatar)
- Conversation name (group name or other user's name)
- Last message preview (truncated)
- Timestamp (relative: just now, 5m, 1h, yesterday)
- Unread badge
- Muted icon
- Verified breeder badge if applicable
- InkWell with `context.push('/messages/${conversation.id}')`

- [ ] **Step 2: Commit**

```bash
git add lib/features/messaging/widgets/conversation_tile.dart
git commit -m "feat(messaging): add conversation tile widget"
```

---

### Task 13: Message Detail Screen (Chat)

**Files:**
- Create: `lib/features/messaging/screens/message_detail_screen.dart`

- [ ] **Step 1: Sohbet detay ekrani (ConsumerStatefulWidget)**

This is the core chat screen:
- AppBar: conversation name, online status, group member count
- Body: reversed ListView of messages (newest at bottom)
- Bottom: message input bar with send button
- Realtime subscription on initState, unsubscribe on dispose
- Typing indicator display
- Message bubbles (left for others, right for self)
- Different bubble layouts for text/image/birdCard/listingCard
- Auto-scroll to bottom on new message
- Read receipt display
- Pull-to-load-more (older messages)

Key implementation details:
- `ScrollController` + `TextEditingController` — both disposed
- Realtime: subscribe in initState via `messagingRealtimeProvider`
- Typing: debounced typing indicator via Presence API
- Mark as read: when message appears in viewport

- [ ] **Step 2: Commit**

```bash
git add lib/features/messaging/screens/message_detail_screen.dart
git commit -m "feat(messaging): add message detail (chat) screen"
```

---

### Task 14: Message Bubble Widget

**Files:**
- Create: `lib/features/messaging/widgets/message_bubble.dart`

- [ ] **Step 1: Mesaj baloncugu widget'i**

StatelessWidget with:
- Alignment: right for self, left for others
- Sender name (group only, not for self)
- Content based on messageType:
  - text: Text widget
  - image: Image.network with tap to expand
  - birdCard: Mini card with bird info from referenceData
  - listingCard: Mini card with listing info from referenceData
- Timestamp
- Read receipt indicator (for self messages in direct)
- Long press for delete option (own messages only)

- [ ] **Step 2: Commit**

```bash
git add lib/features/messaging/widgets/message_bubble.dart
git commit -m "feat(messaging): add message bubble widget"
```

---

### Task 15: Message Input Bar Widget

**Files:**
- Create: `lib/features/messaging/widgets/message_input_bar.dart`

- [ ] **Step 1: Mesaj giris cubugu**

ConsumerStatefulWidget:
- TextFormField with hint "messaging.type_message".tr()
- Send button (icon, enabled only when text not empty)
- Attachment button (opens bottom sheet: photo, bird card, listing card)
- Typing indicator emission on text change (debounced 500ms)
- TextEditingController disposed

- [ ] **Step 2: Commit**

```bash
git add lib/features/messaging/widgets/message_input_bar.dart
git commit -m "feat(messaging): add message input bar widget"
```

---

### Task 16: Group Form Screen

**Files:**
- Create: `lib/features/messaging/screens/group_form_screen.dart`

- [ ] **Step 1: Grup olusturma ekrani (ConsumerStatefulWidget)**

Form with:
- Group name field (required)
- Group photo (optional, StorageService upload)
- Member selection: search users, select up to 50
- Member list with remove option
- Create button → createGroupConversation
- ref.listen for success → context.pop()

- [ ] **Step 2: Commit**

```bash
git add lib/features/messaging/screens/group_form_screen.dart
git commit -m "feat(messaging): add group creation form screen"
```

---

### Task 17: Widget + Unit Tests

**Files:**
- Create: `test/features/messaging/providers/messaging_form_providers_test.dart`
- Create: `test/features/messaging/screens/messages_screen_test.dart`
- Create: `test/data/models/conversation_model_test.dart`
- Create: `test/data/models/message_model_test.dart`

- [ ] **Step 1: Form provider testi**

Test sendMessage, createGroupConversation, startDirectConversation, reset.

- [ ] **Step 2: Widget testi**

Test loading/empty/data states for MessagesScreen.

- [ ] **Step 3: Model testleri**

Round-trip serialization + unknown enum + extension methods.

- [ ] **Step 4: Testleri calistir**

Run: `flutter test test/features/messaging/ test/data/models/conversation_model_test.dart test/data/models/message_model_test.dart`
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add test/features/messaging/ test/data/models/conversation_model_test.dart test/data/models/message_model_test.dart
git commit -m "test(messaging): add model, provider, and widget tests"
```

---

### Task 18: Marketplace Entegrasyonu

**Files:**
- Modify: `lib/features/marketplace/screens/marketplace_detail_screen.dart`

- [ ] **Step 1: "Satıcıya Mesaj" butonunu bagla**

Mevcut placeholder `onPressed: () {}` yerine:
```dart
onPressed: () async {
  final notifier = ref.read(messagingFormStateProvider.notifier);
  final conversationId = await notifier.startDirectConversation(
    userId1: userId,
    userId2: listing.userId,
    username1: '', // current user name
    username2: listing.username,
  );
  if (context.mounted && conversationId != null) {
    context.push('${AppRoutes.messages}/$conversationId');
  }
},
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/marketplace/screens/marketplace_detail_screen.dart
git commit -m "feat(messaging): integrate messaging with marketplace detail screen"
```

---

### Task 19: CLAUDE.md Stats + Final Dogrulama

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: verify_rules.py --fix calistir**

Run: `python3 scripts/verify_rules.py --fix`

- [ ] **Step 2: Quality kontrolleri**

Run:
- `python3 scripts/verify_code_quality.py`
- `python3 scripts/check_l10n_sync.py`
- `flutter analyze --no-fatal-infos`

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: update CLAUDE.md stats for messaging feature"
```
