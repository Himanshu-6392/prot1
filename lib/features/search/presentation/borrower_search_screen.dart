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
import '../../../models/match_model.dart';
import '../../match/presentation/match_screen.dart';

class BorrowerSearchScreen extends ConsumerStatefulWidget {
  const BorrowerSearchScreen({super.key});
  @override
  ConsumerState<BorrowerSearchScreen> createState() => _BorrowerSearchScreenState();
}

class _BorrowerSearchScreenState extends ConsumerState<BorrowerSearchScreen> {
  String? _filterCollateral;
  String? _filterCity;
  bool _verifiedOnly = false;
  double? _maxAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Browse Borrowers')),
      body: Column(children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _FilterChip(
              label: _filterCity ?? 'All Cities',
              icon: Icons.location_on_rounded,
              isActive: _filterCity != null,
              onTap: () => _showCityPicker(),
            ),
            SizedBox(width: 8),
            _FilterChip(
              label: _filterCollateral ?? 'Collateral',
              icon: Icons.diamond_rounded,
              isActive: _filterCollateral != null,
              onTap: () => _showCollateralPicker(),
            ),
            SizedBox(width: 8),
            _FilterChip(
              label: 'Verified',
              icon: Icons.verified_rounded,
              isActive: _verifiedOnly,
              onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
            ),
            if (_filterCity != null || _filterCollateral != null || _verifiedOnly) ...[
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { _filterCity = null; _filterCollateral = null; _verifiedOnly = false; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text('Clear', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                ),
              ),
            ],
          ]),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildQuery(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return ListView.builder(itemCount: 5, itemBuilder: (_, __) => RequestCardShimmer());
              }
              var docs = snap.data!.docs;

              // Client-side filtering to avoid composite index errors
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final status = data['status'] ?? LoanRequestStatus.open.name;
                if (status != LoanRequestStatus.open.name) return false;
                if (_filterCity != null && data['borrowerCity'] != _filterCity) return false;
                if (_verifiedOnly && data['isVerified'] != true) return false;
                if (_filterCollateral != null && data['collateralType'] != _filterCollateral) return false;
                return true;
              }).toList();

              if (docs.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No borrower requests found',
                  subtitle: 'Try adjusting your filters',
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final req = LoanRequestModel.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
                  return _BorrowerRequestCard(request: req, lenderId: ref.read(currentUserProvider).valueOrNull?.uid ?? '')
                      .animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.1, end: 0);
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection(AppConstants.colRequests);
        
    return q.orderBy('createdAt', descending: true).limit(50).snapshots();
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Select City',
        items: ['All', ...AppConstants.popularCities],
        selected: _filterCity,
        onSelect: (v) { setState(() => _filterCity = v == 'All' ? null : v); Navigator.pop(context); },
      ),
    );
  }

  void _showCollateralPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Collateral Type',
        items: ['All', ...AppConstants.collateralTypes],
        selected: _filterCollateral,
        onSelect: (v) { setState(() => _filterCollateral = v == 'All' ? null : v); Navigator.pop(context); },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final IconData icon; final bool isActive; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.icon, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold.withOpacity(0.15) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.gold : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: isActive ? AppColors.gold : AppColors.textMuted),
          SizedBox(width: 5),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: isActive ? AppColors.gold : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _BorrowerRequestCard extends StatelessWidget {
  final LoanRequestModel request;
  final String lenderId;
  const _BorrowerRequestCard({required this.request, required this.lenderId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/request/${request.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(
              color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(request.borrowerName.isNotEmpty ? request.borrowerName[0].toUpperCase() : 'B',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)))),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.borrowerName, style: AppTextStyles.labelLarge),
              Row(children: [
                Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 12),
                Text(request.borrowerCity, style: AppTextStyles.caption),
              ]),
            ])),
            if (request.isVerified) VerifiedBadge(small: true),
          ]),
          SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text(AppFormatters.formatINR(request.loanAmount), style: AppTextStyles.amountMedium)),
            TagChip(label: request.collateralType, color: AppColors.info),
          ]),
          SizedBox(height: 8),
          Row(children: [
            TagChip(label: 'Max ${request.maxInterestRatePerMonth}%/mo', color: AppColors.warning),
            SizedBox(width: 8),
            TagChip(label: AppFormatters.formatTenure(request.tenureMonths), color: AppColors.textSecondary),
          ]),
          SizedBox(height: 10),
          Text(request.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 12),
          AppButton(
            label: 'Send Offer',
            onPressed: () => _sendOffer(context, request),
            height: 40,
            icon: Icon(Icons.send_rounded, size: 16),
          ),
        ]),
      ),
    );
  }

  Future<void> _sendOffer(BuildContext context, LoanRequestModel request) async {
    showMakeOfferSheet(context, lenderId, request.toMap(), request.id);
  }
}

class _PickerSheet extends StatelessWidget {
  final String title; final List<String> items; final String? selected;
  final ValueChanged<String> onSelect;
  const _PickerSheet({required this.title, required this.items, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        SizedBox(height: 16),
        Text(title, style: AppTextStyles.h3),
        SizedBox(height: 8),
        Flexible(child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(items[i], style: AppTextStyles.bodyMedium),
            trailing: selected == items[i] ? Icon(Icons.check_rounded, color: AppColors.gold) : null,
            onTap: () => onSelect(items[i]),
          ),
        )),
        SizedBox(height: 16),
      ]),
    );
  }
}
