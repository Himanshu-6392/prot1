import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';

class AdminKycReviewScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const AdminKycReviewScreen({
    super.key,
    required this.uid,
    required this.userData,
  });

  @override
  State<AdminKycReviewScreen> createState() => _AdminKycReviewScreenState();
}

class _AdminKycReviewScreenState extends State<AdminKycReviewScreen> {
  bool _loading = false;

  Future<void> _updateKyc({
    required String status,
    required bool isVerified,
    String? rejectionReason,
  }) async {
    setState(() => _loading = true);
    try {
      final Map<String, dynamic> updates = {
        'kycStatus': status,
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (rejectionReason != null) {
        updates['kycRejectionReason'] = rejectionReason;
      }
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(widget.uid)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isVerified
              ? 'KYC Approved — ${widget.userData['name']} is now verified'
              : 'KYC Rejected — ${widget.userData['name']} has been notified'),
          backgroundColor: isVerified ? AppColors.emerald : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirmReject() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject KYC',
            style:
                AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide a reason (optional):',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'e.g. Blurry selfie, Aadhaar number mismatch...',
                hintStyle: AppTextStyles.caption,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.error, width: 1.5)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateKyc(
                status: 'rejected',
                isVerified: false,
                rejectionReason: reasonCtrl.text.trim().isNotEmpty
                    ? reasonCtrl.text.trim()
                    : null,
              );
            },
            child: Text('Reject',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kyc = (widget.userData['kyc'] as Map<String, dynamic>?) ?? {};
    final name = widget.userData['name'] ?? 'Unknown';
    final email = widget.userData['email'] ?? '';
    final role = widget.userData['role'] ?? 'borrower';
    final phone = widget.userData['phone'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final submittedAt = kyc['submittedAt'];
    DateTime? submittedDate;
    if (submittedAt is Timestamp) submittedDate = submittedAt.toDate();

    // Determine if borrower or lender to show the right fields
    final isBorrower = role == 'borrower' || role == 'both';
    final isLender = role == 'lender' || role == 'both';

    final String? selfieUrl = kyc['selfieUrl'];
    final String? aadhaar = kyc['aadhaar'];
    final String? pan = kyc['pan'];
    final String? address = kyc['address'];
    final String? bankName = kyc['bankName'];
    final String? account = kyc['account'];
    final String? ifsc = kyc['ifsc'];
    final String? gst = kyc['gst'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('KYC Review',
            style: AppTextStyles.h3
                .copyWith(color: AppColors.textPrimary, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Scrollable doc content ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── User identity card ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(initial,
                                style: AppTextStyles.h2.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: AppTextStyles.h4.copyWith(
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(email,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textMuted)),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(phone,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                        ),
                        _RoleBadge(role: role),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  if (submittedDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted ${AppFormatters.formatRelative(submittedDate)}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Selfie section ──
                  if (selfieUrl != null && selfieUrl.isNotEmpty) ...[
                    _SectionTitle(label: 'Selfie Photo'),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        selfieUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    height: 220,
                                    color: AppColors.surfaceAlt,
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.emerald)),
                                  ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    color: AppColors.textMuted),
                                const SizedBox(height: 4),
                                Text('Could not load image',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),
                  ] else ...[
                    _SectionTitle(label: 'Selfie Photo'),
                    const SizedBox(height: 10),
                    _EmptyDocBox(label: 'No selfie uploaded'),
                    const SizedBox(height: 24),
                  ],

                  // ── Identity documents ──
                  _SectionTitle(label: 'Identity Documents'),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      if (aadhaar != null && aadhaar.isNotEmpty)
                        _DocInfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Aadhaar Number',
                          value: _maskAadhaar(aadhaar),
                        ),
                      if (pan != null && pan.isNotEmpty)
                        _DocInfoTile(
                          icon: Icons.credit_card_rounded,
                          label: 'PAN Number',
                          value: pan,
                        ),
                      if (address != null && address.isNotEmpty)
                        _DocInfoTile(
                          icon: Icons.home_outlined,
                          label: 'Residential Address',
                          value: address,
                        ),
                      if (aadhaar == null && pan == null && address == null)
                        _EmptyDocBox(label: 'No identity documents submitted'),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  // ── Banking / Business (Lender only) ──
                  if (isLender &&
                      (bankName != null ||
                          account != null ||
                          ifsc != null ||
                          gst != null)) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(label: 'Banking & Business Details'),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        if (bankName != null && bankName.isNotEmpty)
                          _DocInfoTile(
                            icon: Icons.account_balance_outlined,
                            label: 'Bank Name',
                            value: bankName,
                          ),
                        if (account != null && account.isNotEmpty)
                          _DocInfoTile(
                            icon: Icons.numbers_rounded,
                            label: 'Account Number',
                            value: _maskAccount(account),
                          ),
                        if (ifsc != null && ifsc.isNotEmpty)
                          _DocInfoTile(
                            icon: Icons.code_rounded,
                            label: 'IFSC Code',
                            value: ifsc,
                          ),
                        if (gst != null && gst.isNotEmpty)
                          _DocInfoTile(
                            icon: Icons.receipt_outlined,
                            label: 'GST Number',
                            value: gst,
                          ),
                      ],
                    ).animate().fadeIn(delay: 150.ms),
                  ],

                  // Space for fixed bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Fixed bottom action bar ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: _loading
                ? const Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : Row(
                    children: [
                      // Reject button
                      Expanded(
                        child: GestureDetector(
                          onTap: _confirmReject,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.error.withOpacity(0.5),
                                  width: 1.5),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close_rounded,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Reject',
                                      style: AppTextStyles.labelMedium
                                          .copyWith(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Approve button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _updateKyc(
                              status: 'verified', isVerified: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.emerald,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emerald.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Approve KYC',
                                      style: AppTextStyles.labelMedium
                                          .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700)),
                                ],
                              ),
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

  String _maskAadhaar(String a) {
    if (a.length < 4) return a;
    return 'XXXX XXXX ${a.substring(a.length - 4)}';
  }

  String _maskAccount(String a) {
    if (a.length < 4) return a;
    return '${'X' * (a.length - 4)}${a.substring(a.length - 4)}';
  }
}

// ─── Reusable widgets ────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.tag.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.5,
        fontSize: 10,
      ),
    );
  }
}

class _DocInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DocInfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icon, size: 17, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocBox extends StatelessWidget {
  final String label;
  const _EmptyDocBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined,
              color: AppColors.textMuted, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'lender':
        color = AppColors.emerald;
        break;
      case 'admin':
        color = Colors.purple;
        break;
      default:
        color = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTextStyles.tag.copyWith(color: color, fontSize: 9),
      ),
    );
  }
}
