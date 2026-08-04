class CategoryModel {
  final int categoryId;
  final String name;
  final String? createdAt;

  const CategoryModel({
    required this.categoryId,
    required this.name,
    this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: int.tryParse(map['category_id']?.toString() ?? '') ?? 0,
      name: map['name']?.toString() ?? '',
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'name': name,
      'created_at': createdAt,
    };
  }
}
