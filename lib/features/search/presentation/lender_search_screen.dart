import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/lender_model.dart';

class LenderSearchScreen extends ConsumerStatefulWidget {
  const LenderSearchScreen({super.key});
  @override
  ConsumerState<LenderSearchScreen> createState() => _LenderSearchScreenState();
}

class _LenderSearchScreenState extends ConsumerState<LenderSearchScreen> {
  final _searchCtr = TextEditingController();
  String? _filterCity;
  String? _filterCollateral;
  double? _maxInterest;
  bool _verifiedOnly = false;
  bool _showFilters = false;

  Query<Map<String, dynamic>> get _query {
    return FirebaseFirestore.instance.collection(AppConstants.colLenders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Find Lenders'),
        actions: [
          IconButton(
            icon: Icon(
                _showFilters
                    ? Icons.filter_list_off_rounded
                    : Icons.filter_list_rounded,
                color: _showFilters ? AppColors.gold : AppColors.textPrimary),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtr,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search by name or city...',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: _searchCtr.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtr.clear();
                          setState(() {});
                        })
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filter Panel
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _showFilters
                ? _FilterPanel(
                    selectedCity: _filterCity,
                    selectedCollateral: _filterCollateral,
                    verifiedOnly: _verifiedOnly,
                    maxInterest: _maxInterest,
                    onCityChanged: (v) => setState(() => _filterCity = v),
                    onCollateralChanged: (v) =>
                        setState(() => _filterCollateral = v),
                    onVerifiedChanged: (v) => setState(() => _verifiedOnly = v),
                    onInterestChanged: (v) => setState(() => _maxInterest = v),
                    onClear: () => setState(() {
                      _filterCity = null;
                      _filterCollateral = null;
                      _verifiedOnly = false;
                      _maxInterest = null;
                    }),
                  )
                : const SizedBox.shrink(),
          ),

          // Results
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _query.limit(30).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) => LenderCardShimmer(),
                  );
                }

                var docs = snap.data!.docs;

                // Client-side generic filters to avoid Firebase Composite Index requirement
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  if (data['isActive'] != true) return false;
                  if (_filterCity != null && data['city'] != _filterCity)
                    return false;
                  if (_verifiedOnly && data['isVerified'] != true) return false;
                  return true;
                }).toList();

                // Sort
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final featA = dataA['isFeatured'] == true ? 1 : 0;
                  final featB = dataB['isFeatured'] == true ? 1 : 0;
                  if (featA != featB) return featB.compareTo(featA);
                  final ratA = ((dataA['rating'] ?? 0.0) as num).toDouble();
                  final ratB = ((dataB['rating'] ?? 0.0) as num).toDouble();
                  return ratB.compareTo(ratA);
                });

                // Client-side name filter
                if (_searchCtr.text.isNotEmpty) {
                  final q = _searchCtr.text.toLowerCase();
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['businessName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (data['city'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q);
                  }).toList();
                }

                // Collateral filter
                if (_filterCollateral != null) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final col =
                        List<String>.from(data['acceptedCollateral'] ?? []);
                    return col.contains(_filterCollateral);
                  }).toList();
                }

                // Interest filter
                if (_maxInterest != null) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['interestRatePerMonth'] ?? 999) <=
                        _maxInterest!;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No lenders found',
                    subtitle: 'Try changing your filters or search query',
                    action: AppButton(
                      label: 'Clear Filters',
                      width: 180,
                      isOutlined: true,
                      onPressed: () => setState(() {
                        _filterCity = null;
                        _filterCollateral = null;
                        _verifiedOnly = false;
                        _maxInterest = null;
                        _searchCtr.clear();
                      }),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final lender = LenderModel.fromMap(
                        docs[i].data() as Map<String, dynamic>, docs[i].id);
                    return _LenderCard(lender: lender)
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn()
                        .slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
class _FilterPanel extends StatelessWidget {
  final String? selectedCity, selectedCollateral;
  final bool verifiedOnly;
  final double? maxInterest;
  final ValueChanged<String?> onCityChanged, onCollateralChanged;
  final ValueChanged<bool> onVerifiedChanged;
  final ValueChanged<double?> onInterestChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.selectedCity,
    required this.selectedCollateral,
    required this.verifiedOnly,
    required this.maxInterest,
    required this.onCityChanged,
    required this.onCollateralChanged,
    required this.onVerifiedChanged,
    required this.onInterestChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Filters',
                style: AppTextStyles.h4.copyWith(color: AppColors.gold)),
            Spacer(),
            TextButton(onPressed: onClear, child: Text('Clear all')),
          ]),
          SizedBox(height: 8),

          // City
          DropdownButtonFormField<String>(
            value: selectedCity,
            dropdownColor: AppColors.surface,
            decoration: InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_rounded)),
            items: [
              DropdownMenuItem(value: null, child: Text('All cities')),
              ...AppConstants.popularCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            ],
            onChanged: onCityChanged,
          ),

          SizedBox(height: 12),

          // Collateral
          Text('Accepted Collateral',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.collateralTypes.map((c) {
              final sel = selectedCollateral == c;
              return GestureDetector(
                onTap: () => onCollateralChanged(sel ? null : c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.gold.withValues(alpha: 0.15)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: sel ? AppColors.gold : AppColors.border),
                  ),
                  child: Text(c,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: sel ? AppColors.gold : AppColors.textSecondary,
                      )),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 12),

          Row(children: [
            Text('Verified Lenders Only',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
            Spacer(),
            Switch(value: verifiedOnly, onChanged: onVerifiedChanged),
          ]),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
class _LenderCard extends StatelessWidget {
  final LenderModel lender;
  const _LenderCard({required this.lender});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/lender-profile/${lender.id}'),
      child: NeumorphicContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: lender.isFeatured
                        ? AppColors.emeraldGradient // Make featured lenders green
                        : AppColors.goldGradient, // Make standard lenders dark
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(
                    lender.businessName.isNotEmpty
                        ? lender.businessName[0].toUpperCase()
                        : 'L',
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  )),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(lender.businessName,
                              style: AppTextStyles.h4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (lender.isFeatured) ...[
                          SizedBox(width: 6),
                          TagChip(label: 'Featured', color: AppColors.gold),
                        ],
                      ]),
                      SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.location_on_rounded,
                            color: AppColors.textMuted, size: 13),
                        SizedBox(width: 3),
                        Text(lender.city, style: AppTextStyles.caption),
                        SizedBox(width: 10),
                        if (lender.isVerified) VerifiedBadge(small: true),
                      ]),
                    ],
                  ),
                ),
                StarRating(rating: lender.rating, count: lender.ratingCount),
              ],
            ),

            SizedBox(height: 16),
            Divider(color: AppColors.border, height: 1),
            SizedBox(height: 14),

            // Key stats
            Row(
              children: [
                _StatItem('Capital',
                    AppFormatters.formatINRCompact(lender.availableCapital)),
                _Divider(),
                _StatItem('Interest', '${lender.interestRatePerMonth}%/mo'),
                _Divider(),
                _StatItem('Min',
                    AppFormatters.formatINRCompact(lender.minLoanAmount)),
                _Divider(),
                _StatItem('Max',
                    AppFormatters.formatINRCompact(lender.maxLoanAmount)),
              ],
            ),

            SizedBox(height: 14),

            // Collateral chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lender.acceptedCollateral
                  .take(5)
                  .map((c) => TagChip(label: c, color: AppColors.info))
                  .toList(),
            ),

            SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                    child: Text(
                  '${lender.completedDeals} deals • Up to ${lender.maxTenureMonths} months',
                  style: AppTextStyles.caption,
                )),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Connect',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textPrimary)),
          Text(label, style: AppTextStyles.caption),
        ]),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        width: 1,
        color: AppColors.border,
      );
}
