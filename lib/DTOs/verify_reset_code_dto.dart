class VerifyResetCodeDto {
  const VerifyResetCodeDto({required this.email, required this.code});

  final String email;
  final String code;

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'code': code.trim(),
  };
}
