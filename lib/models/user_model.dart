import 'user_preferences.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isVerified;
  final UserPreferences preferences;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.isVerified = false,
    this.preferences = const UserPreferences(),
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      isVerified: json['isVerified'] == true,
      preferences: UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>?),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isVerified': isVerified,
        'preferences': preferences.toJson(),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    bool? isVerified,
    UserPreferences? preferences,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        role: role,
        isVerified: isVerified ?? this.isVerified,
        preferences: preferences ?? this.preferences,
        createdAt: createdAt,
      );
}
