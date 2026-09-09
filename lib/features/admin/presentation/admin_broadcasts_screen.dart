import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class AdminBroadcastsScreen extends ConsumerStatefulWidget {
  const AdminBroadcastsScreen({super.key});

  @override
  ConsumerState<AdminBroadcastsScreen> createState() => _AdminBroadcastsScreenState();
}

class _AdminBroadcastsScreenState extends ConsumerState<AdminBroadcastsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'all'; // all, borrowers, lenders
  DateTime? _deliverAt;
  bool _isScheduling = false;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        setState(() {
          _deliverAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _scheduleBroadcast() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    if (_deliverAt == null || _deliverAt!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery time must be in the future')));
      return;
    }

    setState(() => _isScheduling = true);
    try {
      await FirebaseFirestore.instance.collection('scheduled_broadcasts').add({
        'title': title,
        'body': body,
        'audience': _audience,
        'deliverAt': Timestamp.fromDate(_deliverAt!),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'scheduled',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast scheduled!')));
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() {
          _deliverAt = null;
          _isScheduling = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isScheduling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Scheduled Broadcasts', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Composer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compose New Broadcast', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Broadcast Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message Body',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _audience,
                    decoration: InputDecoration(
                      labelText: 'Target Audience',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'borrowers', child: Text('Borrowers Only')),
                      DropdownMenuItem(value: 'lenders', child: Text('Lenders Only')),
                    ],
                    onChanged: (val) => setState(() => _audience = val ?? 'all'),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: AppColors.gold, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _deliverAt == null 
                                  ? 'Select Delivery Date & Time' 
                                  : 'Deliver at: ${DateFormat('dd MMM yyyy, h:mm a').format(_deliverAt!)}',
                              style: AppTextStyles.bodyMedium.copyWith(color: _deliverAt == null ? AppColors.textMuted : AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isScheduling ? null : _scheduleBroadcast,
                      child: _isScheduling 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Schedule Broadcast', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text('Upcoming Broadcasts', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('scheduled_broadcasts')
                  .where('status', isEqualTo: 'scheduled')
                  .orderBy('deliverAt')
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
                      child: Text('No upcoming broadcasts', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final ts = data['deliverAt'] as Timestamp?;
                    final timeStr = ts != null ? DateFormat('dd MMM, h:mm a').format(ts.toDate()) : '';
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.campaign_rounded, color: AppColors.info, size: 20),
                      ),
                      title: Text(data['title'] ?? '', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                      subtitle: Text('Audience: ${data['audience']}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                      trailing: Text(timeStr, style: AppTextStyles.caption.copyWith(color: AppColors.info, fontWeight: FontWeight.bold)),
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
