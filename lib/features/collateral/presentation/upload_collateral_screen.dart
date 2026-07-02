import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';

class UploadCollateralScreen extends ConsumerStatefulWidget {
  const UploadCollateralScreen({super.key});
  @override
  ConsumerState<UploadCollateralScreen> createState() => _UploadCollateralScreenState();
}

class _UploadCollateralScreenState extends ConsumerState<UploadCollateralScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _serialCtr  = TextEditingController();
  final _valueCtr   = TextEditingController();
  final _descCtr    = TextEditingController();
  String? _selectedType;
  String? _selectedCondition;
  final _photos = <File>[];
  File? _invoiceFile;
  bool _loading = false;

  final _conditions = ['Excellent', 'Good', 'Fair', 'Poor'];

  Future<void> _pickPhoto() async {
    if (_photos.length >= 6) return;
    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
    if (img != null) setState(() => _photos.add(File(img.path)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select collateral type')));
      return;
    }
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one photo')));
      return;
    }
    setState(() => _loading = true);
    // Simulate upload
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Collateral uploaded successfully!')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Upload Collateral'),
        leading: AppIconButton(icon: Icons.arrow_back_rounded, onPressed: () => context.pop(), bgColor: Colors.transparent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.info_rounded, color: AppColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Clear photos and accurate details help lenders make faster decisions.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                )),
              ]),
            ).animate().fadeIn(),

            SizedBox(height: 24),
            _SectionLabel('Item Details'),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType, dropdownColor: AppColors.surface,
              decoration: InputDecoration(labelText: 'Item Type', prefixIcon: Icon(Icons.category_rounded)),
              items: AppConstants.collateralTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedType = v),
              validator: (v) => v == null ? 'Select item type' : null,
            ).animate().fadeIn(delay: 50.ms),

            SizedBox(height: 16),
            TextFormField(
              controller: _serialCtr, style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(labelText: 'Serial / IMEI Number', prefixIcon: Icon(Icons.numbers_rounded)),
              validator: (v) => AppValidators.required(v, 'Serial number'),
            ).animate().fadeIn(delay: 80.ms),

            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCondition, dropdownColor: AppColors.surface,
              decoration: InputDecoration(labelText: 'Condition', prefixIcon: Icon(Icons.star_rounded)),
              items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCondition = v),
              validator: (v) => v == null ? 'Select condition' : null,
            ).animate().fadeIn(delay: 100.ms),

            SizedBox(height: 16),
            TextFormField(
              controller: _valueCtr, keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Current Market Value (₹)',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: AppValidators.amount,
            ).animate().fadeIn(delay: 120.ms),

            SizedBox(height: 24),
            _SectionLabel('Photos (up to 6)'),

            // Photo grid
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemCount: _photos.length + 1,
              itemBuilder: (context, i) {
                if (i == _photos.length) {
                  return GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3), style: BorderStyle.solid),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_rounded, color: AppColors.gold, size: 28),
                        SizedBox(height: 4),
                        Text('Add Photo', style: AppTextStyles.caption),
                      ]),
                    ),
                  );
                }
                return Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photos[i], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
                  Positioned(top: 4, right: 4, child: GestureDetector(
                    onTap: () => setState(() => _photos.removeAt(i)),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
                    ),
                  )),
                ]);
              },
            ).animate().fadeIn(delay: 140.ms),

            SizedBox(height: 20),
            _SectionLabel('Description'),
            TextFormField(
              controller: _descCtr, maxLines: 3, style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Describe the item (age, brand, specs...)',
                alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded),
              ),
              validator: (v) => AppValidators.required(v, 'Description'),
            ).animate().fadeIn(delay: 160.ms),

            SizedBox(height: 32),
            AppButton(label: 'Upload Collateral', onPressed: _submit, isLoading: _loading,
                icon: Icon(Icons.cloud_upload_rounded, size: 18))
                .animate().fadeIn(delay: 200.ms),
            SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: AppTextStyles.h3.copyWith(color: AppColors.gold)),
  );
}


