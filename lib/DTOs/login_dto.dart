class LoginDto {
  const LoginDto({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  final String email;
  final String password;
  final bool rememberMe;

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
    'rememberMe': rememberMe,
  };
}
