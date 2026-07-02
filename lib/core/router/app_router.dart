import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/firebase_providers.dart';

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
import '../../features/profile/presentation/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding';

      // Fix for browser getting stuck on #/borrower_dashboard
      if (state.matchedLocation == '/borrower_dashboard') {
        return '/';
      }

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && (state.matchedLocation == '/auth/login' || state.matchedLocation == '/auth/signup')) return '/';
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
          GoRoute(path: '/',              builder: (c, s) => const BorrowerDashboard()),
          GoRoute(path: '/lender',        builder: (c, s) => const LenderDashboard()),
          GoRoute(path: '/search',        builder: (c, s) => const LenderSearchScreen()),
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
