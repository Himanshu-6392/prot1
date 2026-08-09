import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class RateCalculatorScreen extends StatefulWidget {
  const RateCalculatorScreen({super.key});

  @override
  State<RateCalculatorScreen> createState() => _RateCalculatorScreenState();
}

class _RateCalculatorScreenState extends State<RateCalculatorScreen> {
  double _amount = 100000;
  double _rate = 12.0;
  int _months = 12;

  double get _emi {
    if (_amount == 0 || _rate == 0 || _months == 0) return 0;
    double r = (_rate / 12) / 100;
    return (_amount * r * pow(1 + r, _months)) / (pow(1 + r, _months) - 1);
  }

  double get _totalPayment => _emi * _months;
  double get _totalInterest => _totalPayment - _amount;
  
  double get _principalRatio => _amount / (_totalPayment == 0 ? 1 : _totalPayment);
  double get _interestRatio => _totalInterest / (_totalPayment == 0 ? 1 : _totalPayment);

  String formatRupee(double amount) {
    String numStr = amount.toStringAsFixed(0);
    if (numStr.length <= 3) return '₹$numStr';
    String lastThree = numStr.substring(numStr.length - 3);
    String otherNumbers = numStr.substring(0, numStr.length - 3);
    if (otherNumbers != '') lastThree = ',$lastThree';
    String res = otherNumbers.replaceAllMapped(RegExp(r'.{1,2}(?=(.{2})+(?!.))'), (Match m) => '${m[0]},') + lastThree;
    return '₹$res';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('EMI Calculator', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Results Card (Dark theme inside)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2433), Color(0xFF121620)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('Estimated Monthly EMI', 
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    formatRupee(_emi), 
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.emerald, 
                      fontSize: 42,
                      shadows: [Shadow(color: AppColors.emerald.withValues(alpha: 0.5), blurRadius: 20)],
                    )
                  ).animate(target: _emi == 0 ? 0 : 1).scaleXY(end: 1.05, duration: 200.ms).then().scaleXY(end: 1.0, duration: 200.ms),
                  
                  const SizedBox(height: 32),
                  
                  // Progress Bar Breakdown
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (_principalRatio * 100).toInt(),
                            child: Container(color: AppColors.emerald),
                          ),
                          Expanded(
                            flex: (_interestRatio * 100).toInt(),
                            child: Container(color: const Color(0xFFF59E0B)), // Amber
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Breakdown Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBreakdownStat('Principal Amount', formatRupee(_amount), AppColors.emerald, (_principalRatio * 100).toStringAsFixed(0)),
                      _buildBreakdownStat('Total Interest', formatRupee(_totalInterest), const Color(0xFFF59E0B), (_interestRatio * 100).toStringAsFixed(0)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
            
            const SizedBox(height: 32),
            
            // Interactive Inputs
            _buildInputCard(
              title: 'Loan Amount',
              valueText: formatRupee(_amount),
              slider: Slider(
                value: _amount,
                min: 10000,
                max: 1000000,
                divisions: 99,
                onChanged: (val) => setState(() => _amount = val),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            _buildInputCard(
              title: 'Annual Interest Rate',
              valueText: '${_rate.toStringAsFixed(1)}%',
              slider: Slider(
                value: _rate,
                min: 1.0,
                max: 30.0,
                divisions: 290,
                onChanged: (val) => setState(() => _rate = val),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            _buildInputCard(
              title: 'Loan Duration',
              valueText: '$_months months',
              slider: Slider(
                value: _months.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (val) => setState(() => _months = val.toInt()),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownStat(String label, String amount, Color color, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 6),
        Text(amount, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        Text('$percent%', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInputCard({required String title, required String valueText, required Widget slider}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Text(valueText, style: AppTextStyles.h3.copyWith(color: AppColors.emerald)),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.emerald,
              inactiveTrackColor: AppColors.emerald.withValues(alpha: 0.15),
              thumbColor: Colors.white,
              trackHeight: 8,
              overlayColor: AppColors.emerald.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 6),
            ),
            child: slider,
          ),
        ],
      ),
    );
  }
}
