import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchPendingRequests();
    });
  }

  void _handleAction(String userId, String status, String name) async {
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .updateRequestStatus(userId, status);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff "$name" was successfully ${status == 'approved' ? 'approved' : 'rejected'}.'),
          backgroundColor: status == 'approved' ? AppColors.neonGreen : AppColors.neonRed,
        ),
      );
    } else {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update request.'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pendingUsers = auth.pendingRequests;
    final isLoading = auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Approvals'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : pendingUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No Pending Requests',
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
                          'When new coaches or staff members register, their requests will appear here for your review.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: pendingUsers.length,
                  itemBuilder: (context, idx) {
                    final req = pendingUsers[idx];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.neonAmber.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppColors.neonAmber),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  req.email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Action Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Reject Button
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: AppColors.neonRed),
                                onPressed: () => _handleAction(req.id, 'rejected', req.name),
                                tooltip: 'Reject Request',
                              ),
                              const SizedBox(width: 4),
                              // Approve Button
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: AppColors.neonGreen),
                                onPressed: () => _handleAction(req.id, 'approved', req.name),
                                tooltip: 'Approve Request',
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
