import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/firebase_providers.dart';
import '../../models/user_model.dart';

// ─── Auth Feature ─────────────────────────────
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/kyc_borrower_screen.dart';
import '../../features/auth/presentation/kyc_lender_screen.dart';

// ─── Shell / Nav ──────────────────────────────
import '../../features/shell/main_shell.dart';

// ─── Borrower Feature ────────────────────────
import '../../features/borrower/presentation/borrower_dashboard.dart';
import '../../features/borrower/presentation/post_request_screen.dart';
import '../../features/borrower/presentation/saved_lenders_screen.dart';

// ─── Lender Feature ──────────────────────────
import '../../features/lender/presentation/lender_dashboard.dart';
import '../../features/lender/presentation/create_offer_screen.dart';
import '../../features/lender/presentation/lender_profile_screen.dart';

// ─── Search ──────────────────────────────────
import '../../features/search/presentation/lender_search_screen.dart';
import '../../features/search/presentation/borrower_search_screen.dart';

// ─── Match ───────────────────────────────────
import '../../features/match/presentation/match_screen.dart';

// ─── Chat ────────────────────────────────────
import '../../features/chat/presentation/chat_list_screen.dart';

// ─── Collateral ──────────────────────────────
import '../../features/collateral/presentation/upload_collateral_screen.dart';
import '../../features/collateral/presentation/collateral_detail_screen.dart';

// ─── Subscription ────────────────────────────
import '../../features/subscription/presentation/plans_screen.dart';

// ─── Notifications ───────────────────────────
import '../../features/notifications/presentation/notifications_screen.dart';

// ─── Admin ───────────────────────────────────
import '../../features/admin/presentation/admin_dashboard_screen.dart';
// ─── Profile ───────────────────────────────────
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/bank_details_screen.dart';
import '../../features/profile/presentation/change_role_screen.dart';
import '../../features/profile/presentation/kyc_verification_screen.dart';
import '../../features/profile/presentation/security_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      final settingsBox = Hive.box('settings');
      final hasSeenOnboarding = settingsBox.get('hasSeenOnboarding', defaultValue: false);

      // Fix for browser getting stuck on #/borrower_dashboard
      if (state.matchedLocation == '/borrower_dashboard') {
        return '/';
      }

      // If user is logged in, never let them see auth, splash, or onboarding
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      // If user is logged out
      if (!isLoggedIn) {
        // If they try to access a protected route, send to login
        if (!isAuthRoute) return '/auth/login';

        // If they have already seen onboarding, bypass splash and onboarding
        if (hasSeenOnboarding && (state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding')) {
          return '/auth/login';
        }
      }

      return null;
    },
    routes: [
      // ─── Splash & Onboarding ──────────────
      GoRoute(path: '/splash',      builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding',  builder: (c, s) => const OnboardingScreen()),

      // ─── Auth Routes ──────────────────────
      GoRoute(path: '/auth/login',          builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/auth/signup',         builder: (c, s) => const SignupScreen()),
      GoRoute(path: '/auth/role-selection', builder: (c, s) => const RoleSelectionScreen()),
      GoRoute(path: '/auth/kyc-borrower',   builder: (c, s) => const KycBorrowerScreen()),
      GoRoute(path: '/auth/kyc-lender',     builder: (c, s) => const KycLenderScreen()),

      // ─── Main Shell (Bottom Nav) ──────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/',              builder: (c, s) => const DashboardRouter()),
          GoRoute(path: '/lender',        builder: (c, s) => const LenderDashboard()), // Kept for direct linking if needed
          GoRoute(path: '/search',        builder: (c, s) => const SearchRouter()),
          GoRoute(path: '/chat',          builder: (c, s) => const ChatListScreen()),
          GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
        ],
      ),

      // ─── Borrower ─────────────────────────
      GoRoute(path: '/post-request',      builder: (c, s) => const PostRequestScreen()),
      GoRoute(path: '/saved-lenders',     builder: (c, s) => const SavedLendersScreen()),
      GoRoute(path: '/borrower-search',   builder: (c, s) => const BorrowerSearchScreen()),

      // ─── Lender ───────────────────────────
      GoRoute(path: '/create-offer',      builder: (c, s) => const CreateOfferScreen()),
      GoRoute(
        path: '/lender-profile/:id',
        builder: (c, s) => LenderProfileScreen(lenderId: s.pathParameters['id']!),
      ),

      // ─── Match ────────────────────────────
      GoRoute(path: '/match',             builder: (c, s) => const MatchScreen()),
      GoRoute(
        path: '/request/:id',
        builder: (c, s) => RequestDetailScreen(requestId: s.pathParameters['id']!),
      ),

      // ─── Chat ─────────────────────────────
      GoRoute(
        path: '/chat/:roomId',
        builder: (c, s) => ChatRoomScreen(roomId: s.pathParameters['roomId']!),
      ),

      // ─── Collateral ───────────────────────
      GoRoute(path: '/upload-collateral', builder: (c, s) => const UploadCollateralScreen()),
      GoRoute(
        path: '/collateral/:id',
        builder: (c, s) => CollateralDetailScreen(requestId: s.pathParameters['id']!),
      ),

      // ─── Subscription ─────────────────────
      GoRoute(path: '/plans',             builder: (c, s) => const PlansScreen()),
      GoRoute(
        path: '/unlock-contact/:matchId',
        builder: (c, s) => ContactUnlockScreen(matchId: s.pathParameters['matchId']!),
      ),

      // ─── Admin ────────────────────────────
      GoRoute(path: '/admin',             builder: (c, s) => const AdminDashboardScreen()),
      GoRoute(path: '/profile',           builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/profile/edit',      builder: (c, s) => const EditProfileScreen()),
      GoRoute(path: '/profile/bank',      builder: (c, s) => const BankDetailsScreen()),
      GoRoute(path: '/profile/role',      builder: (c, s) => const ChangeRoleScreen()),
      GoRoute(path: '/profile/kyc',       builder: (c, s) => const KycVerificationScreen()),
      GoRoute(path: '/profile/security',  builder: (c, s) => const SecurityScreen()),
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Text(
          'Page not found',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});

// ─── Dashboard Router ────────────────────────
class DashboardRouter extends ConsumerWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user?.role == UserRole.lender) {
          return const LenderDashboard();
        }
        // Universal dashboard that adapts its UI based on the user's role
        return const BorrowerDashboard();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const BorrowerDashboard(),
    );
  }
}

// ─── Search Router ───────────────────────────
class SearchRouter extends ConsumerWidget {
  const SearchRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user?.role == UserRole.lender) {
          return const BorrowerSearchScreen();
        }
        // Default to finding lenders if role is borrower or both
        return const LenderSearchScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LenderSearchScreen(),
    );
  }
}
