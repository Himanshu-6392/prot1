import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/firebase_providers.dart';
import '../providers/platform_settings_provider.dart';
import '../../models/user_model.dart';

// ─── Auth Feature ─────────────────────────────
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/kyc_borrower_screen.dart';
import '../../features/auth/presentation/kyc_lender_screen.dart';
import '../../features/auth/presentation/maintenance_screen.dart';
import '../../features/auth/presentation/account_suspended_screen.dart';

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

import '../../features/profile/presentation/kyc_verification_screen.dart';
// ─── Admin ───────────────────────────────────
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_user_management_screen.dart';
import '../../features/admin/presentation/admin_user_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final isLoggingInProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final maintenanceMode = ref.watch(maintenanceModeProvider);
  final userAsync = ref.watch(currentUserProvider);
  final isLoggingIn = ref.watch(isLoggingInProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // ── CRITICAL: Wait until auth state has resolved ───────────────
      // If auth is still loading, do nothing — don't redirect yet.
      // Without this, authState.valueOrNull = null (loading = not logged in)
      // which makes the router wrongly think the user is a guest.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc.startsWith('/auth') || loc == '/splash' || loc == '/onboarding';
      final isMaintenanceRoute = loc == '/maintenance';

      // Fix for browser getting stuck on #/borrower_dashboard
      if (loc == '/borrower_dashboard') return '/';

      // Admin email — exempt from maintenance
      final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
      
      // Determine if they are an admin via email OR via Firestore Role
      final isAdmin = email.contains('admin104') || 
                      (userAsync.valueOrNull?.role == UserRole.admin);

      // ── Maintenance Mode Guard ─────────────────────────────────────
      if (maintenanceMode && !isAdmin) {
        // Wait for user document to load before deciding
        if (isLoggedIn && userAsync.isLoading) return null;

        if (!isLoggingIn) {
          if (!isMaintenanceRoute) return '/maintenance';
        }
      }
      if (!maintenanceMode && isMaintenanceRoute) return '/auth/login';
      // ───────────────────────────────────────────────────────────────

      // Logged-in users should never see auth/splash/onboarding screens
      if (isLoggedIn && isAuthRoute && !isLoggingIn) return '/';

      // Guest on splash: decide between onboarding and login
      if (!isLoggedIn && loc == '/splash') {
        final box = Hive.box('settings');
        final hasSeenOnboarding = box.get('hasSeenOnboarding', defaultValue: false) as bool;
        return hasSeenOnboarding ? '/auth/login' : '/onboarding';
      }

      // Guests should not access protected routes
      if (!isLoggedIn && !isAuthRoute && !isMaintenanceRoute) return '/auth/login';

      return null;
    },
    routes: [
      // ─── Splash & Onboarding ──────────────
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/maintenance', builder: (c, s) => const MaintenanceScreen()),

      // ─── Auth Routes ──────────────────────
      GoRoute(path: '/auth/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(
          path: '/auth/role-selection',
          builder: (c, s) => const RoleSelectionScreen()),
      GoRoute(
          path: '/auth/kyc-borrower',
          builder: (c, s) => const KycBorrowerScreen()),
      GoRoute(
          path: '/auth/kyc-lender', builder: (c, s) => const KycLenderScreen()),

      // ─── Main Shell (Bottom Nav) ──────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const DashboardRouter()),
          GoRoute(
              path: '/lender',
              builder: (c, s) =>
                  const LenderDashboard()), // Kept for direct linking if needed
          GoRoute(path: '/search', builder: (c, s) => const SearchRouter()),
          GoRoute(path: '/match', builder: (c, s) => const MatchScreen()),
          GoRoute(path: '/chat', builder: (c, s) => const ChatListScreen()),
          GoRoute(
              path: '/notifications',
              builder: (c, s) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),

      // ─── Borrower ─────────────────────────
      GoRoute(
          path: '/post-request', builder: (c, s) => const PostRequestScreen()),
      GoRoute(
          path: '/saved-lenders',
          builder: (c, s) => const SavedLendersScreen()),
      GoRoute(
          path: '/borrower-search',
          builder: (c, s) => const BorrowerSearchScreen()),

      // ─── Lender ───────────────────────────
      GoRoute(
          path: '/create-offer', builder: (c, s) => const CreateOfferScreen()),
      GoRoute(
        path: '/lender-profile/:id',
        builder: (c, s) =>
            LenderProfileScreen(lenderId: s.pathParameters['id']!),
      ),

      // ─── Match ────────────────────────────
      GoRoute(
        path: '/request/:id',
        builder: (c, s) =>
            RequestDetailScreen(requestId: s.pathParameters['id']!),
      ),

      // ─── Chat ─────────────────────────────
      GoRoute(
        path: '/chat/:roomId',
        builder: (c, s) => ChatRoomScreen(
          roomId: s.pathParameters['roomId']!,
          peerUser: s.extra as UserModel?,
        ),
      ),

      // ─── Collateral ───────────────────────
      GoRoute(
          path: '/upload-collateral',
          builder: (c, s) => const UploadCollateralScreen()),
      GoRoute(
        path: '/collateral/:id',
        builder: (c, s) =>
            CollateralDetailScreen(requestId: s.pathParameters['id']!),
      ),

      // ─── Subscription ─────────────────────
      GoRoute(path: '/plans', builder: (c, s) => const PlansScreen()),
      GoRoute(
        path: '/unlock-contact/:matchId',
        builder: (c, s) =>
            ContactUnlockScreen(matchId: s.pathParameters['matchId']!),
      ),

      // ─── Admin ────────────────────────────
      GoRoute(path: '/admin', builder: (c, s) => const AdminDashboardScreen()),
      GoRoute(
          path: '/admin/users',
          builder: (c, s) => const AdminUserManagementScreen()),
      GoRoute(
        path: '/admin/users/:id',
        builder: (c, s) =>
            AdminUserDetailScreen(userId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/kyc', builder: (c, s) => const KycVerificationScreen()),
      GoRoute(path: '/suspended', builder: (c, s) => const AccountSuspendedScreen()),
    ],
    errorBuilder: (context, state) => const Scaffold(
      backgroundColor: Color(0xFF0A0E1A),
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
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final authEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? user.email.toLowerCase();

        // Auto-elevate the account to Admin if it matches the criteria
        if (user.role != UserRole.admin && 
            authEmail.contains('admin104')) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'role': 'admin',
            'isPremium': true,
          });
        }

        // ── Real-time Block Guard ─────────────────────────────────
        // If a non-admin user's account is blocked (even while active),
        // immediately redirect them to the suspended screen.
        final isAdmin = user.role == UserRole.admin || authEmail.contains('admin104');
        if (user.isBlocked == true && !isAdmin) {
          return const AccountSuspendedScreen();
        }
        // ─────────────────────────────────────────────────────────

        // Force the route immediately so they don't have to wait for the stream to update
        if (user.role == UserRole.admin || authEmail.contains('admin104')) {
          return const AdminDashboardScreen();
        }
        if (user.role == UserRole.lender) {
          return const LenderDashboard();
        }
        return const BorrowerDashboard();
      },

      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) {
        debugPrint('Router Stream Error: $err');
        final authEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
        if (authEmail.contains('admin104')) {
          return const AdminDashboardScreen();
        }
        return const BorrowerDashboard();
      },
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
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? user.email.toLowerCase();

        if (user.role == UserRole.admin || authEmail.contains('admin104')) {
          return const AdminUserManagementScreen();
        }
        if (user.role == UserRole.lender) {
          return const BorrowerSearchScreen();
        }
        return const LenderSearchScreen();
      },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) {
          debugPrint('SearchRouter Stream Error: $err');
          final authEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
          if (authEmail.contains('admin104')) {
            return const AdminUserManagementScreen();
          }
          return const LenderSearchScreen();
        },
    );
  }
}
