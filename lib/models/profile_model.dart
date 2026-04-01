class ProfileModel {
  final String id;
  final String username;
  final String? fullName;
  final String role; // member | editor | admin
  final String createdAt;
  final String? avatarUrl;
  final String? bio;

  const ProfileModel({
    required this.id,
    required this.username,
    this.fullName,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
    this.bio,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] ?? '',
    username: json['username'] ?? '',
    fullName: json['full_name'],
    role: json['role'] ?? 'member',
    createdAt: json['created_at'] ?? '',
    avatarUrl: json['avatar_url'],
    bio: json['bio'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'role': role,
    'created_at': createdAt,
    'avatar_url': avatarUrl,
    'bio': bio,
  };

  bool get isEditor => role == 'editor' || role == 'admin';
  bool get isAdmin => role == 'admin';

  ProfileModel copyWith({String? fullName, String? bio, String? avatarUrl, String? role}) =>
    ProfileModel(
      id: id, username: username, createdAt: createdAt,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
}
