class FaceProfile {
  final String id;
  final String name;
  final String imagePath;
  final bool isDefault;

  FaceProfile({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.isDefault,
  });

  factory FaceProfile.fromJson(Map<String, dynamic> json) {
    return FaceProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'isDefault': isDefault,
    };
  }
}
