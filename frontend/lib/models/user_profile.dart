class UserProfile {
  final String id;
  final String name;
  final String role;
  final String email;
  final String? avatar; // Thêm thuộc tính avatar

  UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.avatar, // Thêm vào constructor
  });
}
