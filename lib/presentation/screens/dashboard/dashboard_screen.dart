import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/glass_card.dart';
import '../auth/login_screen.dart';
import '../auth/admin_requests_screen.dart';
import '../members/member_directory_screen.dart';
import '../tracking/expiry_tracker_screen.dart';
import '../payments/payment_screen.dart';
import '../payments/financial_report_screen.dart';
import '../attendance/attendance_screen.dart';
import '../website/website_manager_screen.dart';
import '../admin/staff_directory_screen.dart';
import '../profile/profile_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStats();
    });
  }

  Future<void> _refreshStats() async {
    final payProvider = Provider.of<PaymentProvider>(context, listen: false);
    await payProvider.fetchDashboardStats();
    await payProvider.fetchFinancialReports();
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.neonRed.withOpacity(0.5), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.power_settings_new_rounded, color: AppColors.neonRed, size: 28),
              SizedBox(width: 12),
              Text(
                'Log Out?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of Muscles Up? You will need to enter your email and password to log back in.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // pop dialog
                auth.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonRed.withOpacity(0.15),
                foregroundColor: AppColors.neonRed,
                side: const BorderSide(color: AppColors.neonRed, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'LOG OUT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final payProvider = Provider.of<PaymentProvider>(context);
    final stats = payProvider.dashboardStats;
    final isLoading = payProvider.isLoading;

    final membersCount = stats['members'] ?? {};
    final collections = stats['collections'] ?? {};
    final alerts = stats['alerts'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('MUSCLES UP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _refreshStats,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded, color: AppColors.neonBlue),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
              );
            },
            tooltip: 'Profile Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.neonRed),
            onPressed: () => _showLogoutConfirmation(context, auth),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : RefreshIndicator(
              onRefresh: _refreshStats,
              color: AppColors.neonGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome & Role card
                    _buildWelcomeCard(user?.name ?? 'Coach', user?.role ?? 'staff'),
                    const SizedBox(height: 24),

                    // Metrics Dashboard Cards Grid (2x3)
                    const Text(
                      'GYM OVERVIEW',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildMetricCard(
                          title: 'Active Members',
                          value: '${membersCount['active'] ?? 0}',
                          subtitle: 'Total: ${membersCount['total'] ?? 0}',
                          icon: Icons.people_outline,
                          color: AppColors.neonGreen,
                        ),
                        _buildMetricCard(
                          title: 'New Admissions',
                          value: '${membersCount['newToday'] ?? 0}',
                          subtitle: "Added Today",
                          icon: Icons.add_moderator,
                          color: AppColors.neonBlue,
                        ),
                        _buildMetricCard(
                          title: "Today's Collection",
                          value: _currencyFormat.format(collections['today'] ?? 0.0),
                          subtitle: "Daily Cash Log",
                          icon: Icons.monetization_on_outlined,
                          color: AppColors.neonGreen,
                        ),
                        _buildMetricCard(
                          title: 'Monthly Revenue',
                          value: _currencyFormat.format(collections['monthly'] ?? 0.0),
                          subtitle: 'Active Cycle',
                          icon: Icons.calendar_today_outlined,
                          color: AppColors.neonBlue,
                        ),
                        _buildMetricCard(
                          title: 'Yearly Aggregate',
                          value: _currencyFormat.format(collections['yearly'] ?? 0.0),
                          subtitle: 'Annual Flow',
                          icon: Icons.analytics_outlined,
                          color: AppColors.neonAmber,
                        ),
                        _buildMetricCard(
                          title: 'Urgent Expiries',
                          value: '${alerts['upcomingExpirations'] ?? 0}',
                          subtitle: 'Next 10 Days',
                          icon: Icons.warning_amber_outlined,
                          color: AppColors.neonRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Revenue Line Chart Panel
                    const Text(
                      'MONTHLY REVENUE TREND',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRevenueChartCard(payProvider.dailyChartData),
                    const SizedBox(height: 28),

                    // Quick Control Hub panel
                    const Text(
                      'ADMINISTRATIVE HUB',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildControlGrid(user?.role == 'admin'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // Builder for Welcome Glass Card
  Widget _buildWelcomeCard(String name, String role) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: AppColors.greenGlow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Live Control Room Node',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Builder for Metric cards
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color.withOpacity(0.8), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // Beautiful Revenue Line Chart Card
  Widget _buildRevenueChartCard(List<dynamic> chartData) {
    if (chartData.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No revenue transactions logged yet this month.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final List<FlSpot> spots = [];
    double maxAmount = 0.0;
    
    for (int i = 0; i < chartData.length; i++) {
      final amount = double.tryParse(chartData[i]['amount'].toString()) ?? 0.0;
      if (amount > maxAmount) maxAmount = amount;
      
      // Parse day of month from 'YYYY-MM-DD'
      int day = i + 1;
      try {
        final date = DateTime.parse(chartData[i]['date']);
        day = date.day;
      } catch (_) {}

      spots.add(FlSpot(day.toDouble(), amount));
    }

    // Round max amount up for clean grids
    maxAmount = maxAmount == 0.0 ? 1000.0 : maxAmount * 1.25;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 16),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withOpacity(0.05),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxAmount / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : '${value.toInt()}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 7, // Marks approx once a week
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 1,
            maxX: 31,
            minY: 0,
            maxY: maxAmount,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [AppColors.neonGreen, AppColors.neonBlue],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonGreen.withOpacity(0.12),
                      AppColors.neonBlue.withOpacity(0.01),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builder for Action Grids
  Widget _buildControlGrid(bool isAdmin) {
    final List<_HubItem> items = [
      _HubItem(
        label: 'Member Directory',
        desc: 'Add & Search Members',
        icon: Icons.assignment_ind_outlined,
        color: AppColors.neonGreen,
        target: const MemberDirectoryScreen(),
      ),
      _HubItem(
        label: 'Tracking & Alerts',
        desc: 'Send WhatsApp & Expiries',
        icon: Icons.notifications_active_outlined,
        color: AppColors.neonAmber,
        target: const ExpiryTrackerScreen(),
      ),
      _HubItem(
        label: 'Manual Payments',
        desc: 'Collect Membership Fees',
        icon: Icons.payments_outlined,
        color: AppColors.neonBlue,
        target: const PaymentScreen(),
      ),
      _HubItem(
        label: 'Financial Ledger',
        desc: 'Reports & PDF Export',
        icon: Icons.picture_as_pdf_outlined,
        color: AppColors.neonGreen,
        target: const FinancialReportScreen(),
      ),
      _HubItem(
        label: 'Attendance Register',
        desc: 'Mark Daily Checkins',
        icon: Icons.fact_check_outlined,
        color: AppColors.neonBlue,
        target: const AttendanceScreen(),
      ),
    ];

    if (isAdmin) {
      items.add(
        _HubItem(
          label: 'Staff Approvals',
          desc: 'Authorize Pending Users',
          icon: Icons.security_outlined,
          color: AppColors.neonAmber,
          target: const AdminRequestsScreen(),
        ),
      );
      items.add(
        _HubItem(
          label: 'Staff Directory',
          desc: 'Manage Staff Credentials',
          icon: Icons.badge_outlined,
          color: AppColors.neonGreen,
          target: const StaffDirectoryScreen(),
        ),
      );
      items.add(
        _HubItem(
          label: 'Website Control',
          desc: 'Manage Web & Inquiries',
          icon: Icons.language_outlined,
          color: AppColors.neonBlue,
          target: const WebsiteManagerScreen(),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, idx) {
        final item = items[idx];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => item.target),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderColor: item.color.withOpacity(0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 24),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  item.desc,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Model for navigation grids
class _HubItem {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final Widget target;

  _HubItem({
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.target,
  });
}
