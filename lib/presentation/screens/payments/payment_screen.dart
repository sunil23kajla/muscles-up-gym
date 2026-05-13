import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/member_model.dart';
import '../../providers/member_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

class PaymentScreen extends StatefulWidget {
  final String? preSelectedMemberId;

  const PaymentScreen({super.key, this.preSelectedMemberId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedMemberId;
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.preSelectedMemberId;
    
    // Load members dropdown indices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).fetchMembers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate.isAfter(now) ? now : _paymentDate,
      firstDate: DateTime(2022),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _submit() async {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member.'), backgroundColor: AppColors.neonRed),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final payProvider = Provider.of<PaymentProvider>(context, listen: false);
    final success = await payProvider.recordPayment(
      memberId: _selectedMemberId!,
      amount: double.parse(_amountController.text.trim()),
      paymentDate: DateFormat('yyyy-MM-dd').format(_paymentDate),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment registered successfully!'), backgroundColor: AppColors.neonGreen),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payProvider.errorMessage ?? 'Transaction recording failed.'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final payProvider = Provider.of<PaymentProvider>(context);
    final members = memberProvider.members;
    final isLoading = payProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Log'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MEMBER SELECTION',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    
                    // Selection dropdown for members
                    widget.preSelectedMemberId != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161F35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'Profile Linked Automatically',
                              style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold),
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedMemberId,
                            dropdownColor: AppColors.surface,
                            isExpanded: true,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Select Member...',
                              prefixIcon: Icon(Icons.person, color: AppColors.textSecondary),
                            ),
                            items: members.map((m) {
                              return DropdownMenuItem<String>(
                                value: m.id,
                                child: Text(m.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedMemberId = val;
                              });
                            },
                          ),
                    const SizedBox(height: 24),

                    // Cash parameters
                    CustomTextField(
                      label: 'Collection Amount (₹)',
                      hint: 'Enter collection amount',
                      prefixIcon: Icons.currency_rupee,
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Amount is required';
                        if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      label: 'Payment Notes / Descriptions',
                      hint: 'Enter payment notes / description',
                      prefixIcon: Icons.description_outlined,
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transaction date picker panel
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Transaction Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppColors.neonBlue, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMMM, yyyy').format(_paymentDate),
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
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              NeonButton(
                text: 'COMMIT CASH TRANSACTION',
                isLoading: isLoading,
                icon: Icons.payments,
                gradient: AppColors.cyberGlow,
                glowColor: AppColors.neonBlue.withOpacity(0.25),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
