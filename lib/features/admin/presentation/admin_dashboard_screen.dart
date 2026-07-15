import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/admin_stats_provider.dart';
import '../../../main.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ─── Subtle Theme Background (Matching Search Screen) ───
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.05),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          // ─── Main Content ───
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 80,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                    title: Text('Admin Command Center',
                        style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary, fontSize: 20)),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.settings, color: AppColors.textSecondary),
                      onPressed: () => _showSettings(context, ref),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),

                // Stats Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ref.watch(adminStatsProvider).when(
                          data: (stats) => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _TopStat(label: 'USERS', value: stats.totalUsers.toString(), color: AppColors.textSecondary),
                                _TopStat(label: 'LENDERS', value: stats.activeLenders.toString(), color: AppColors.emerald),
                                _TopStat(label: 'REQUESTS', value: stats.openRequests.toString(), color: Colors.blue),
                                _TopStat(label: 'PENDING KYC', value: stats.kycPending.toString(), color: Colors.redAccent),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms),
                          loading: () => const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                          ),
                          error: (e, _) => const SizedBox(
                            height: 100,
                            child: Center(child: Text('Error loading stats')),
                          ),
                        ),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.palette_outlined, color: Colors.amber),
                ),
                title: Text('Toggle Theme', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                trailing: Icon(Icons.chevron_right, color: AppColors.textPrimary.withOpacity(0.3)),
                onTap: () {
                  final current = ref.read(themeModeProvider);
                  ref.read(themeModeProvider.notifier).state = 
                    current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                ),
                title: Text('Sign Out', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                trailing: Icon(Icons.chevron_right, color: AppColors.textPrimary.withOpacity(0.3)),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TopStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 28)),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textPrimary.withOpacity(0.4), letterSpacing: 1, fontSize: 10)),
      ],
    );
  }
}


