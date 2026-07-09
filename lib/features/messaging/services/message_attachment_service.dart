import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/repositories/repository_providers.dart';

typedef PickMessagePhoto = Future<XFile?> Function(ImageSource source);

typedef UploadMessagePhoto =
    Future<String> Function({
      required String userId,
      required String conversationId,
      required XFile file,
    });

class MessageAttachmentService {
  const MessageAttachmentService({
    required this.pickPhoto,
    required this.uploadPhoto,
  });

  final PickMessagePhoto pickPhoto;
  final UploadMessagePhoto uploadPhoto;
}

final messageAttachmentServiceProvider = Provider<MessageAttachmentService>((
  ref,
) {
  final picker = ImagePicker();
  final repository = ref.watch(messagingRepositoryProvider);
  return MessageAttachmentService(
    pickPhoto: (source) => picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    ),
    uploadPhoto: repository.uploadMessagePhoto,
  );
});
