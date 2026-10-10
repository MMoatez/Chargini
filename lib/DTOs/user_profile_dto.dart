class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.role,
    this.vehiculeCount = 0,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      birthDate: DateTime.tryParse(json['birthDate']?.toString() ?? ''),
      role: json['role']?.toString() ?? 'user',
      vehiculeCount: (json['vehiculeCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final DateTime? birthDate;
  final String role;
  final int vehiculeCount;

  String get fullName => '$firstName $lastName'.trim();

  UserProfileDto copyWith({int? vehiculeCount}) => UserProfileDto(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    birthDate: birthDate,
    role: role,
    vehiculeCount: vehiculeCount ?? this.vehiculeCount,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'birthDate': birthDate?.toUtc().toIso8601String(),
    'role': role,
    'vehiculeCount': vehiculeCount,
  };

  String get initials {
    final first = firstName.trim().isEmpty ? '' : firstName.trim()[0];
    final last = lastName.trim().isEmpty ? '' : lastName.trim()[0];
    return '$first$last'.toUpperCase();
  }
}
