// lib/models/user_model.dart

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      isAdmin: map['isAdmin'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'username'  : username,
    'email'     : email,
    'avatarUrl' : avatarUrl,
    'isAdmin'   : isAdmin,
    'createdAt' : createdAt.millisecondsSinceEpoch,
  };

  UserModel copyWith({String? username, String? avatarUrl}) => UserModel(
    id: id,
    username: username ?? this.username,
    email: email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    isAdmin: isAdmin,
    createdAt: createdAt,
  );
}