import 'package:uuid/uuid.dart';

enum MessageStatus { sending, sent, failed }

const _uuid = Uuid();

class Message {
  final String localId;
  final String? messageId;
  final String? conId;
  final String sender;
  final String receiver;
  final String? content;
  final List<MessageMedia> media;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MessageStatus status;

  Message({
    String? localId,
    this.messageId,
    this.conId,
    required this.sender,
    required this.receiver,
    this.content,
    required this.media,
    required this.createdAt,
    this.updatedAt,
    this.status = MessageStatus.sent,
  }) : localId = localId ?? _uuid.v4();

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      // Chấp nhận null nếu JSON không có
      messageId: json['messageId'] as String?,
      conId: json['conId'] as String?,

      sender: json['sender'] as String,
      receiver: json['receiver'] as String,
      content: json['content'] as String?,
      media: (json['media'] as List<dynamic>?)
          ?.map((m) => MessageMedia.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: MessageStatus.sent,
    );
  }

  // Hàm tạo tin nhắn tạm (Optimistic UI)
  static Message createTemp({
    required String conId,
    required String sender,
    required String receiver,
    String? content,
    List<MessageMedia>? media,
  }) {
    return Message(
      messageId: "temp_${_uuid.v4()}", // ID tạm
      conId: conId,
      sender: sender,
      receiver: receiver,
      content: content,
      media: media ?? [],
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
  }
}
class MessageMedia {
  final String type; // 'image', 'video', 'audio
  final String url;

  MessageMedia({required this.type, required this.url});

  factory MessageMedia.fromJson(Map<String, dynamic> json) {
    return MessageMedia(
      type: json['type'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'url': url,
  };
}