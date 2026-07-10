import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/lender_model.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key});
  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
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

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

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
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Create Lending Offer'),
        leading: AppIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.pop(),
            bgColor: Colors.transparent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Info
              _SectionLabel('Business Info'),
              TextFormField(
                controller: _nameCtr,
                textCapitalization: TextCapitalization.words,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                    labelText: 'Business / Display Name',
                    prefixIcon: Icon(Icons.business_center_rounded)),
                validator: AppValidators.name,
              ).animate().fadeIn(delay: 50.ms),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _city,
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
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

              SizedBox(height: 24),
              _SectionLabel('Capital & Loan Range'),

              TextFormField(
                controller: _capitalCtr,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                    labelText: 'Total Available Capital (₹)',
                    prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
                validator: (v) => AppValidators.amount(v),
              ).animate().fadeIn(delay: 100.ms),
              SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: TextFormField(
                  controller: _minLoanCtr,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                      labelText: 'Min Loan (₹)',
                      prefixIcon: Icon(Icons.arrow_downward_rounded)),
                  validator: (v) => AppValidators.amount(v),
                )),
                SizedBox(width: 12),
                Expanded(
                    child: TextFormField(
                  controller: _maxLoanCtr,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                      labelText: 'Max Loan (₹)',
                      prefixIcon: Icon(Icons.arrow_upward_rounded)),
                  validator: (v) => AppValidators.amount(v),
                )),
              ]).animate().fadeIn(delay: 120.ms),

              SizedBox(height: 24),
              _SectionLabel('Terms'),

              TextFormField(
                controller: _interestCtr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Interest Rate (% per month)',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
                validator: AppValidators.interestRate,
              ).animate().fadeIn(delay: 140.ms),
              SizedBox(height: 16),

              Row(children: [
                Text('Max Tenure',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textSecondary)),
                Spacer(),
                Text(AppFormatters.formatTenure(_tenure),
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.gold)),
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
                Spacer(),
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

              SizedBox(height: 24),
              _SectionLabel('Accepted Collateral'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.collateralTypes.map((c) {
                  final sel = _selectedCollateral.contains(c);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel)
                        _selectedCollateral.remove(c);
                      else
                        _selectedCollateral.add(c);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
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
                          SizedBox(width: 5)
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

              SizedBox(height: 20),
              TextFormField(
                controller: _descCtr,
                maxLines: 3,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'About your service (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ).animate().fadeIn(delay: 220.ms),

              SizedBox(height: 32),
              AppButton(
                      label: 'List Offer',
                      onPressed: _submit,
                      isLoading: _loading,
                      icon: Icon(Icons.publish_rounded, size: 18))
                  .animate()
                  .fadeIn(delay: 250.ms),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child:
          Text(text, style: AppTextStyles.h3.copyWith(color: AppColors.gold)),
    );
  }
}
