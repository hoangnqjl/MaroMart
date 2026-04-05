class Category {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categorySpec;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categorySpec,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      categoryIcon: json['categoryIcon']?.toString(),
      categorySpec: json['categorySpec']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categorySpec': categorySpec,
    };
  }
}
