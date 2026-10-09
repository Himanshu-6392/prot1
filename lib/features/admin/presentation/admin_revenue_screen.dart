import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';

class AdminRevenueScreen extends ConsumerStatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  ConsumerState<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends ConsumerState<AdminRevenueScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Revenue Dashboard', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Revenue Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Revenue (MTD)', style: AppTextStyles.labelLarge.copyWith(color: Colors.white.withOpacity(0.8))),
                        const SizedBox(height: 8),
                        Text('₹1,24,500', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Revenue Chart
            Text('Revenue Growth', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.only(right: 16, top: 24, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final style = TextStyle(color: AppColors.textMuted, fontSize: 10);
                          Widget text;
                          switch (value.toInt()) {
                            case 0: text = Text('Jan', style: style); break;
                            case 2: text = Text('Mar', style: style); break;
                            case 4: text = Text('May', style: style); break;
                            case 6: text = Text('Jul', style: style); break;
                            default: text = Text('', style: style); break;
                          }
                          return SideTitleWidget(axisSide: meta.axisSide, child: text);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}k', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 6,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1),
                        FlSpot(1, 1.5),
                        FlSpot(2, 1.4),
                        FlSpot(3, 3.4),
                        FlSpot(4, 2),
                        FlSpot(5, 2.2),
                        FlSpot(6, 4.8),
                      ],
                      isCurved: true,
                      color: AppColors.gold,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.gold.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Subscriptions
            Text('Recent Premium Subscriptions', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subscriptions')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No subscriptions yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final amount = data['amount'] as num? ?? 0;
                    final userId = data['userId'] as String? ?? 'Unknown';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                      ),
                      title: Text('User: $userId', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                      subtitle: Text('Premium Plan', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                      trailing: Text(AppFormatters.formatINR(amount), style: AppTextStyles.labelLarge.copyWith(color: AppColors.emerald)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
