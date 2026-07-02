// ─────────────────────────────────────────────
// App-wide Constants
// ─────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  static const String appName        = 'PeerLend';
  static const String appTagline     = 'Secure Lending, Peer to Peer';
  static const String appVersion     = '1.0.0';

  // Firestore Collections
  static const String colUsers       = 'users';
  static const String colLenders     = 'lenders';
  static const String colBorrowers   = 'borrowers';
  static const String colRequests    = 'loan_requests';
  static const String colMatches     = 'matches';
  static const String colChats       = 'chats';
  static const String colMessages    = 'messages';
  static const String colCollateral  = 'collateral';
  static const String colReviews     = 'reviews';
  static const String colReports     = 'reports';
  static const String colSubscriptions = 'subscriptions';

  // Pricing
  static const int contactUnlockBasic   = 199;
  static const int contactUnlockPremium = 999;
  static const int subscriptionBasic    = 999;
  static const int subscriptionPremium  = 2999;

  // Validation
  static const int minLoanAmount     = 1000;
  static const int maxLoanAmount     = 10000000;
  static const double minInterestRate = 0.5;
  static const double maxInterestRate = 20.0;
  static const int maxTenureMonths   = 60;

  // Collateral Types
  static const List<String> collateralTypes = [
    'Laptop', 'Mobile', 'Gold', 'Bike', 'Car', 'Electronics', 'Other',
  ];

  // LTV Ratios
  static const List<double> ltvOptions = [50, 60, 70, 75, 80, 85, 90];

  // Indian Cities
  static const List<String> popularCities = [
    'Mumbai', 'Delhi', 'Bengaluru', 'Hyderabad', 'Chennai', 'Kolkata',
    'Pune', 'Ahmedabad', 'Jaipur', 'Lucknow', 'Kanpur', 'Nagpur',
    'Indore', 'Thane', 'Bhopal', 'Patna', 'Vadodara', 'Ghaziabad',
    'Ludhiana', 'Agra', 'Nashik', 'Faridabad', 'Meerut', 'Rajkot',
    'Varanasi', 'Srinagar', 'Aurangabad', 'Dhanbad', 'Amritsar',
    'Allahabad', 'Ranchi', 'Howrah', 'Coimbatore', 'Jabalpur',
    'Gwalior', 'Vijayawada', 'Jodhpur', 'Madurai', 'Raipur', 'Kota',
  ];

  // Subscription Features
  static const Map<String, List<String>> subscriptionFeatures = {
    'Basic': [
      'Up to 5 active listings',
      'Standard search visibility',
      'Chat with matched users',
      'Basic analytics dashboard',
    ],
    'Premium': [
      'Unlimited active listings',
      'Verified badge on profile',
      'Priority in search results',
      'Advanced analytics & reports',
      'Featured listing (1/month)',
      'Dedicated support',
    ],
  };
}

// ─────────────────────────────────────────────
// Spacing
// ─────────────────────────────────────────────
class Spacing {
  Spacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
  static const double h   = 64;
}
