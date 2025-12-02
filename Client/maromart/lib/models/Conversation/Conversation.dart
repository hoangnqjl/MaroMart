// Trong Conversation model
import '../Message/Message.dart';
import '../User/User.dart';

class Conversation {
  final String conId;
  final String userId1;
  final String userId2;
  final Message? latestMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? partnerInfo; // THÊM FIELD NÀY

  Conversation({
    required this.conId,
    required this.userId1,
    required this.userId2,
    this.latestMessage,
    required this.createdAt,
    required this.updatedAt,
    this.partnerInfo, // THÊM FIELD NÀY
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conId: json['conId'] ?? '',
      userId1: json['userId1'] ?? '',
      userId2: json['userId2'] ?? '',
      latestMessage: json['latest_message'] != null
          ? Message.fromJson(json['latest_message'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      partnerInfo: json['partnerInfo'] != null  // THÊM FIELD NÀY
          ? User.fromJson(json['partnerInfo'])
          : null,
    );
  }
}