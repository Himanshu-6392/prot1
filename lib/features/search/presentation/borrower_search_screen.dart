import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/loan_request_model.dart';
import '../../match/presentation/match_screen.dart';

class BorrowerSearchScreen extends ConsumerStatefulWidget {
  const BorrowerSearchScreen({super.key});
  @override
  ConsumerState<BorrowerSearchScreen> createState() =>
      _BorrowerSearchScreenState();
}

class _BorrowerSearchScreenState extends ConsumerState<BorrowerSearchScreen> {
  final _searchCtr = TextEditingController();
  String? _filterCity;
  String? _filterCollateral;
  bool _verifiedOnly = false;

  Query<Map<String, dynamic>> get _query {
    return FirebaseFirestore.instance
        .collection(AppConstants.colRequests)
        .orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.05),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'Borrowers',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.emerald,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: _searchCtr,
                            style: AppTextStyles.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Search borrowers, cities...',
                              hintStyle: AppTextStyles.bodyLarge
                                  .copyWith(color: AppColors.textMuted),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.search_rounded,
                                    color: AppColors.emerald, size: 24),
                              ),
                              suffixIcon: _searchCtr.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear_rounded,
                                          color: AppColors.textSecondary,
                                          size: 20),
                                      onPressed: () {
                                        _searchCtr.clear();
                                        setState(() {});
                                      })
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                ),

                // Modern Quick Filters
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 60,
                    child: ListView(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      children: [
                        // City Filter Dropdown Chip
                        _buildFilterDropdown(
                          value: _filterCity,
                          hint: 'All Cities',
                          icon: Icons.location_city_rounded,
                          items: AppConstants.popularCities,
                          onChanged: (v) => setState(() => _filterCity = v),
                        ),
                        const SizedBox(width: 10),
                        // Verified Toggle Chip
                        GestureDetector(
                          onTap: () =>
                              setState(() => _verifiedOnly = !_verifiedOnly),
                          child: _buildFilterChip(
                            label: 'Verified Only',
                            icon: Icons.verified_rounded,
                            isActive: _verifiedOnly,
                            activeColor: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Collateral Filter Dropdown Chip
                        _buildFilterDropdown(
                          value: _filterCollateral,
                          hint: 'Any Collateral',
                          icon: Icons.inventory_2_rounded,
                          items: AppConstants.collateralTypes,
                          onChanged: (v) =>
                              setState(() => _filterCollateral = v),
                        ),
                      ]
                          .animate(interval: 50.ms)
                          .fadeIn(delay: 200.ms)
                          .slideX(begin: 0.1, end: 0),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // StreamBuilder Results
                StreamBuilder<QuerySnapshot>(
                  stream: _query.limit(40).snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: RequestCardShimmer(),
                          ),
                          childCount: 5,
                        ),
                      );
                    }

                    var docs = snap.data!.docs;

                    // Client-side filtering
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      if (data['borrowerName'] == 'Test User') {
                        return false; // HIDE DEMO REQUESTS
                      }
                        
                      final currentUser = ref.read(currentUserProvider).valueOrNull;
                      if (currentUser != null && data['borrowerId'] == currentUser.uid) {
                        return false; // HIDE OWN REQUESTS
                      }
                      
                      final status =
                          data['status'] ?? LoanRequestStatus.open.name;
                      if (status != LoanRequestStatus.open.name) return false;
                      if (_filterCity != null &&
                          data['borrowerCity'] != _filterCity) {
                        return false;
                      }
                      if (_verifiedOnly && data['isVerified'] != true) {
                        return false;
                      }
                      if (_filterCollateral != null &&
                          data['collateralType'] != _filterCollateral) {
                        return false;
                      }
                      if (_searchCtr.text.isNotEmpty) {
                        final q = _searchCtr.text.toLowerCase();
                        final name = (data['borrowerName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final city = (data['borrowerCity'] ?? '')
                            .toString()
                            .toLowerCase();
                        if (!name.contains(q) && !city.contains(q)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    if (docs.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 120),
                          child: Center(
                            child: EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No borrower requests found',
                              subtitle:
                                  'Try adjusting your filters or search term.',
                              action: AppButton(
                                label: 'Clear Filters',
                                width: 160,
                                onPressed: () => setState(() {
                                  _filterCity = null;
                                  _filterCollateral = null;
                                  _verifiedOnly = false;
                                  _searchCtr.clear();
                                }),
                              ),
                            ).animate().fadeIn(),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final req = LoanRequestModel.fromMap(
                                docs[i].data() as Map<String, dynamic>,
                                docs[i].id);
                            return _AestheticBorrowerRequestCard(
                              request: req,
                              lenderId: ref
                                      .read(currentUserProvider)
                                      .valueOrNull
                                      ?.uid ??
                                  '',
                            )
                                .animate(delay: Duration(milliseconds: i * 50))
                                .fadeIn()
                                .slideY(begin: 0.1, end: 0);
                          },
                          childCount: docs.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    Color activeColor = const Color(0xFF18181B),
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color:
            isActive ? activeColor : AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isActive ? activeColor : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive ? Colors.white : AppColors.textPrimary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isActive = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.emerald
            : AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.emerald
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: PopupMenuButton<String?>(
        initialValue: value,
        onSelected: onChanged,
        padding: EdgeInsets.zero,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.surface,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              isActive ? value : hint,
              style: AppTextStyles.labelMedium.copyWith(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isActive ? Colors.white : AppColors.textSecondary,
                size: 20),
          ],
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
              value: null,
              child: Text('Any',
                  style: TextStyle(color: AppColors.textSecondary))),
          ...items.map((e) => PopupMenuItem(
              value: e, child: Text(e, style: AppTextStyles.labelMedium))),
        ],
      ),
    );
  }
}

class _AestheticBorrowerRequestCard extends StatelessWidget {
  final LoanRequestModel request;
  final String lenderId;
  const _AestheticBorrowerRequestCard(
      {required this.request, required this.lenderId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/request/${request.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          children: [
            // The Premium Card Body
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar with Ring
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.emeraldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border:
                                Border.all(color: AppColors.surface, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              request.borrowerName.isNotEmpty
                                  ? request.borrowerName[0].toUpperCase()
                                  : 'B',
                              style: AppTextStyles.h2.copyWith(
                                foreground: Paint()
                                  ..shader = AppColors.emeraldGradient
                                      .createShader(const Rect.fromLTWH(
                                          0.0, 0.0, 50.0, 50.0)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name and Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    request.borrowerName,
                                    style: AppTextStyles.h3.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (request.isVerified) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.verified_rounded,
                                      color: AppColors.info, size: 20),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    color: AppColors.textMuted, size: 14),
                                const SizedBox(width: 4),
                                Text(request.borrowerCity,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats Grid with Modern Aesthetic
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn(
                            'Req. Amount',
                            AppFormatters.formatINRCompact(request.loanAmount),
                            Icons.account_balance_wallet_rounded,
                            AppColors.emerald),
                        _buildStatColumn(
                            'Max Int.',
                            '${request.maxInterestRatePerMonth}%',
                            Icons.percent_rounded,
                            AppColors.warning),
                        _buildStatColumn('Tenure', '${request.tenureMonths}mo',
                            Icons.calendar_month_rounded, AppColors.info),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    request.description,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Footer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Collateral Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          request.collateralType,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Connect Button
                      GestureDetector(
                        onTap: () => showMakeOfferSheet(
                            context, lenderId, request.toMap(), request.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.emeraldGradient,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Send Offer',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
