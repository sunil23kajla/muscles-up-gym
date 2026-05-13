import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/inquiry_model.dart';
import '../../providers/website_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';

class WebsiteManagerScreen extends StatefulWidget {
  const WebsiteManagerScreen({super.key});

  @override
  State<WebsiteManagerScreen> createState() => _WebsiteManagerScreenState();
}

class _WebsiteManagerScreenState extends State<WebsiteManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for stats configuration
  final _trainedController = TextEditingController();
  final _coachesController = TextEditingController();
  final _expController = TextEditingController();

  // Controllers for announcement banner
  final _announcementController = TextEditingController();
  bool _showAnnouncement = true;

  // Controllers for videos configuration
  final _videoController = TextEditingController();

  // Controllers for gym contact details
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Local action state loaders
  bool _isInitialLoading = true;
  bool _isSavingCounters = false;
  bool _isSavingAnnouncement = false;
  bool _isUploadingPhoto = false;
  bool _isAddingVideo = false;
  bool _isSavingContact = false;
  bool _isSavingPlan = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial loading of settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WebsiteProvider>(context, listen: false);
      Future.wait([
        provider.fetchWebsiteConfig(),
        provider.fetchInquiries(),
      ]).then((_) {
        if (mounted) {
          setState(() {
            _trainedController.text =
                provider.stats['membersTrained'] ?? '1,000+';
            _coachesController.text = provider.stats['certifiedTrainers'] ?? '5+';
            _expController.text = provider.stats['yearsExp'] ?? '4+';
            _announcementController.text = provider.announcement['text'] ?? '';
            _showAnnouncement = provider.announcement['show'] ?? true;
            _addressController.text =
                provider.contact['address'] ??
                'Opposite High Court Lane, Sector 4, New Delhi';
            _phoneController.text = provider.contact['phone'] ?? '9876543210';
            _emailController.text =
                provider.contact['email'] ?? 'support@musclesup.com';
            _isInitialLoading = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trainedController.dispose();
    _coachesController.dispose();
    _expController.dispose();
    _announcementController.dispose();
    _videoController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Trigger Phone Call Action
  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to trigger phone call dialer.')),
        );
      }
    }
  }

  // Trigger pre-filled WhatsApp Action
  Future<void> _sendWhatsApp(
    String phoneNumber,
    String name,
    String package,
  ) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final String formattedPhone = cleanPhone.startsWith('91')
        ? cleanPhone
        : '91$cleanPhone';
    final String text =
        "Hello $name,\n\nThanks for reaching out to Muscles Up Gym! We noticed you inquired about the *$package Membership* on our website. Would you like to schedule a free session visit today?";
    final Uri url = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(text)}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp application is not installed.'),
          ),
        );
      }
    }
  }

  // Save Counters Settings
  void _saveStats() async {
    setState(() => _isSavingCounters = true);
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    final success = await provider.updateStats(
      membersTrained: _trainedController.text.trim(),
      certifiedTrainers: _coachesController.text.trim(),
      yearsExp: _expController.text.trim(),
    );

    if (mounted) setState(() => _isSavingCounters = false);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Website statistics updated successfully!'),
          backgroundColor: AppColors.neonGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to update statistics.',
          ),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  // Save Announcement Settings
  void _saveAnnouncement() async {
    setState(() => _isSavingAnnouncement = true);
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    final success = await provider.updateAnnouncement(
      show: _showAnnouncement,
      text: _announcementController.text.trim(),
    );

    if (mounted) setState(() => _isSavingAnnouncement = false);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Website announcement updated successfully!'),
          backgroundColor: AppColors.neonGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to update announcement.',
          ),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  // Pick image from local gallery, encode as base64 and save to server gallery
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Optimize sizing/resolution
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final String base64Image =
          "data:image/jpeg;base64,${base64Encode(bytes)}";

      if (!mounted) return;
      final provider = Provider.of<WebsiteProvider>(context, listen: false);
      final success = await provider.addGalleryImage(base64Image);

      if (mounted) setState(() => _isUploadingPhoto = false);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery photo uploaded successfully!'),
            backgroundColor: AppColors.neonGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to upload image.'),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error converting image: $e'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  // Save new YouTube / Short video link
  void _saveVideoLink() async {
    final text = _videoController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid video link.'),
          backgroundColor: AppColors.neonRed,
        ),
      );
      return;
    }

    setState(() => _isAddingVideo = true);
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    final success = await provider.addVideoLink(text);

    if (mounted) setState(() => _isAddingVideo = false);
    if (!mounted) return;
    if (success) {
      _videoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video link added successfully!'),
          backgroundColor: AppColors.neonGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to add video link.'),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  // Save Gym Contact Details to Server
  void _saveContactInfo() async {
    setState(() => _isSavingContact = true);
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    final success = await provider.updateContact(
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (mounted) setState(() => _isSavingContact = false);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact details saved successfully!'),
          backgroundColor: AppColors.neonGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to update contact details.',
          ),
          backgroundColor: AppColors.neonRed,
        ),
      );
    }
  }

  // Show a dialog to add or edit a subscription plan
  void _showPlanDialog({int? editIndex}) {
    final provider = Provider.of<WebsiteProvider>(context, listen: false);
    final isEditing = editIndex != null;

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final periodCtrl = TextEditingController(text: '/month');
    final badgeCtrl = TextEditingController();
    final featuresCtrl = TextEditingController();
    bool isFeatured = false;

    if (isEditing) {
      final plan = provider.plans[editIndex];
      nameCtrl.text = plan['name'] ?? '';
      priceCtrl.text = plan['price'] ?? '';
      periodCtrl.text = plan['period'] ?? '/month';
      badgeCtrl.text = plan['badge'] ?? '';
      isFeatured = plan['isFeatured'] ?? false;

      final List<dynamic> featuresList = plan['features'] ?? [];
      featuresCtrl.text = featuresList.join(', ');
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note : Icons.add_card,
                color: AppColors.neonBlue,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Edit Pricing Plan' : 'Add New Pricing Plan',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Plan Name',
                  hint: 'e.g. 3 Months Pro Pack',
                  controller: nameCtrl,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Price',
                  hint: 'e.g. ₹4,500',
                  controller: priceCtrl,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Pricing Period / Frequency',
                  hint: 'e.g. /month, /quarter, /year',
                  controller: periodCtrl,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Badge / Special Tag (Optional)',
                  hint: 'e.g. Best Value, Hot Seller',
                  controller: badgeCtrl,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Features (Comma Separated)',
                  hint: 'Full floor access, Cardio deck, Personal locker',
                  controller: featuresCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Featured / Highlighted Plan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: isFeatured,
                      activeColor: AppColors.neonBlue,
                      onChanged: (val) {
                        setDialogState(() {
                          isFeatured = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = priceCtrl.text.trim();
                final period = periodCtrl.text.trim();
                final badge = badgeCtrl.text.trim();
                final featuresText = featuresCtrl.text.trim();

                if (name.isEmpty || price.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill out Plan Name and Price.'),
                      backgroundColor: AppColors.neonRed,
                    ),
                  );
                  return;
                }

                final List<String> features = featuresText.isNotEmpty
                    ? featuresText
                          .split(',')
                          .map((f) => f.trim())
                          .where((f) => f.isNotEmpty)
                          .toList()
                    : [];

                final Map<String, dynamic> planData = {
                  'name': name,
                  'price': price,
                  'period': period,
                  'badge': badge.isNotEmpty ? badge : null,
                  'features': features,
                  'isFeatured': isFeatured,
                };

                final success = isEditing
                    ? await provider.editPlan(editIndex, planData)
                    : await provider.addPlan(planData);

                if (!context.mounted) return;
                Navigator.of(ctx).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Subscription plan updated successfully!'
                            : 'New subscription plan saved successfully!',
                      ),
                      backgroundColor: AppColors.neonGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ??
                            (isEditing ? 'Failed to update plan.' : 'Failed to add plan.'),
                      ),
                      backgroundColor: AppColors.neonRed,
                    ),
                  );
                }
              },
              child: const Text(
                'SAVE PLAN',
                style: TextStyle(
                  color: AppColors.neonBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WebsiteProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Website Control Center'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonBlue,
          labelColor: AppColors.neonBlue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.settings_ethernet), text: 'Layout Settings'),
            Tab(icon: Icon(Icons.people_outline), text: 'User Inquiries'),
          ],
        ),
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonBlue),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLayoutSettingsTab(provider),
                _buildInquiriesTab(provider),
              ],
            ),
    );
  }

  // TAB 1: WEBSITE LAYOUT CONTROLS
  Widget _buildLayoutSettingsTab(WebsiteProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dynamic Counters Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.query_stats,
                      color: AppColors.neonBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'WEBSITE COUNTERS (STATS)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'These values show up in the animated counters section of your website.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Total Members Trained',
                  hint: 'e.g. 1,500+',
                  prefixIcon: Icons.fitness_center,
                  controller: _trainedController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Certified Coaches',
                  hint: 'e.g. 8+',
                  prefixIcon: Icons.engineering,
                  controller: _coachesController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Years of Excellence',
                  hint: 'e.g. 5+',
                  prefixIcon: Icons.calendar_today,
                  controller: _expController,
                ),
                const SizedBox(height: 24),
                NeonButton(
                  text: 'SAVE COUNTERS',
                  icon: Icons.check,
                  isLoading: _isSavingCounters,
                  onPressed: _saveStats,
                  gradient: AppColors.cyberGlow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Announcement Banner Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, color: AppColors.neonGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'MARQUEE ANNOUNCEMENT BANNER',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'This text flashes at the absolute top of the homepage in a continuous scrolling marquee.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Show Announcement Banner',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _showAnnouncement,
                      activeColor: AppColors.neonGreen,
                      onChanged: (val) {
                        setState(() {
                          _showAnnouncement = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Announcement Banner Text',
                  hint: 'Enter special offer text...',
                  prefixIcon: Icons.edit_note,
                  controller: _announcementController,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                NeonButton(
                  text: 'SAVE ANNOUNCEMENT',
                  icon: Icons.campaign_outlined,
                  isLoading: _isSavingAnnouncement,
                  onPressed: _saveAnnouncement,
                  gradient: AppColors.greenGlow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Image Gallery Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: AppColors.neonBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'WEBSITE PHOTO GALLERY',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage the dynamic photos displayed in your landing website gallery section.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                if (provider.gallery.isEmpty)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textMuted,
                            size: 36,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No custom photos uploaded yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Website will show standard default fitness cards.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.gallery.length,
                      itemBuilder: (context, idx) {
                        final imgBase64 = provider.gallery[idx];
                        ImageProvider imageProvider;
                        try {
                          if (imgBase64.startsWith('data:image')) {
                            final base64Str = imgBase64.split(',').last;
                            imageProvider = MemoryImage(
                              base64Decode(base64Str),
                            );
                          } else {
                            imageProvider = NetworkImage(imgBase64);
                          }
                        } catch (_) {
                          imageProvider = const NetworkImage(
                            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500',
                          );
                        }

                        return Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (c, o, s) => const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: AppColors.neonRed,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.surface,
                                        title: const Text(
                                          'Delete Photo?',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to remove this photo from the website gallery?',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text(
                                              'CANCEL',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text(
                                              'DELETE',
                                              style: TextStyle(
                                                color: AppColors.neonRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      provider.removeGalleryImage(idx);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_forever,
                                      color: AppColors.neonRed,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                NeonButton(
                  text: 'UPLOAD NEW PHOTO',
                  icon: Icons.add_photo_alternate_outlined,
                  isLoading: _isUploadingPhoto,
                  onPressed: _pickAndUploadImage,
                  gradient: AppColors.cyberGlow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Gym Video Clips Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      color: AppColors.neonAmber,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'GYM VIDEOS / SHORTS',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add YouTube Shorts or Instagram Reels links to display motivational workout clips directly on the website.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Add Video Link',
                  hint: 'e.g. https://www.youtube.com/shorts/...',
                  prefixIcon: Icons.link,
                  controller: _videoController,
                ),
                const SizedBox(height: 16),
                NeonButton(
                  text: 'ADD VIDEO LINK',
                  icon: Icons.add,
                  isLoading: _isAddingVideo,
                  onPressed: _saveVideoLink,
                  gradient: AppColors.warningGlow,
                ),
                if (provider.videos.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'CURRENT ACTIVE VIDEOS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.videos.length,
                    itemBuilder: (context, idx) {
                      final videoUrl = provider.videos[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.video_library_outlined,
                            color: AppColors.neonAmber,
                          ),
                          title: Text(
                            videoUrl,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.neonRed,
                              size: 18,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text(
                                    'Delete Video?',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to remove this video link?',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text(
                                        'CANCEL',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'DELETE',
                                        style: TextStyle(
                                          color: AppColors.neonRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                provider.removeVideoLink(idx);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Gym Contact Details Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.contact_mail,
                      color: AppColors.neonBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'GYM CONTACT DETAILS',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage the location address, support email, and phone number displayed on your gym landing page.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Gym Location / Address',
                  hint: 'e.g. Opposite High Court Lane, Sector 4, New Delhi',
                  prefixIcon: Icons.location_on_outlined,
                  controller: _addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Gym Contact Phone Number',
                  hint: 'e.g. 9876543210',
                  prefixIcon: Icons.phone_android_outlined,
                  controller: _phoneController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Gym Support Email',
                  hint: 'e.g. contact@musclesup.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                ),
                const SizedBox(height: 24),
                NeonButton(
                  text: 'SAVE CONTACT DETAILS',
                  icon: Icons.check,
                  isLoading: _isSavingContact,
                  onPressed: _saveContactInfo,
                  gradient: AppColors.cyberGlow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Gym Subscription Plans Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: AppColors.neonGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'GYM SUBSCRIPTION PLANS',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage the active gym pricing options. Create, highlight or delete membership cards live.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                if (provider.plans.isEmpty)
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No pricing plans active yet. Default pricing will be loaded.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.plans.length,
                    itemBuilder: (context, idx) {
                      final plan = provider.plans[idx];
                      final name = plan['name'] ?? '';
                      final price = plan['price'] ?? '';
                      final period = plan['period'] ?? '';
                      final badge = plan['badge'];
                      final isFeatured = plan['isFeatured'] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isFeatured
                              ? AppColors.neonBlue.withOpacity(0.05)
                              : Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFeatured
                                ? AppColors.neonBlue
                                : AppColors.border,
                            width: isFeatured ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isFeatured) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.star,
                                          color: AppColors.neonBlue,
                                          size: 16,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$price$period',
                                    style: const TextStyle(
                                      color: AppColors.neonGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonBlue.withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        badge,
                                        style: const TextStyle(
                                          color: AppColors.neonBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.neonBlue,
                                    size: 20,
                                  ),
                                  onPressed: () => _showPlanDialog(editIndex: idx),
                                ),
                                const SizedBox(height: 6),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.neonRed,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.surface,
                                        title: const Text(
                                          'Delete Plan?',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to remove this pricing plan from the landing page?',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text(
                                              'CANCEL',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text(
                                              'DELETE',
                                              style: TextStyle(
                                                color: AppColors.neonRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      provider.removePlan(idx);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                NeonButton(
                  text: 'ADD NEW PLAN',
                  icon: Icons.add_circle_outline,
                  onPressed: () => _showPlanDialog(),
                  gradient: AppColors.greenGlow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: USER WEBSITE INQUIRIES LIST
  Widget _buildInquiriesTab(WebsiteProvider provider) {
    final inquiries = provider.inquiries;

    if (inquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_ind_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No inquiries recorded yet!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Submitted website leads will populate here.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.fetchInquiries,
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonBlue,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchInquiries,
      color: AppColors.neonBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inquiries.length,
        itemBuilder: (ctx, idx) {
          final item = inquiries[idx];
          return _buildInquiryCard(item, provider);
        },
      ),
    );
  }

  // Sub-Widget for a single inquiry card
  Widget _buildInquiryCard(InquiryModel item, WebsiteProvider provider) {
    Color statusColor;
    switch (item.status) {
      case 'joined':
        statusColor = AppColors.neonGreen;
        break;
      case 'contacted':
        statusColor = AppColors.neonBlue;
        break;
      default:
        statusColor = AppColors.neonRed;
    }

    // Parse date beautifully
    String dateStr = item.createdAt;
    try {
      final parsed = DateTime.parse(item.createdAt).toLocal();
      dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    } catch (_) {}

    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Submitter Info & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Selected plan
            Row(
              children: [
                const Icon(
                  Icons.bookmark_outline,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Chosen Plan: ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.packageName,
                  style: const TextStyle(
                    color: AppColors.neonBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 3: Submitter phone number
            Row(
              children: [
                const Icon(
                  Icons.phone_android,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  item.phone,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Message text container
            if (item.message != null && item.message!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: Text(
                  item.message!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Date Text
            Text(
              'Inquiry Date: $dateStr',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const Divider(color: AppColors.border, height: 24),

            // Interactive action buttons
            Row(
              children: [
                // Call Dialer Button
                IconButton(
                  onPressed: () => _makeCall(item.phone),
                  icon: const Icon(
                    Icons.phone_in_talk,
                    color: AppColors.neonBlue,
                  ),
                  tooltip: 'Call Submitter',
                ),
                const SizedBox(width: 8),

                // WhatsApp Messenger Button
                IconButton(
                  onPressed: () =>
                      _sendWhatsApp(item.phone, item.name, item.packageName),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.neonGreen,
                  ),
                  tooltip: 'WhatsApp Invitation',
                ),
                const Spacer(),

                // Change status popup menu
                PopupMenuButton<String>(
                  color: AppColors.surface,
                  tooltip: 'Change Lead Status',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Update Status',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'delete') {
                      _showDeleteConfirmation(item.id, provider);
                    } else {
                      provider.changeInquiryStatus(item.id, val);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text(
                        'Mark Pending',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'contacted',
                      child: Text(
                        'Mark Contacted',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'joined',
                      child: Text(
                        'Mark Joined/Closed',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Inquiry',
                        style: TextStyle(color: AppColors.neonRed),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Confirmation modal alert
  void _showDeleteConfirmation(String id, WebsiteProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Inquiry?'),
          content: const Text(
            'Are you sure you want to permanently delete this website lead? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                provider.removeInquiry(id);
                Navigator.pop(ctx);
              },
              child: const Text(
                'DELETE',
                style: TextStyle(color: AppColors.neonRed),
              ),
            ),
          ],
        );
      },
    );
  }
}
