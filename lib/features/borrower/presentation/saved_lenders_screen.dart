import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';

class SavedLendersScreen extends ConsumerWidget {
  const SavedLendersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Saved Lenders', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No saved lenders yet',
        subtitle: 'Bookmark lenders from search to find them here.',
        action: AppButton(
          label: 'Browse Lenders',
          width: 180,
          onPressed: () => context.go('/search'),
          icon: Icon(Icons.search_rounded, size: 18),
        ),
      ),
    );
  }
}
