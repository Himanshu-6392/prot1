import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class MarketInsightsCard extends StatefulWidget {
  const MarketInsightsCard({super.key});
  @override
  State<MarketInsightsCard> createState() => _MarketInsightsCardState();
}

class _MarketInsightsCardState extends State<MarketInsightsCard> {
  final List<Map<String, dynamic>> _insights = [
    {
      'type': 'Insight',
      'text': 'Borrowers who add a profile picture get funded 40% faster.',
      'icon': Icons.lightbulb_outline_rounded,
      'color': AppColors.warning,
    },
    {
      'type': 'Smart Tip',
      'text': 'Paying EMIs on time boosts your Trust Score by 10 points per month.',
      'icon': Icons.verified_rounded,
      'color': AppColors.info,
    }
  ];
  
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchRealData();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _insights.length;
        });
      }
    });
  }

  Future<void> _fetchRealData() async {
    try {
      final response = await http.get(Uri.parse('https://api.coindesk.com/v1/bpi/currentprice.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = data['bpi']['USD']['rate_float'] as double;
        final formattedPrice = '\$${price.toStringAsFixed(0)}';
        
        if (mounted) {
          setState(() {
            _insights.insert(0, {
              'type': 'Market Trend',
              'text': 'Global Crypto Benchmark: Bitcoin is currently trading at $formattedPrice.',
              'icon': Icons.trending_up_rounded,
              'color': AppColors.emerald,
            });
          });
        }
      }
    } catch (e) {
      // Fallback
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _insights[_currentIndex];
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: current['color'].withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: current['color'].withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<int>(_currentIndex),
            color: Colors.white,
            child: Row(
              children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: current['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(current['icon'], color: current['color'], size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      current['type'],
                      style: AppTextStyles.caption.copyWith(
                        color: current['color'],
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current['text'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 350.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
