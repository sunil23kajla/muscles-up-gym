import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/member_photo_avatar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDailyRoster();
  }

  void _loadDailyRoster() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchDailyRoster(dateStr);
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(), // Cannot mark future attendance
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyRoster();
    }
  }

  void _toggleAttendance(String memberId, String currentStatus, String targetStatus) async {
    // If selecting the same status, do nothing (do not unmark on double-click)
    if (currentStatus == targetStatus) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final provider = Provider.of<AttendanceProvider>(context, listen: false);

    await provider.markAttendance(
      memberId: memberId,
      date: dateStr,
      status: targetStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final attProvider = Provider.of<AttendanceProvider>(context);
    final roster = attProvider.dailyRoster;
    final isLoading = attProvider.isLoading;

    final presentCount = roster.where((m) => m.isPresent).length;
    final absentCount = roster.where((m) => m.isAbsent).length;
    final unmarkedCount = roster.where((m) => m.isUnmarked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Register'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant Date Controller Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.neonGreen, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, dd MMMM').format(_selectedDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar, color: AppColors.neonGreen),
                    onPressed: _pickDate,
                    tooltip: 'Change Registry Date',
                  )
                ],
              ),
            ),
          ),

          // Counts metrics row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildStatusCountBox('Present: $presentCount', AppColors.neonGreen),
                const SizedBox(width: 8),
                _buildStatusCountBox('Absent: $absentCount', AppColors.neonRed),
                const SizedBox(width: 8),
                _buildStatusCountBox('Unmarked: $unmarkedCount', AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily Register table
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
                : roster.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'No Active Members',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.0),
                              child: Text(
                                'You must have approved, active gym members on this date to mark attendance registers.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: roster.length,
                        itemBuilder: (context, idx) {
                          final att = roster[idx];
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                MemberPhotoAvatar(base64Photo: att.photo, name: att.name, radius: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    att.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // Present & Absent Quick check logs
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Present Button
                                    GestureDetector(
                                      onTap: () => _toggleAttendance(att.id, att.status, 'present'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: att.isPresent 
                                              ? AppColors.neonGreen 
                                              : AppColors.neonGreen.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: att.isPresent 
                                                ? AppColors.neonGreen 
                                                : AppColors.neonGreen.withOpacity(0.25),
                                            width: 1,
                                          )
                                        ),
                                        child: Text(
                                          'PRESENT',
                                          style: TextStyle(
                                            color: att.isPresent ? Colors.black : AppColors.neonGreen,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Absent Button
                                    GestureDetector(
                                      onTap: () => _toggleAttendance(att.id, att.status, 'absent'),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: att.isAbsent 
                                              ? AppColors.neonRed 
                                              : AppColors.neonRed.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: att.isAbsent 
                                                ? AppColors.neonRed 
                                                : AppColors.neonRed.withOpacity(0.25),
                                            width: 1,
                                          )
                                        ),
                                        child: Text(
                                          'ABSENT',
                                          style: TextStyle(
                                            color: att.isAbsent ? Colors.white : AppColors.neonRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCountBox(String text, Color borderColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: borderColor.withOpacity(0.05),
          border: Border.all(color: borderColor.withOpacity(0.3), width: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: borderColor == AppColors.textSecondary ? AppColors.textSecondary : borderColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
