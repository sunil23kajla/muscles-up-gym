import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/member_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/member_photo_avatar.dart';
import '../../widgets/status_badge.dart';
import 'add_edit_member_screen.dart';
import 'member_detail_screen.dart';

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final List<String> _statuses = ['all', 'active', 'expired', 'pending'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFilteredMembers();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _fetchFilteredMembers();
  }

  void _onSearchChanged() {
    _fetchFilteredMembers();
  }

  void _fetchFilteredMembers() {
    final status = _statuses[_tabController.index] == 'all' ? null : _statuses[_tabController.index];
    final search = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    
    Provider.of<MemberProvider>(context, listen: false).fetchMembers(
      status: status,
      search: search,
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final members = memberProvider.members;
    final isLoading = memberProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Directory'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonGreen,
          labelColor: AppColors.neonGreen,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'ACTIVE'),
            Tab(text: 'EXPIRED'),
            Tab(text: 'PENDING'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Elegant Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // Members Scroll Area
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
                : members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'No Members Found',
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
                                'Try widening your filters or register a new member profile using the floating green button below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: members.length,
                        itemBuilder: (context, idx) {
                          final member = members[idx];
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MemberDetailScreen(memberId: member.id),
                                ),
                              ).then((_) => _fetchFilteredMembers()); // Refetch details on popping back
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  MemberPhotoAvatar(
                                    base64Photo: member.photo,
                                    name: member.name,
                                    radius: 26,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, color: AppColors.textMuted, size: 12),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                member.phone,
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          member.isExpired
                                              ? 'Expired subscription'
                                              : 'Expires in: ${member.daysRemaining} days',
                                          style: TextStyle(
                                            color: member.isExpired
                                                ? AppColors.neonRed.withOpacity(0.8)
                                                : member.isUrgentExpiry
                                                    ? AppColors.neonAmber
                                                    : AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: member.isUrgentExpiry ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(status: member.status),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGreen,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add_alt_1, size: 24),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditMemberScreen()),
          ).then((_) => _fetchFilteredMembers());
        },
      ),
    );
  }
}
