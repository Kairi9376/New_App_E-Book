class AuthorModel {
  final int authorId;
  final String name;
  final String? biography;
  final String? createdAt;

  const AuthorModel({
    required this.authorId,
    required this.name,
    this.biography,
    this.createdAt,
  });

  factory AuthorModel.fromMap(Map<String, dynamic> map) {
    return AuthorModel(
      authorId: int.tryParse(map['author_id']?.toString() ?? '') ?? 0,
      name: map['name']?.toString() ?? '',
      biography: map['biography']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author_id': authorId,
      'name': name,
      'biography': biography,
      'created_at': createdAt,
    };
  }
}
