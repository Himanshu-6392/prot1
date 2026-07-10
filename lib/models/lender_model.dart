import 'package:cloud_firestore/cloud_firestore.dart';

class LenderModel {
  final String id;
  final String userId;
  final String businessName;
  final String city;
  final String? description;
  final double availableCapital;
  final double minLoanAmount;
  final double maxLoanAmount;
  final double interestRatePerMonth;
  final int maxTenureMonths;
  final List<String> acceptedCollateral;
  final double ltvRatio; // e.g. 70.0 means max 70% of collateral value
  final bool isVerified;
  final bool isActive;
  final double rating;
  final int ratingCount;
  final int completedDeals;
  final List<String> photoUrls;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LenderModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.city,
    this.description,
    required this.availableCapital,
    required this.minLoanAmount,
    required this.maxLoanAmount,
    required this.interestRatePerMonth,
    required this.maxTenureMonths,
    required this.acceptedCollateral,
    required this.ltvRatio,
    this.isVerified = false,
    this.isActive = true,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.completedDeals = 0,
    this.photoUrls = const [],
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LenderModel.fromMap(Map<String, dynamic> map, String id) {
    return LenderModel(
      id: id,
      userId: map['userId'] ?? '',
      businessName: map['businessName'] ?? '',
      city: map['city'] ?? '',
      description: map['description'],
      availableCapital: (map['availableCapital'] ?? 0).toDouble(),
      minLoanAmount: (map['minLoanAmount'] ?? 0).toDouble(),
      maxLoanAmount: (map['maxLoanAmount'] ?? 0).toDouble(),
      interestRatePerMonth: (map['interestRatePerMonth'] ?? 0).toDouble(),
      maxTenureMonths: map['maxTenureMonths'] ?? 12,
      acceptedCollateral: List<String>.from(map['acceptedCollateral'] ?? []),
      ltvRatio: (map['ltvRatio'] ?? 70).toDouble(),
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      completedDeals: map['completedDeals'] ?? 0,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      isFeatured: map['isFeatured'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'businessName': businessName,
        'city': city,
        'description': description,
        'availableCapital': availableCapital,
        'minLoanAmount': minLoanAmount,
        'maxLoanAmount': maxLoanAmount,
        'interestRatePerMonth': interestRatePerMonth,
        'maxTenureMonths': maxTenureMonths,
        'acceptedCollateral': acceptedCollateral,
        'ltvRatio': ltvRatio,
        'isVerified': isVerified,
        'isActive': isActive,
        'rating': rating,
        'ratingCount': ratingCount,
        'completedDeals': completedDeals,
        'photoUrls': photoUrls,
        'isFeatured': isFeatured,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  LenderModel copyWith({
    String? businessName,
    String? city,
    String? description,
    double? availableCapital,
    double? minLoanAmount,
    double? maxLoanAmount,
    double? interestRatePerMonth,
    int? maxTenureMonths,
    List<String>? acceptedCollateral,
    double? ltvRatio,
    bool? isVerified,
    bool? isActive,
    double? rating,
    int? ratingCount,
    int? completedDeals,
    List<String>? photoUrls,
    bool? isFeatured,
  }) =>
      LenderModel(
        id: id,
        userId: userId,
        businessName: businessName ?? this.businessName,
        city: city ?? this.city,
        description: description ?? this.description,
        availableCapital: availableCapital ?? this.availableCapital,
        minLoanAmount: minLoanAmount ?? this.minLoanAmount,
        maxLoanAmount: maxLoanAmount ?? this.maxLoanAmount,
        interestRatePerMonth: interestRatePerMonth ?? this.interestRatePerMonth,
        maxTenureMonths: maxTenureMonths ?? this.maxTenureMonths,
        acceptedCollateral: acceptedCollateral ?? this.acceptedCollateral,
        ltvRatio: ltvRatio ?? this.ltvRatio,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        completedDeals: completedDeals ?? this.completedDeals,
        photoUrls: photoUrls ?? this.photoUrls,
        isFeatured: isFeatured ?? this.isFeatured,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
