class AppUser {
  final String username;
  final String password;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String? email;
  final String? phone;
  final String? profession;
  final String farm;

  const AppUser({
    required this.username,
    required this.password,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.email,
    this.phone,
    this.profession,
    required this.farm,
  });

  factory AppUser.fromSupabase(Map<String, dynamic> row) {
    return AppUser(
      username: row['username']?.toString() ?? '',
      password: row['password']?.toString() ?? '',
      nickname: row['nickname']?.toString() ?? '',
      avatarUrl: row['avatar_url']?.toString(),
      bio: row['bio']?.toString(),
      email: row['email']?.toString(),
      phone: row['phone']?.toString(),
      profession: row['profession']?.toString(),
      farm: row['farm']?.toString() ?? '',
    );
  }
}
