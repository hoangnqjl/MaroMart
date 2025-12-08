enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;

  MediaItem({required this.type, required this.url});

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      type: (json['type']?.toString().toLowerCase() == 'video')
          ? MediaType.video
          : MediaType.image,
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == MediaType.video ? 'video' : 'image',
      'url': url,
    };
  }
}