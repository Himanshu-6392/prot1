import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/loan_request_model.dart';
import '../../../models/lender_model.dart';
import '../../../core/services/activity_log_service.dart';

class PostRequestScreen extends StatelessWidget {
  const PostRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('Post a Request', style: AppTextStyles.h3),
          leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            bgColor: Colors.transparent,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Column(
              children: [
                Divider(height: 1, color: AppColors.border),
                TabBar(
                  indicatorColor: AppColors.gold,
                  labelColor: AppColors.gold,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'Need a Loan (Borrower)'),
                    Tab(text: 'Offer a Loan (Lender)'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _BorrowerForm(),
            _LenderForm(),
          ],
        ),
      ),
    );
  }
}

// ─── BORROWER FORM ──────────────────────────────────────────
class _BorrowerForm extends ConsumerStatefulWidget {
  const _BorrowerForm();
  @override
  ConsumerState<_BorrowerForm> createState() => _BorrowerFormState();
}

class _BorrowerFormState extends ConsumerState<_BorrowerForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtr = TextEditingController();
  final _valueCtr = TextEditingController();
  final _interestCtr = TextEditingController();
  final _descCtr = TextEditingController();
  String? _collateral;
  int _tenure = 3;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_collateral == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a collateral type')));
      return;
    }
    setState(() => _loading = true);

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final userModel = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;

      final now = DateTime.now();
      final request = LoanRequestModel(
        id: '',
        borrowerId: user.uid,
        borrowerName: userModel?.name ?? '',
        borrowerCity: userModel?.city ?? '',
        loanAmount:
            double.parse(_amountCtr.text.replaceAll(RegExp(r'[^\d.]'), '')),
        collateralType: _collateral!,
        collateralValue:
            double.parse(_valueCtr.text.replaceAll(RegExp(r'[^\d.]'), '')),
        maxInterestRatePerMonth: double.parse(_interestCtr.text),
        tenureMonths: _tenure,
        description: _descCtr.text.trim(),
        createdAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );

      await ref
          .read(firestoreProvider)
          .collection(AppConstants.colRequests)
          .add(request.toMap());

      // ── Log loan request event ────────────────
      ActivityLogService.log(
        type: ActivityType.loanRequest,
        title: '💰 New Loan Request Posted',
        detail: '${userModel?.name ?? 'Unknown'} • ₹${request.loanAmount.toStringAsFixed(0)} for ${request.tenureMonths}mo',
        meta: {
          'amount': request.loanAmount,
          'tenure': request.tenureMonths,
          'collateral': request.collateralType,
          'borrower': userModel?.name ?? '',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✓ Loan request posted successfully!')));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(label: 'Loan Details'),
            TextFormField(
              controller: _amountCtr,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'Loan Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  hintText: 'e.g. 25000'),
              validator: (v) =>
                  AppValidators.amount(v, min: 1000, max: 10000000),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestCtr,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'Max Willing Interest (% per month)',
                  prefixIcon: Icon(Icons.percent_rounded),
                  hintText: 'e.g. 2.5'),
              validator: AppValidators.interestRate,
            ).animate().fadeIn(delay: 130.ms),
            const SizedBox(height: 16),
            Row(children: [
              Text('Preferred Tenure',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text(AppFormatters.formatTenure(_tenure),
                  style:
                      AppTextStyles.labelLarge.copyWith(color: AppColors.gold)),
            ]),
            Slider(
                value: _tenure.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (v) => setState(() => _tenure = v.round())),
            const SizedBox(height: 24),
            const _SectionTitle(label: 'Collateral'),
            DropdownButtonFormField<String>(
              initialValue: _collateral,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                  labelText: 'Collateral Type',
                  prefixIcon: Icon(Icons.category_rounded)),
              items: AppConstants.collateralTypes
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: AppTextStyles.bodyMedium)))
                  .toList(),
              onChanged: (v) => setState(() => _collateral = v),
              validator: (v) => v == null ? 'Select collateral' : null,
            ).animate().fadeIn(delay: 160.ms),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueCtr,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'Estimated Collateral Value (₹)',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
              validator: (v) => AppValidators.amount(v, min: 1000),
            ).animate().fadeIn(delay: 190.ms),
            const SizedBox(height: 24),
            const _SectionTitle(label: 'Additional Info'),
            TextFormField(
              controller: _descCtr,
              maxLines: 3,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'Why do you need this loan? (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true),
            ).animate().fadeIn(delay: 220.ms),
            const SizedBox(height: 32),
            AppButton(
                    label: 'Post Loan Request',
                    onPressed: _submit,
                    isLoading: _loading,
                    icon: const Icon(Icons.campaign_rounded, size: 18))
                .animate()
                .fadeIn(delay: 250.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── LENDER FORM ──────────────────────────────────────────
class _LenderForm extends ConsumerStatefulWidget {
  const _LenderForm();
  @override
  ConsumerState<_LenderForm> createState() => _LenderFormState();
}

class _LenderFormState extends ConsumerState<_LenderForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _capitalCtr = TextEditingController();
  final _minLoanCtr = TextEditingController();
  final _maxLoanCtr = TextEditingController();
  final _interestCtr = TextEditingController();
  final _descCtr = TextEditingController();
  String? _city;
  int _tenure = 12;
  double _ltv = 70;
  final _selectedCollateral = <String>{};
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollateral.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one accepted collateral')));
      return;
    }
    if (_city == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select your city')));
      return;
    }
    setState(() => _loading = true);

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final offer = LenderModel(
        id: '',
        userId: user.uid,
        businessName: _nameCtr.text.trim(),
        city: _city!,
        description: _descCtr.text.trim(),
        availableCapital:
            double.parse(_capitalCtr.text.replaceAll(RegExp(r'[^\d.]'), '')),
        minLoanAmount:
            double.parse(_minLoanCtr.text.replaceAll(RegExp(r'[^\d.]'), '')),
        maxLoanAmount:
            double.parse(_maxLoanCtr.text.replaceAll(RegExp(r'[^\d.]'), '')),
        interestRatePerMonth: double.parse(_interestCtr.text),
        maxTenureMonths: _tenure,
        acceptedCollateral: _selectedCollateral.toList(),
        ltvRatio: _ltv,
        createdAt: now,
        updatedAt: now,
      );

      await ref
          .read(firestoreProvider)
          .collection(AppConstants.colLenders)
          .add(offer.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Offer listed successfully!')));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(label: 'Business Info'),
            TextFormField(
              controller: _nameCtr,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'Business / Display Name',
                  prefixIcon: Icon(Icons.business_center_rounded)),
              validator: AppValidators.name,
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _city,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_rounded)),
              items: AppConstants.popularCities
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: AppTextStyles.bodyMedium)))
                  .toList(),
              onChanged: (v) => setState(() => _city = v),
              validator: (v) => v == null ? 'Select your city' : null,
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 24),
            const _SectionTitle(label: 'Capital & Loan Range'),
            TextFormField(
              controller: _capitalCtr,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'Total Available Capital (₹)',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
              validator: (v) => AppValidators.amount(v),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextFormField(
                controller: _minLoanCtr,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                    labelText: 'Min Loan (₹)',
                    prefixIcon: Icon(Icons.arrow_downward_rounded)),
                validator: (v) => AppValidators.amount(v),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                controller: _maxLoanCtr,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                    labelText: 'Max Loan (₹)',
                    prefixIcon: Icon(Icons.arrow_upward_rounded)),
                validator: (v) => AppValidators.amount(v),
              )),
            ]).animate().fadeIn(delay: 120.ms),
            const SizedBox(height: 24),
            const _SectionTitle(label: 'Terms'),
            TextFormField(
              controller: _interestCtr,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'Interest Rate (% per month)',
                  prefixIcon: Icon(Icons.percent_rounded)),
              validator: AppValidators.interestRate,
            ).animate().fadeIn(delay: 140.ms),
            const SizedBox(height: 16),
            Row(children: [
              Text('Max Tenure',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text(AppFormatters.formatTenure(_tenure),
                  style:
                      AppTextStyles.labelLarge.copyWith(color: AppColors.gold)),
            ]),
            Slider(
                value: _tenure.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (v) => setState(() => _tenure = v.round())),
            Row(children: [
              Text('Loan-to-Value Ratio',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text('${_ltv.toStringAsFixed(0)}%',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.emerald)),
            ]),
            Slider(
                value: _ltv,
                min: 30,
                max: 90,
                divisions: 12,
                activeColor: AppColors.emerald,
                onChanged: (v) => setState(() => _ltv = v)),
            Text('Max ${_ltv.toStringAsFixed(0)}% of the collateral\'s value',
                style: AppTextStyles.caption),
            const SizedBox(height: 24),
            const _SectionTitle(label: 'Accepted Collateral'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.collateralTypes.map((c) {
                final sel = _selectedCollateral.contains(c);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedCollateral.remove(c);
                    } else {
                      _selectedCollateral.add(c);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.emerald.withOpacity(0.12)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? AppColors.emerald : AppColors.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (sel) ...[
                        Icon(Icons.check_rounded,
                            color: AppColors.emerald, size: 14),
                        const SizedBox(width: 5)
                      ],
                      Text(c,
                          style: AppTextStyles.labelMedium.copyWith(
                              color: sel
                                  ? AppColors.emerald
                                  : AppColors.textSecondary)),
                    ]),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descCtr,
              maxLines: 3,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                  labelText: 'About your service (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true),
            ).animate().fadeIn(delay: 220.ms),
            const SizedBox(height: 32),
            AppButton(
                    label: 'List Offer',
                    onPressed: _submit,
                    isLoading: _loading,
                    icon: const Icon(Icons.publish_rounded, size: 18))
                .animate()
                .fadeIn(delay: 250.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child:
          Text(label, style: AppTextStyles.h3.copyWith(color: AppColors.gold)),
    );
  }
}
