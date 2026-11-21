/// Compte connecté, tel que renvoyé par `GET /me`.
class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.locale,
    required this.status,
    required this.roles,
    this.name,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      locale: (json['locale'] as String?) ?? 'fr',
      status: (json['status'] as String?) ?? 'active',
      roles: ((json['roles'] as List<dynamic>?) ?? const <dynamic>[])
          .map((role) => role as String)
          .toList(growable: false),
    );
  }

  final String id;
  final String phone;
  final String? name;
  final String locale;
  final String status;
  final List<String> roles;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'phone': phone,
        'name': name,
        'locale': locale,
        'status': status,
        'roles': roles,
      };

  AppUser copyWith({String? name, String? locale}) {
    return AppUser(
      id: id,
      phone: phone,
      name: name ?? this.name,
      locale: locale ?? this.locale,
      status: status,
      roles: roles,
    );
  }
}