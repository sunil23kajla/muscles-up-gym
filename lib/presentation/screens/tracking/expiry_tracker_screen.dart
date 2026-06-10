import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/member_model.dart';
import '../../providers/member_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/member_photo_avatar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExpiryTrackerScreen extends StatefulWidget {
  const ExpiryTrackerScreen({super.key});

  @override
  State<ExpiryTrackerScreen> createState() => _ExpiryTrackerScreenState();
}

class _ExpiryTrackerScreenState extends State<ExpiryTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExpiries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpiries() async {
    await Provider.of<MemberProvider>(context, listen: false).fetchExpiriesAndAlerts();
  }

  // Pre-fill and launch WhatsApp with custom text templates
  Future<void> _sendWhatsApp(MemberModel member) async {
    final name = member.name;
    // Strip all non-digits
    String phone = member.phone.replaceAll(RegExp(r'\D'), ''); 
    if (phone.length == 10) {
      phone = '91$phone'; // Add India country code if exactly 10 digits
    }
    
    // Construct tailored template
    String textMessage = '';
    if (member.isExpired) {
      textMessage = "Hi $name, your Muscles Up Gym membership has expired! Don't let your streak break. Drop by the front desk to renew your subscription. Keep crushing it! 💪🏋️";
    } else {
      final days = member.daysRemaining;
      textMessage = "Hey $name, hope you are crushing your workouts! This is a friendly reminder that your Muscles Up Gym membership expires in $days days (on ${member.subscriptionEnd}). Tap to lock in your renewal! 🔥💪";
    }

    final encodedMessage = Uri.encodeComponent(textMessage);
    // Standard WhatsApp wa.me link structure
    final urlString = 'https://wa.me/$phone?text=$encodedMessage';
    final uri = Uri.parse(urlString);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showToast("Could not launch WhatsApp. Error: $e", true);
    }
  }

  // Pre-fill and launch SMS client
  Future<void> _sendSMS(MemberModel member) async {
    final name = member.name;
    final phone = member.phone.replaceAll(RegExp(r'\s+'), '');

    String textMessage = '';
    if (member.isExpired) {
      textMessage = "Hi $name, your Muscles Up Gym membership has expired! Visit front desk to renew. Let's keep training! 💪";
    } else {
      textMessage = "Hi $name, friendly reminder that your Muscles Up Gym membership expires on ${member.subscriptionEnd}. Tap to renew! 💪";
    }

    final Uri uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{
        'body': textMessage,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not open SMS app.';
      }
    } catch (e) {
      _showToast(e.toString(), true);
    }
  }

  void _showToast(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.neonRed : AppColors.neonGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final expiringSoon = memberProvider.expiringSoon;
    final expired = memberProvider.expiredMembers;
    final isLoading = memberProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Tracker'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonGreen,
          labelColor: AppColors.neonGreen,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'EXPIRING SOON (${expiringSoon.length})'),
            Tab(text: 'EXPIRED (${expired.length})'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRosterList(expiringSoon, isExpiringList: true),
                _buildRosterList(expired, isExpiringList: false),
              ],
            ),
    );
  }

  Widget _buildRosterList(List<MemberModel> list, {required bool isExpiringList}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpiringList ? Icons.verified_user_outlined : Icons.hourglass_disabled_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isExpiringList ? 'No Expiring Accounts' : 'No Expired Members',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                isExpiringList 
                    ? 'All memberships are active with healthy subscription durations. Great job!'
                    : 'Zero members with expired accounts are on the registry index.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final member = list[idx];
        final isUrgent = isExpiringList && member.daysRemaining <= 3;

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          borderColor: isUrgent 
              ? AppColors.neonAmber.withOpacity(0.3) 
              : isExpiringList 
                  ? AppColors.neonBlue.withOpacity(0.12)
                  : AppColors.neonRed.withOpacity(0.2),
          child: Row(
            children: [
              MemberPhotoAvatar(base64Photo: member.photo, name: member.name, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExpiringList 
                          ? 'Expires in ${member.daysRemaining} days (${DateFormat('dd MMM').format(DateTime.parse(member.subscriptionEnd))})'
                          : 'Expired on ${DateFormat('dd MMM, yyyy').format(DateTime.parse(member.subscriptionEnd))}',
                      style: TextStyle(
                        color: isUrgent 
                            ? AppColors.neonAmber 
                            : isExpiringList 
                                ? AppColors.textSecondary 
                                : AppColors.neonRed.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Reminders launching hub buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.sms_outlined, color: AppColors.neonBlue, size: 20),
                    onPressed: () => _sendSMS(member),
                    tooltip: 'Send SMS',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: AppColors.neonGreen, size: 22),
                    onPressed: () => _sendWhatsApp(member),
                    tooltip: 'WhatsApp Reminder',
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
