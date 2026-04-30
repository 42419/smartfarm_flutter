class AppUser {
  final String id;
  final String username;
  final String? email;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? profession;
  final String farm;

  const AppUser({
    required this.id,
    required this.username,
    this.email,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.profession,
    required this.farm,
  });

  factory AppUser.fromProfilesRow(Map<String, dynamic> row) {
    return AppUser(
      id: row['id']?.toString() ?? '',
      username: row['username']?.toString() ?? '',
      email: row['email']?.toString(),
      nickname: row['nickname']?.toString() ?? '',
      avatarUrl: row['avatar_url']?.toString(),
      bio: row['bio']?.toString(),
      phone: row['phone']?.toString(),
      profession: row['profession']?.toString(),
      farm: row['farm']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toProfilesRow() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (phone != null) 'phone': phone,
      if (profession != null) 'profession': profession,
      'farm': farm,
    };
  }
}
