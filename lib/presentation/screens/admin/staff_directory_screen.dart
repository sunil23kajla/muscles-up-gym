import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/glass_card.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStaff();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    await Provider.of<AuthProvider>(context, listen: false).fetchStaffList();
  }

  void _showDeleteConfirmation(BuildContext context, UserModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonRed.withOpacity(0.3), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.neonRed, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Remove Staff?',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete ${staff.name} (${staff.email}) from the system? They will be immediately logged out and blocked from logging back in.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<AuthProvider>(context, listen: false)
                  .deleteStaff(staff.id);
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Staff member deleted successfully.'),
                    backgroundColor: AppColors.neonGreen,
                  ),
                );
              } else {
                final error = Provider.of<AuthProvider>(context, listen: false).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Failed to delete staff member.'),
                    backgroundColor: AppColors.neonRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed.withOpacity(0.15),
              foregroundColor: AppColors.neonRed,
              side: const BorderSide(color: AppColors.neonRed),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context, UserModel staff) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonBlue.withOpacity(0.3), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: AppColors.neonBlue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reset Password',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manually reset password for ${staff.name}.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  hintText: 'Enter new password',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.neonBlue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.neonRed),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.neonRed, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Password is required';
                  if (val.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();

              final success = await Provider.of<AuthProvider>(context, listen: false)
                  .adminResetPassword(staff.id, passwordController.text.trim());

              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password for ${staff.name} reset successfully.'),
                    backgroundColor: AppColors.neonGreen,
                  ),
                );
              } else {
                final error = Provider.of<AuthProvider>(context, listen: false).errorMessage;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Failed to reset password.'),
                    backgroundColor: AppColors.neonRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonBlue.withOpacity(0.15),
              foregroundColor: AppColors.neonBlue,
              side: const BorderSide(color: AppColors.neonBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final staffList = authProvider.staffList.where((s) {
      final nameMatches = s.name.toLowerCase().contains(_searchQuery);
      final emailMatches = s.email.toLowerCase().contains(_searchQuery);
      return nameMatches || emailMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E293B), AppColors.background],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Column(
          children: [
            // Search Input Panel
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search staff by name or email...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Active employee listings
            Expanded(
              child: authProvider.isLoading && staffList.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
                  : RefreshIndicator(
                      onRefresh: _fetchStaff,
                      color: AppColors.neonGreen,
                      child: staffList.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                const Center(
                                  child: Text(
                                    'No active staff members found.',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: staffList.length,
                              itemBuilder: (context, index) {
                                final staff = staffList[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GlassCard(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    borderColor: Colors.white.withOpacity(0.05),
                                    child: Row(
                                      children: [
                                        // Profile initials badge
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.neonBlue.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
                                          ),
                                          child: Center(
                                            child: Text(
                                              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                                              style: const TextStyle(
                                                color: AppColors.neonBlue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Metadata
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                staff.name,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                staff.email,
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Action items
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Reset Password Button
                                            IconButton(
                                              icon: const Icon(Icons.lock_reset_rounded, color: AppColors.neonBlue),
                                              tooltip: 'Reset Staff Password',
                                              onPressed: () => _showPasswordResetDialog(context, staff),
                                            ),
                                            // Delete Staff Button
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.neonRed),
                                              tooltip: 'Delete Staff Member',
                                              onPressed: () => _showDeleteConfirmation(context, staff),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
