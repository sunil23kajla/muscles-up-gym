import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/member_model.dart';
import '../../providers/member_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

class AddEditMemberScreen extends StatefulWidget {
  final MemberModel? member; // If null, we are adding. If provided, we are editing!

  const AddEditMemberScreen({super.key, this.member});

  @override
  State<AddEditMemberScreen> createState() => _AddEditMemberScreenState();
}

class _AddEditMemberScreenState extends State<AddEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bloodController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 29)); // Default 30-day cycle inclusive (29 days difference)
  
  final List<String> _plans = ['1 Month', '3 Months', '6 Months', '1 Year', '2 Years', 'Custom'];
  String _selectedPlan = '1 Month';

  String? _base64Photo;
  final ImagePicker _picker = ImagePicker();

  bool get isEditMode => widget.member != null;

  String _detectPlanFromDates(DateTime start, DateTime end) {
    final differenceInDays = end.difference(start).inDays;
    if (differenceInDays >= 28 && differenceInDays <= 32) return '1 Month';
    if (differenceInDays >= 88 && differenceInDays <= 93) return '3 Months';
    if (differenceInDays >= 178 && differenceInDays <= 185) return '6 Months';
    if (differenceInDays >= 360 && differenceInDays <= 368) return '1 Year';
    if (differenceInDays >= 725 && differenceInDays <= 735) return '2 Years';
    return 'Custom';
  }

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final m = widget.member!;
      _nameController.text = m.name;
      _phoneController.text = m.phone;
      _heightController.text = m.height != null ? m.height.toString() : '';
      _weightController.text = m.weight != null ? m.weight.toString() : '';
      _bloodController.text = m.bloodGroup ?? '';
      _startDate = DateTime.parse(m.subscriptionStart);
      _endDate = DateTime.parse(m.subscriptionEnd);
      _base64Photo = m.photo;
      _selectedPlan = _detectPlanFromDates(_startDate, _endDate);
    } else {
      _updateEndDateFromPlan('1 Month');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bloodController.dispose();
    super.dispose();
  }

  // Choose profile photo from camera/gallery and encode
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _base64Photo = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick photo: ${e.toString()}'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  // Show bottom sheet with picture picker channels
  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.neonGreen),
                title: const Text('Capture with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.neonBlue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_base64Photo != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.neonRed),
                  title: const Text('Remove Current Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _base64Photo = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _updateEndDateFromPlan(String plan) {
    setState(() {
      _selectedPlan = plan;
      switch (plan) {
        case '1 Month':
          _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day).subtract(const Duration(days: 1));
          break;
        case '3 Months':
          _endDate = DateTime(_startDate.year, _startDate.month + 3, _startDate.day).subtract(const Duration(days: 1));
          break;
        case '6 Months':
          _endDate = DateTime(_startDate.year, _startDate.month + 6, _startDate.day).subtract(const Duration(days: 1));
          break;
        case '1 Year':
          _endDate = DateTime(_startDate.year + 1, _startDate.month, _startDate.day).subtract(const Duration(days: 1));
          break;
        case '2 Years':
          _endDate = DateTime(_startDate.year + 2, _startDate.month, _startDate.day).subtract(const Duration(days: 1));
          break;
        default:
          break;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonGreen,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_selectedPlan != 'Custom') {
            _updateEndDateFromPlan(_selectedPlan);
          } else {
            _endDate = picked.add(const Duration(days: 29));
          }
        } else {
          _endDate = picked;
          _selectedPlan = 'Custom';
        }
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'photo': _base64Photo,
      'height': _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
      'weight': _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
      'bloodGroup': _bloodController.text.trim().isEmpty ? null : _bloodController.text.trim(),
      'subscriptionStart': DateFormat('yyyy-MM-dd').format(_startDate),
      'subscriptionEnd': DateFormat('yyyy-MM-dd').format(_endDate),
      'plan': _selectedPlan,
    };

    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    bool success;

    if (isEditMode) {
      success = await memberProvider.updateMember(widget.member!.id, data);
    } else {
      success = await memberProvider.addMember(data);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Member info updated successfully.' : 'New member added successfully.'),
          backgroundColor: AppColors.neonGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(memberProvider.errorMessage ?? 'Something went wrong'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final isLoading = memberProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Member Profile' : 'Add New Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Selection Circle Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.neonGreen, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: _base64Photo != null && _base64Photo!.isNotEmpty
                            ? Image.memory(base64Decode(_base64Photo!), fit: BoxFit.cover)
                            : Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.person, color: AppColors.textSecondary, size: 50),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showPhotoSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.neonGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Glass Fields Frame
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your name',
                      prefixIcon: Icons.badge_outlined,
                      controller: _nameController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Full Name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone number is required';
                        if (v.length < 8) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Height (cm)',
                            hint: 'Enter height',
                            prefixIcon: Icons.height,
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Weight (kg)',
                            hint: 'Enter weight',
                            prefixIcon: Icons.monitor_weight_outlined,
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Blood Group',
                      hint: 'Enter blood group',
                      prefixIcon: Icons.bloodtype_outlined,
                      controller: _bloodController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subscription Period Panel
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MEMBERSHIP DURATION',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPlan,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Membership Plan',
                        labelStyle: const TextStyle(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.bold),
                        prefixIcon: const Icon(Icons.card_membership_outlined, color: AppColors.neonGreen, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.neonGreen),
                        ),
                        filled: true,
                        fillColor: AppColors.surface.withOpacity(0.3),
                      ),
                      items: _plans.map((plan) {
                        return DropdownMenuItem<String>(
                          value: plan,
                          child: Text(plan),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _updateEndDateFromPlan(val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: AppColors.border.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: AppColors.neonGreen, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd MMM, yyyy').format(_startDate),
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.border),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Expiry Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, color: AppColors.neonRed, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd MMM, yyyy').format(_endDate),
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              NeonButton(
                text: isEditMode ? 'UPDATE MEMBERSHIP' : 'REGISTER NEW MEMBER',
                isLoading: isLoading,
                icon: isEditMode ? Icons.edit : Icons.person_add,
                onPressed: _save,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
