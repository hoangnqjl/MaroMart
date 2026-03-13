
import 'dart:convert';

class ProductAddress {
  final String province;
  final String commute;
  final String detail;

  ProductAddress({
    this.province = '',
    this.commute = '',
    this.detail = '',
  });

  factory ProductAddress.fromJson(dynamic json) {
    if (json == null) return ProductAddress();

    if (json is String) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map<String, dynamic>) {
          return ProductAddress.fromMap(decoded);
        }
      } catch (e) {
        return ProductAddress();
      }
    }

    if (json is Map<String, dynamic>) {
      return ProductAddress.fromMap(json);
    }

    return ProductAddress();
  }

  factory ProductAddress.fromMap(Map<String, dynamic> map) {
    return ProductAddress(
      province: map['province']?.toString() ?? '',
      // Map 'commune' or 'ward' to 'commute' field
      commute: map['commune']?.toString() ?? map['ward']?.toString() ?? map['commute']?.toString() ?? '',
      detail: map['detail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province': province,
      'commute': commute,
      'detail': detail,
    };
  }

  String get fullAddress {
    List<String> parts = [];
    if (detail.isNotEmpty) parts.add(detail);
    if (commute.isNotEmpty) parts.add(commute);
    if (province.isNotEmpty) parts.add(province);
    return parts.join(', ');
  }
}

class ProductAttribute {
  final String? ram;
  final String? cpu;
  final String? storage;
  final String? screen;
  final Map<String, dynamic> otherAttributes;

  ProductAttribute({
    this.ram,
    this.cpu,
    this.storage,
    this.screen,
    this.otherAttributes = const {},
  });

  factory ProductAttribute.fromJson(dynamic json) {
    if (json == null) return ProductAttribute();
    if (json is String) {
      try {
        final Map<String, dynamic> map = jsonDecode(json);
        return ProductAttribute.fromMap(map);
      } catch (e) {
        return ProductAttribute();
      }
    }
    if (json is Map<String, dynamic>) {
      return ProductAttribute.fromMap(json);
    }
    return ProductAttribute();
  }

  factory ProductAttribute.fromMap(Map<String, dynamic> map) {
    final ram = map['RAM'] ?? map['ram'];
    final cpu = map['CPU'] ?? map['cpu'];
    final storage = map['Storage'] ?? map['storage'];
    final screen = map['Screen'] ?? map['screen'];

    final otherAttrs = Map<String, dynamic>.from(map);
    otherAttrs.removeWhere((key, value) =>
        ['RAM', 'ram', 'CPU', 'cpu', 'Storage', 'storage', 'Screen', 'screen'].contains(key)
    );

    return ProductAttribute(
      ram: ram?.toString(),
      cpu: cpu?.toString(),
      storage: storage?.toString(),
      screen: screen?.toString(),
      otherAttributes: otherAttrs,
    );
  }
}

class UserInfo {
  final String userId;
  final String fullName;
  final String email;
  final String avatarUrl;
  final String phoneNumber;

  UserInfo({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.phoneNumber = '',
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Người dùng ẩn danh',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      // Handle both string and int for phone number
      phoneNumber: json['phoneNumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
    };
  }
}

// --- 4. Main Class Product ---
class Product {
  final String id;
  final String productId;
  final String categoryId;
  final String userId;
  final String productName;
  final int productPrice;
  final String productDescription;
  
  final String status; // Added status field

  final String productCondition;
  final String productBrand;
  final String productWP;
  final String productOrigin;
  final String productCategory;

  final dynamic productAttribute;
  final ProductAddress? productAddress;

  final List<String> productMedia;
  final String createdAt;
  final String updatedAt;

  final UserInfo? userInfo;

  Product({
    required this.id,
    required this.productId,
    required this.categoryId,
    required this.userId,
    required this.productName,
    required this.productPrice,
    required this.productDescription,
    this.status = 'active', // Default status

    required this.productCondition,
    required this.productBrand,
    required this.productWP,
    required this.productOrigin,
    required this.productCategory,
    required this.productAttribute,
    this.productAddress,
    required this.productMedia,
    required this.createdAt,
    required this.updatedAt,
    this.userInfo,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',

      productPrice: json['productPrice'] is int
          ? json['productPrice']
          : int.tryParse(json['productPrice'].toString()) ?? 0,

      productDescription: json['productDescription']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active', // Parse status

      productCondition: json['productCondition']?.toString() ?? '',
      productBrand: json['productBrand']?.toString() ?? '',
      productWP: json['productWP']?.toString() ?? '',
      productOrigin: json['productOrigin']?.toString() ?? '',
      productCategory: json['productCategory']?.toString() ?? '',

      // Attribute: Keep raw value or parse if needed.
      // Using 'dynamic' here allows flexibility in UI parsing.
      productAttribute: json['productAttribute'],

      // Address Parsing
      productAddress: json['productAddress'] != null
          ? ProductAddress.fromJson(json['productAddress'])
          : null,

      productMedia: json['productMedia'] != null
          ? List<String>.from(json['productMedia'])
          : [],

      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',

      userInfo: json['userInfo'] != null
          ? UserInfo.fromJson(json['userInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'categoryId': categoryId,
      'userId': userId,
      'productName': productName,
      'productPrice': productPrice,
      'productDescription': productDescription,
      'status': status,
      'productCondition': productCondition,
      'productBrand': productBrand,
      'productWP': productWP,
      'productOrigin': productOrigin,
      'productCategory': productCategory,
      'productAttribute': productAttribute,
      'productAddress': productAddress?.toJson(),
      'productMedia': productMedia,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userInfo': userInfo?.toJson(),
    };
  }

  String get formattedPrice {
    return productPrice.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}