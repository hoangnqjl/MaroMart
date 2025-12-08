class User {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final int phoneNumber;
  final String role;
  final String? country;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? avatarUrl;

  User({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.country,
    required this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
  });

  // --- Parse từ JSON response ---
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? 0,
      role: json['role'] ?? 'user',
      country: json['country'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  // --- Chuyển sang JSON để gửi lên API ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'country': country,
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }

  // --- copyWith ---
  User copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    int? phoneNumber,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      country: country ?? this.country,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  String get displayName => fullName.isNotEmpty ? fullName : email;

  String get formattedPhone {
    final phone = phoneNumber.toString();
    if (phone.length >= 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => role.toLowerCase() == 'user';

  @override
  String toString() {
    return 'User(id: $id, userId: $userId, fullName: $fullName, email: $email, role: $role, avatarUrl: $avatarUrl)';
  }
}