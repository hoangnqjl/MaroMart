class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final String? relatedUrl;
  final String? relatedId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    this.relatedUrl,
    this.relatedId,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,

      title: (json['title'] ?? 'Thông báo') as String,
      content: (json['content'] ?? '') as String,
      type: (json['type'] ?? 'system') as String,

      // Xử lý boolean
      isRead: (json['isRead'] ?? false) as bool,

      // Các trường nullable
      relatedUrl: json['relatedUrl'] as String?,
      relatedId: json['relatedId'] as String?,

      // Xử lý Map an toàn (tránh lỗi crash khi cast)
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,

      // Xử lý ngày giờ và chuyển sang giờ địa phương
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    bool? isRead,
    String? relatedUrl,
    String? relatedId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedUrl: relatedUrl ?? this.relatedUrl,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}