import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/member_photo_avatar.dart';
import '../../widgets/status_badge.dart';
import '../workout/assign_workout_screen.dart';
import '../payments/payment_screen.dart';
import 'add_edit_member_screen.dart';

class MemberDetailScreen extends StatefulWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  MemberModel? _detailedMember;
  bool _localLoading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
  }

  Future<void> _loadMemberDetails() async {
    setState(() => _localLoading = true);
    final provider = Provider.of<MemberProvider>(context, listen: false);
    final result = await provider.fetchMemberById(widget.memberId);
    if (mounted) {
      setState(() {
        _detailedMember = result;
        _localLoading = false;
      });
    }
  }

  // Dynamic BMI Calculation
  String _calculateBMI(double? heightCm, double? weightKg) {
    if (heightCm == null || weightKg == null || heightCm == 0) return 'N/A';
    final heightMeters = heightCm / 100.0;
    final bmi = weightKg / (heightMeters * heightMeters);
    String status = '';
    if (bmi < 18.5) {
      status = 'Underweight';
    } else if (bmi < 25) {
      status = 'Healthy';
    } else if (bmi < 30) {
      status = 'Overweight';
    } else {
      status = 'Obese';
    }
    return '${bmi.toStringAsFixed(1)} ($status)';
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Deletion', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to permanently remove "${_detailedMember?.name}" from the system? This action is irreversible and deletes all associated payment & attendance logs.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
            onPressed: () async {
              Navigator.pop(ctx); // Dismiss Dialog
              final success = await Provider.of<MemberProvider>(context, listen: false)
                  .deleteMember(widget.memberId);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member deleted successfully.'), backgroundColor: AppColors.neonRed),
                  );
                  Navigator.pop(context); // Go back to directory
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deletion failed. Retry later.'), backgroundColor: AppColors.neonRed),
                  );
                }
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.currentUser?.role == 'admin';

    if (_localLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Profile')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.neonGreen)),
      );
    }

    if (_detailedMember == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Profile')),
        body: const Center(
          child: Text('Failed to load profile. Member may have been deleted.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final m = _detailedMember!;

    // Cast payments/attendance if dynamic types are loaded from API
    final List<dynamic> paymentsList = m.toJson()['payments'] ?? [];
    final List<dynamic> attendanceList = m.toJson()['attendance'] ?? [];
    final Map<String, dynamic>? workoutObj = m.toJson()['workout'];

    // Summarize attendance stats
    final presents = attendanceList.where((a) => a['status'] == 'present').length;
    final totalAttendance = attendanceList.length;
    final attendancePercent = totalAttendance == 0 
        ? 'No logs' 
        : '${((presents / totalAttendance) * 100).toStringAsFixed(0)}% ($presents/$totalAttendance)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddEditMemberScreen(member: m)),
              ).then((_) => _loadMemberDetails());
            },
            tooltip: 'Edit Profile',
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined, color: AppColors.neonRed),
              onPressed: _confirmDelete,
              tooltip: 'Delete Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Header Glass Card
            GlassCard(
              child: Column(
                children: [
                  MemberPhotoAvatar(base64Photo: m.photo, name: m.name, radius: 44),
                  const SizedBox(height: 16),
                  Text(
                    m.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${m.phone}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusBadge(status: m.status),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: m.isExpired ? AppColors.neonRed.withOpacity(0.12) : AppColors.neonBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.isExpired ? 'EXPIRED' : '${m.daysRemaining} DAYS REMAINING',
                          style: TextStyle(
                            color: m.isExpired ? AppColors.neonRed : AppColors.neonBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('Plan', m.plan),
                      _buildHeaderStat('Joined', DateFormat('dd MMM, yy').format(DateTime.parse(m.subscriptionStart))),
                      _buildHeaderStat('Expires', DateFormat('dd MMM, yy').format(DateTime.parse(m.subscriptionEnd))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Physical Telemetry Stats
            const Text(
              'HEALTH & BODY STATS',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _buildProfileStatTile('Height', m.height != null ? '${m.height} cm' : 'N/A', Icons.height),
                  _buildProfileStatTile('Weight', m.weight != null ? '${m.weight} kg' : 'N/A', Icons.monitor_weight_outlined),
                  _buildProfileStatTile('Blood Group', m.bloodGroup ?? 'N/A', Icons.bloodtype_outlined),
                  _buildProfileStatTile('BMI Score', _calculateBMI(m.height, m.weight), Icons.scale_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Assigned Routine Program
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GYM WORKOUT PLAN',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AssignWorkoutScreen(memberId: m.id, memberName: m.name),
                      ),
                    ).then((_) => _loadMemberDetails());
                  },
                  icon: const Icon(Icons.edit_note, color: AppColors.neonGreen, size: 18),
                  label: Text(
                    workoutObj != null ? 'EDIT PLAN' : 'ASSIGN PLAN',
                    style: const TextStyle(color: AppColors.neonGreen, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: workoutObj != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workoutObj['planName'] ?? 'Custom Routine',
                          style: const TextStyle(color: AppColors.neonGreen, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          workoutObj['details'] ?? 'No schedule notes provided.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                        ),
                      ],
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No workout plan assigned yet.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // 4. Payment Logs Ledger
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TRANSACTION LEDGER',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(preSelectedMemberId: m.id),
                      ),
                    ).then((_) => _loadMemberDetails());
                  },
                  icon: const Icon(Icons.add_card, color: AppColors.neonBlue, size: 16),
                  label: const Text(
                    'ADD ENTRY',
                    style: TextStyle(color: AppColors.neonBlue, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: paymentsList.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('No transactions recorded yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paymentsList.length,
                      itemBuilder: (context, idx) {
                        final pay = paymentsList[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currencyFormat.format(double.parse(pay['amount'].toString())),
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                    ),
                                    if (pay['notes'] != null && pay['notes'].toString().isNotEmpty)
                                      Text(
                                        pay['notes'],
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd MMM, yyyy').format(DateTime.parse(pay['paymentDate'])),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // 5. Attendance Summary
            const Text(
              'ATTENDANCE METRICS',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_outlined, color: AppColors.neonBlue, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Attendance Ratio', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          attendancePercent,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProfileStatTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonBlue.withOpacity(0.7), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text(
                value,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
