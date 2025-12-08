class ChatPartner {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? email;

  ChatPartner({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.email,
  });

  factory ChatPartner.fromProductUserInfo(Map<String, dynamic> json) {
    return ChatPartner(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? 'Người dùng',
      avatarUrl: json['avatarUrl'],
      email: json['email'],
    );
  }

  factory ChatPartner.fromUser(dynamic user) {
    return ChatPartner(
      userId: user.userId,
      fullName: user.fullName,
      avatarUrl: user.avatarUrl,
      email: user.email,
    );
  }
}