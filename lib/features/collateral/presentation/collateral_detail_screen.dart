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
      appBar: AppBar(title: Text('Collateral Details')),
      body: Center(child: Text('Collateral for request: $requestId', style: AppTextStyles.bodyLarge)),
    );
  }
}
