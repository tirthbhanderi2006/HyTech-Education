class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? nationality;
  final String? passportExpiry;
  final String? educationLevel;
  final String subscriptionTier;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.nationality,
    this.passportExpiry,
    this.educationLevel,
    required this.subscriptionTier,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'],
        fullName: json['full_name'],
        phone: json['phone'],
        nationality: json['nationality'],
        passportExpiry: json['passport_expiry'],
        educationLevel: json['education_level'],
        subscriptionTier: json['subscription_tier'] ?? 'free',
        isVerified: json['is_verified'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'nationality': nationality,
        'passport_expiry': passportExpiry,
        'education_level': educationLevel,
        'subscription_tier': subscriptionTier,
        'is_verified': isVerified,
        'created_at': createdAt.toIso8601String(),
      };
}
