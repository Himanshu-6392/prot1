import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

class DummySeeder {
  static Future<void> seedLenders() async {
    final firestore = FirebaseFirestore.instance;
    final snap = await firestore.collection(AppConstants.colLenders).limit(1).get();
    if (snap.docs.isNotEmpty) return; // Already seeded

    final lenders = [
      {
        'id': 'dummy_1',
        'userId': 'dummy_user_1',
        'businessName': 'Capital Trust',
        'city': 'Mumbai',
        'minAmount': 10000,
        'maxAmount': 500000,
        'interestRatePerMonth': 1.5,
        'maxTenureMonths': 24,
        'acceptedCollateral': ['Gold', 'Electronics', 'Vehicles'],
        'isActive': true,
        'isVerified': true,
        'isFeatured': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_2',
        'userId': 'dummy_user_2',
        'businessName': 'QuickFunds Ltd',
        'city': 'Delhi',
        'minAmount': 5000,
        'maxAmount': 100000,
        'interestRatePerMonth': 2.0,
        'maxTenureMonths': 12,
        'acceptedCollateral': ['Laptops', 'Mobiles'],
        'isActive': true,
        'isVerified': false,
        'isFeatured': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_3',
        'userId': 'dummy_user_3',
        'businessName': 'Secure Assets Finance',
        'city': 'Bangalore',
        'minAmount': 50000,
        'maxAmount': 2000000,
        'interestRatePerMonth': 1.2,
        'maxTenureMonths': 36,
        'acceptedCollateral': ['Property', 'Gold', 'Cars'],
        'isActive': true,
        'isVerified': true,
        'isFeatured': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'dummy_4',
        'userId': 'dummy_user_4',
        'businessName': 'MicroLend India',
        'city': 'Pune',
        'minAmount': 1000,
        'maxAmount': 25000,
        'interestRatePerMonth': 3.0,
        'maxTenureMonths': 6,
        'acceptedCollateral': ['Electronics'],
        'isActive': true,
        'isVerified': false,
        'isFeatured': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = firestore.batch();
    for (var lender in lenders) {
      final doc = firestore.collection(AppConstants.colLenders).doc(lender['id'] as String);
      batch.set(doc, lender);
    }
    await batch.commit();
  }
}
