const { WebsiteSetting } = require('../models');

// Helper to get or create a setting with fallback default value
async function getOrCreateSetting(key, defaultValue) {
  try {
    let setting = await WebsiteSetting.findByPk(key);
    if (!setting) {
      setting = await WebsiteSetting.create({
        key,
        value: JSON.stringify(defaultValue),
      });
    }
    return JSON.parse(setting.value);
  } catch (_) {
    return defaultValue;
  }
}

// Default Configurations
const DEFAULT_CONFIGS = {
  announcement: {
    show: true,
    text: '🔥 SUMMER SPEC-OPS OFFER: Enroll on a 1-Year Membership today and get 2 Months of personal training absolutely FREE!',
  },
  stats: {
    membersTrained: '1,500+',
    certifiedTrainers: '8+',
    yearsExp: '5+',
  },
  gallery: [], // Base64 images array or paths
  videos: [], // YouTube Shorts / embed video links
  plans: [
    {
      name: "MONTHLY CARDIO & WEIGHTS",
      price: "₹1,500",
      period: "/month",
      features: [
        "Access to Weight Floor",
        "Free Locker Access",
        "General Trainer Guidance"
      ],
      badge: "Standard",
      isFeatured: false
    },
    {
      name: "6-MONTHS PRO-FITNESS",
      price: "₹7,500",
      period: "/6 months",
      features: [
        "All Weight Floor access",
        "Free locker & showers",
        "2 Free body scans",
        "Personalized Workout Draft"
      ],
      badge: "Best Value",
      isFeatured: true
    },
    {
      name: "1-YEAR VIP MUSCLE UP",
      price: "₹12,000",
      period: "/year",
      features: [
        "24/7 Premium Gym Access",
        "Free locker, steam & sauna",
        "Monthly Dietitian checks",
        "1 Personal Coach slot",
        "Exclusive VIP Lounge access"
      ],
      badge: "Premium",
      isFeatured: false
    }
  ],
  contact: {
    address: "Opposite High Court Lane, Sector 4, New Delhi",
    phone: "9876543210",
    email: "support@musclesup.com"
  }
};

// 1. Get Website Configuration (Public - Landing page)
exports.getWebsiteConfig = async (req, res) => {
  try {
    const announcement = await getOrCreateSetting('announcement', DEFAULT_CONFIGS.announcement);
    const stats = await getOrCreateSetting('stats', DEFAULT_CONFIGS.stats);
    const gallery = await getOrCreateSetting('gallery', DEFAULT_CONFIGS.gallery);
    const videos = await getOrCreateSetting('videos', DEFAULT_CONFIGS.videos);
    const plans = await getOrCreateSetting('plans', DEFAULT_CONFIGS.plans);
    const contact = await getOrCreateSetting('contact', DEFAULT_CONFIGS.contact);

    res.json({
      announcement,
      stats,
      gallery,
      videos,
      plans,
      contact,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to retrieve website settings.', error: error.message });
  }
};

// 2. Update Website Setting (Admin only)
exports.updateWebsiteSetting = async (req, res) => {
  const { key, value } = req.body;

  if (!key || value === undefined) {
    return res.status(400).json({ message: 'Key and Value are required.' });
  }

  const allowedKeys = ['announcement', 'stats', 'gallery', 'videos', 'plans', 'contact'];
  if (!allowedKeys.includes(key)) {
    return res.status(400).json({ message: 'Invalid configuration key.' });
  }

  try {
    let setting = await WebsiteSetting.findByPk(key);
    if (!setting) {
      setting = await WebsiteSetting.create({
        key,
        value: JSON.stringify(value),
      });
    } else {
      setting.value = JSON.stringify(value);
      await setting.save();
    }

    res.json({ message: 'Website configuration updated successfully!', key, value });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update website configuration.', error: error.message });
  }
};
