import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

class AssignWorkoutScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const AssignWorkoutScreen({super.key, required this.memberId, required this.memberName});

  @override
  State<AssignWorkoutScreen> createState() => _AssignWorkoutScreenState();
}

class _AssignWorkoutScreenState extends State<AssignWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingPlan();
    });
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _loadExistingPlan() async {
    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final plan = await attProvider.getWorkoutPlan(widget.memberId);
    if (mounted) {
      if (plan != null) {
        _planNameController.text = plan.planName;
        _detailsController.text = plan.details;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final result = await attProvider.assignWorkoutPlan(
      memberId: widget.memberId,
      planName: _planNameController.text.trim(),
      details: _detailsController.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout routine assigned for ${widget.memberName}!'),
          backgroundColor: AppColors.neonGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attProvider.errorMessage ?? 'Workout saving failed.'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateLoading = Provider.of<AttendanceProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Workout Plan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Member context banner
                    GlassCard(
                      borderColor: AppColors.neonGreen.withOpacity(0.15),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center, color: AppColors.neonGreen, size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CUSTOM SCHEDULE FOR:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                Text(
                                  widget.memberName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Inputs Card
                    GlassCard(
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Plan Title / Program Name',
                            hint: 'Enter workout plan title / name',
                            prefixIcon: Icons.title_rounded,
                            controller: _planNameController,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Plan Title is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            label: 'Exercises List & Schedules (Notes)',
                            hint: 'Enter exercises, sets, reps, and instructions...',
                            prefixIcon: Icons.list_alt,
                            controller: _detailsController,
                            maxLines: 12,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Workout instructions are required';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    NeonButton(
                      text: 'SAVE WORKOUT PLAN',
                      isLoading: stateLoading,
                      icon: Icons.check_circle_outline,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
