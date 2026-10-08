class RegisterUserDto {
  const RegisterUserDto({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.email,
    required this.phone,
    required this.gender,
    required this.role,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String email;
  final String phone;
  final String gender;
  final String role;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'birthDate': birthDate.toUtc().toIso8601String(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'gender': gender,
      'role': role,
      'password': password,
    };
  }
}
