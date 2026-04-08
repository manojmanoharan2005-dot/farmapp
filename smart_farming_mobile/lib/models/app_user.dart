class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String state;
  final String district;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.state,
    required this.district,
  });

  factory AppUser.fromSessionMap(Map<String, dynamic> map) {
    return AppUser(
      id: (map['user_id'] ?? '').toString(),
      name: (map['user_name'] ?? 'Farmer').toString(),
      email: (map['user_email'] ?? '').toString(),
      phone: (map['user_phone'] ?? '').toString(),
      state: (map['user_state'] ?? '').toString(),
      district: (map['user_district'] ?? '').toString(),
    );
  }
}
