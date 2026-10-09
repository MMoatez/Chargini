class ForgotPasswordDto {
  const ForgotPasswordDto({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email.trim().toLowerCase()};
}
