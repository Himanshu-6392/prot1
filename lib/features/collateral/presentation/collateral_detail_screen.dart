import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class CollateralDetailScreen extends StatelessWidget {
  final String requestId;
  const CollateralDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Collateral Details', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Center(
          child: Text('Collateral for request: $requestId',
              style: AppTextStyles.bodyLarge)),
    );
  }
}
