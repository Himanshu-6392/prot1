import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { borrower, lender, both, admin }
enum KycStatus { pending, submitted, verified, rejected }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final UserRole role;
  final KycStatus kycStatus;
  final bool isVerified;
  final bool isBlocked;
  final bool isPremium;
  final String? subscriptionPlan; // 'basic' | 'premium' | null
  final DateTime? subscriptionExpiry;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final String? city;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.role,
    this.kycStatus = KycStatus.pending,
    this.isVerified = false,
    this.isBlocked = false,
    this.isPremium = false,
    this.subscriptionPlan,
    this.subscriptionExpiry,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.city,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid:               id,
      name:              map['name'] ?? '',
      email:             map['email'] ?? '',
      phone:             map['phone'] ?? '',
      photoUrl:          map['photoUrl'],
      role:              UserRole.values.firstWhere(
                           (e) => e.name == map['role'],
                           orElse: () => UserRole.borrower),
      kycStatus:         KycStatus.values.firstWhere(
                           (e) => e.name == map['kycStatus'],
                           orElse: () => KycStatus.pending),
      isVerified:        map['isVerified'] ?? false,
      isBlocked:         map['isBlocked'] ?? false,
      isPremium:         map['isPremium'] ?? false,
      subscriptionPlan:  map['subscriptionPlan'],
      subscriptionExpiry: (map['subscriptionExpiry'] as Timestamp?)?.toDate(),
      createdAt:         (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:         (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken:          map['fcmToken'],
      city:              map['city'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name':              name,
    'email':             email,
    'phone':             phone,
    'photoUrl':          photoUrl,
    'role':              role.name,
    'kycStatus':         kycStatus.name,
    'isVerified':        isVerified,
    'isBlocked':         isBlocked,
    'isPremium':         isPremium,
    'subscriptionPlan':  subscriptionPlan,
    'subscriptionExpiry': subscriptionExpiry != null
                            ? Timestamp.fromDate(subscriptionExpiry!)
                            : null,
    'createdAt':         Timestamp.fromDate(createdAt),
    'updatedAt':         Timestamp.fromDate(updatedAt),
    'fcmToken':          fcmToken,
    'city':              city,
  };

  UserModel copyWith({
    String? name, String? email, String? phone, String? photoUrl,
    UserRole? role, KycStatus? kycStatus, bool? isVerified, bool? isBlocked,
    bool? isPremium, String? subscriptionPlan, DateTime? subscriptionExpiry,
    String? fcmToken, String? city,
  }) => UserModel(
    uid:               uid,
    name:              name              ?? this.name,
    email:             email             ?? this.email,
    phone:             phone             ?? this.phone,
    photoUrl:          photoUrl          ?? this.photoUrl,
    role:              role              ?? this.role,
    kycStatus:         kycStatus         ?? this.kycStatus,
    isVerified:        isVerified        ?? this.isVerified,
    isBlocked:         isBlocked         ?? this.isBlocked,
    isPremium:         isPremium         ?? this.isPremium,
    subscriptionPlan:  subscriptionPlan  ?? this.subscriptionPlan,
    subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
    createdAt:         createdAt,
    updatedAt:         DateTime.now(),
    fcmToken:          fcmToken          ?? this.fcmToken,
    city:              city              ?? this.city,
  );
}
