import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/constants.dart';

// ─────────────────────────────────────────────
// Platform Health Chart
// - Fetches ALL users and requests (no Firestore index needed)
// - Buckets by exact calendar date client-side (100% accurate)
// - Polls Firestore every 5 seconds for fresh data
// - Togglable: New Signups / Loan Requests
// ─────────────────────────────────────────────

class AdminPlatformHealthChart extends StatefulWidget {
  const AdminPlatformHealthChart({super.key});

  @override
  State<AdminPlatformHealthChart> createState() =>
      _AdminPlatformHealthChartState();
}

class _AdminPlatformHealthChartState extends State<AdminPlatformHealthChart> {
  int _metric = 0; // 0 = Signups, 1 = Loan Requests
  bool _loading = true;
  String? _error;

  // The O(1) Data Structures
  final Map<String, int> _signupsMap = {};
  final Map<String, int> _requestsMap = {};

  List<int> _signups = List.filled(7, 0);
  List<int> _requests = List.filled(7, 0);
  List<DateTime> _bucketDates = [];

  StreamSubscription? _usersSub;
  StreamSubscription? _requestsSub;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _computeBuckets();
    _listenToData();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _requestsSub?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      _computeBuckets();
      _rebuildChartData();
      _scheduleMidnightRefresh();
    });
  }

  void _computeBuckets() {
    final now = DateTime.now();
    _bucketDates = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day); // strip time component
    });
  }

  String? _getDateString(dynamic rawTs) {
    if (rawTs == null) return null;
    DateTime? dt;
    if (rawTs is Timestamp) {
      dt = rawTs.toDate();
    } else if (rawTs is String) {
      dt = DateTime.tryParse(rawTs);
    }
    if (dt == null) return null;
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  void _listenToData() {
    _usersSub = FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .snapshots()
        .listen((snap) {
      bool changed = false;
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final dateStr = _getDateString(data['createdAt']);
        if (dateStr == null) continue;

        if (change.type == DocumentChangeType.added) {
          _signupsMap[dateStr] = (_signupsMap[dateStr] ?? 0) + 1;
          changed = true;
        } else if (change.type == DocumentChangeType.removed) {
          _signupsMap[dateStr] = (_signupsMap[dateStr] ?? 0) - 1;
          if (_signupsMap[dateStr]! < 0) _signupsMap[dateStr] = 0;
          changed = true;
        }
      }
      if (changed) {
        _rebuildChartData();
      }
    }, onError: (e) {
      if (mounted) setState(() => _error = e.toString());
    });

    _requestsSub = FirebaseFirestore.instance
        .collection(AppConstants.colRequests)
        .snapshots()
        .listen((snap) {
      bool changed = false;
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final dateStr = _getDateString(data['createdAt']);
        if (dateStr == null) continue;

        if (change.type == DocumentChangeType.added) {
          _requestsMap[dateStr] = (_requestsMap[dateStr] ?? 0) + 1;
          changed = true;
        } else if (change.type == DocumentChangeType.removed) {
          _requestsMap[dateStr] = (_requestsMap[dateStr] ?? 0) - 1;
          if (_requestsMap[dateStr]! < 0) _requestsMap[dateStr] = 0;
          changed = true;
        }
      }
      if (changed) {
        _rebuildChartData();
      }
    }, onError: (e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  void _rebuildChartData() {
    if (!mounted) return;
    final newSignups = List.filled(7, 0);
    final newRequests = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final d = _bucketDates[i];
      final dateStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      newSignups[i] = _signupsMap[dateStr] ?? 0;
      newRequests[i] = _requestsMap[dateStr] ?? 0;
    }

    setState(() {
      _signups = newSignups;
      _requests = newRequests;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final counts = _metric == 0 ? _signups : _requests;
    final total = counts.fold(0, (a, b) => a + b);
    final maxVal = counts.fold(0, (a, b) => a > b ? a : b);
    final chartMax = maxVal < 4 ? 4.0 : (maxVal + 1).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _metric == 0 ? 'New Signups' : 'Loan Requests',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _loading
                                ? 'Refreshing...'
                                : _error != null
                                    ? 'Error'
                                    : '$total this week',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted),
                          ),
                          if (!_loading) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _error != null
                                    ? AppColors.error
                                    : AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _error != null ? 'Error' : 'Live',
                              style: AppTextStyles.caption.copyWith(
                                color: _error != null
                                    ? AppColors.error
                                    : AppColors.emerald,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Metric toggle ──
                Container(
                  height: 28,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Pill(
                          label: 'Users',
                          active: _metric == 0,
                          onTap: () => setState(() => _metric = 0)),
                      _Pill(
                          label: 'Loans',
                          active: _metric == 1,
                          onTap: () => setState(() => _metric = 1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Chart body ──
            if (_loading)
              const SizedBox(
                height: 110,
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null)
              SizedBox(
                height: 110,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 24),
                      const SizedBox(height: 6),
                      Text('Failed to load chart data',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _error = null;
                            _loading = true;
                          });
                          _listenToData();
                        },
                        child: Text('Retry',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.info)),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: BarChart(
                  swapAnimationDuration: const Duration(milliseconds: 300),
                  BarChartData(
                    maxY: chartMax,
                    minY: 0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: chartMax / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [3, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (val, meta) {
                            final i = val.toInt();
                            if (i < 0 || i >= _bucketDates.length) {
                              return const SizedBox.shrink();
                            }
                            final isToday = i == 6;
                            final label = _dayAbbr(_bucketDates[i].weekday);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                label,
                                style: AppTextStyles.caption.copyWith(
                                  color: isToday
                                      ? AppColors.emerald
                                      : AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(7, (i) {
                      final isToday = i == 6;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [
                                      AppColors.emerald.withOpacity(0.6),
                                      AppColors.emerald,
                                    ]
                                  : [
                                      AppColors.emerald.withOpacity(0.12),
                                      AppColors.emerald.withOpacity(0.3),
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    }),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.textPrimary,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        getTooltipItem: (group, gI, rod, rI) {
                          final i = group.x;
                          final date = i < _bucketDates.length
                              ? _bucketDates[i]
                              : null;
                          final dateStr = date != null
                              ? '${date.day}/${date.month}/${date.year}'
                              : '';
                          return BarTooltipItem(
                            '${rod.toY.toInt()} ${_metric == 0 ? 'user${rod.toY.toInt() == 1 ? '' : 's'}' : 'loan${rod.toY.toInt() == 1 ? '' : 's'}'}\n$dateStr',
                            AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 8),

            // ── Legend + refresh indicator ──
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Today',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted, fontSize: 9)),
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Previous',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dayAbbr(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: active ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
