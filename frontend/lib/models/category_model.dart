class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String description;
  final int sortOrder;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      description: json['description'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'sortOrder': sortOrder,
    };
  }
}
