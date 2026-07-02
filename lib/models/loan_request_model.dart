import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanRequestStatus { open, matched, accepted, completed, cancelled, expired }

class LoanRequestModel {
  final String id;
  final String borrowerId;
  final String borrowerName;
  final String borrowerCity;
  final double loanAmount;
  final String collateralType;
  final double collateralValue;
  final double maxInterestRatePerMonth;
  final int tenureMonths;
  final String description;
  final bool isVerified;
  final LoanRequestStatus status;
  final List<String> collateralPhotoUrls;
  final List<String> savedByLenderIds;
  final double? borrowerRating;
  final DateTime createdAt;
  final DateTime expiresAt;

  const LoanRequestModel({
    required this.id,
    required this.borrowerId,
    required this.borrowerName,
    required this.borrowerCity,
    required this.loanAmount,
    required this.collateralType,
    required this.collateralValue,
    required this.maxInterestRatePerMonth,
    required this.tenureMonths,
    required this.description,
    this.isVerified = false,
    this.status = LoanRequestStatus.open,
    this.collateralPhotoUrls = const [],
    this.savedByLenderIds = const [],
    this.borrowerRating,
    required this.createdAt,
    required this.expiresAt,
  });

  factory LoanRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return LoanRequestModel(
      id:                      id,
      borrowerId:              map['borrowerId'] ?? '',
      borrowerName:            map['borrowerName'] ?? '',
      borrowerCity:            map['borrowerCity'] ?? '',
      loanAmount:              (map['loanAmount'] ?? 0).toDouble(),
      collateralType:          map['collateralType'] ?? '',
      collateralValue:         (map['collateralValue'] ?? 0).toDouble(),
      maxInterestRatePerMonth: (map['maxInterestRatePerMonth'] ?? 0).toDouble(),
      tenureMonths:            map['tenureMonths'] ?? 1,
      description:             map['description'] ?? '',
      isVerified:              map['isVerified'] ?? false,
      status:                  LoanRequestStatus.values.firstWhere(
                                 (e) => e.name == map['status'],
                                 orElse: () => LoanRequestStatus.open),
      collateralPhotoUrls:     List<String>.from(map['collateralPhotoUrls'] ?? []),
      savedByLenderIds:        List<String>.from(map['savedByLenderIds'] ?? []),
      borrowerRating:          (map['borrowerRating'] as num?)?.toDouble(),
      createdAt:               (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:               (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
    );
  }

  Map<String, dynamic> toMap() => {
    'borrowerId':              borrowerId,
    'borrowerName':            borrowerName,
    'borrowerCity':            borrowerCity,
    'loanAmount':              loanAmount,
    'collateralType':          collateralType,
    'collateralValue':         collateralValue,
    'maxInterestRatePerMonth': maxInterestRatePerMonth,
    'tenureMonths':            tenureMonths,
    'description':             description,
    'isVerified':              isVerified,
    'status':                  status.name,
    'collateralPhotoUrls':     collateralPhotoUrls,
    'savedByLenderIds':        savedByLenderIds,
    'borrowerRating':          borrowerRating,
    'createdAt':               Timestamp.fromDate(createdAt),
    'expiresAt':               Timestamp.fromDate(expiresAt),
  };
}
