class UserModel {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final String? address;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.address,
    required this.isVerified,
    required this.createdAt,
  });

  // من JSON إلى UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // من UserModel إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'address': address,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
