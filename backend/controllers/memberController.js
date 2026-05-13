const { Member, Payment, Attendance, Workout } = require('../models');
const { Op } = require('sequelize');

// Helper to auto-recalculate and save status based on current date
const autoRecalculateStatus = (member) => {
  const todayStr = new Date().toISOString().split('T')[0];
  const start = member.subscriptionStart;
  const end = member.subscriptionEnd;

  let computedStatus = 'active';
  if (todayStr < start) {
    computedStatus = 'pending';
  } else if (todayStr > end) {
    computedStatus = 'expired';
  }

  if (member.status !== computedStatus) {
    member.status = computedStatus;
  }
  return member;
};

// Create Member
exports.createMember = async (req, res) => {
  const { name, phone, photo, height, weight, bloodGroup, subscriptionStart, subscriptionEnd, plan } = req.body;

  try {
    const member = Member.build({
      name,
      phone,
      photo,
      height,
      weight,
      bloodGroup,
      subscriptionStart,
      subscriptionEnd,
      plan: plan || '1 Month',
    });

    autoRecalculateStatus(member);
    await member.save();

    res.status(201).json(member);
  } catch (error) {
    res.status(500).json({ message: 'Failed to create member.', error: error.message });
  }
};


exports.getAllMembers = async (req, res) => {
  const { status, search } = req.query;

  try {
    let whereClause = {};

    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { phone: { [Op.like]: `%${search}%` } }
      ];
    }

    const members = await Member.findAll({ where: whereClause });

    // Auto update status on load to ensure accuracy
    const updatedMembers = [];
    for (const member of members) {
      const originalStatus = member.status;
      autoRecalculateStatus(member);
      if (member.changed('status')) {
        await member.save();
      }

      // Filter if status query is provided
      if (!status || member.status === status) {
        updatedMembers.push(member);
      }
    }

    res.json(updatedMembers);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch members.', error: error.message });
  }
};

// Get Single Member Details
exports.getMemberById = async (req, res) => {
  try {
    const member = await Member.findByPk(req.params.id, {
      include: [
        { model: Payment, as: 'payments' },
        { model: Attendance, as: 'attendance' },
        { model: Workout, as: 'workout' }
      ]
    });

    if (!member) {
      return res.status(404).json({ message: 'Member not found.' });
    }

    // Auto-recalculate status
    autoRecalculateStatus(member);
    if (member.changed('status')) {
      await member.save();
    }

    res.json(member);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch member details.', error: error.message });
  }
};

// Update Member
exports.updateMember = async (req, res) => {
  const { name, phone, photo, height, weight, bloodGroup, subscriptionStart, subscriptionEnd, plan } = req.body;

  try {
    const member = await Member.findByPk(req.params.id);
    if (!member) {
      return res.status(404).json({ message: 'Member not found.' });
    }

    member.name = name || member.name;
    member.phone = phone || member.phone;
    if (photo !== undefined) member.photo = photo;
    member.height = height !== undefined ? height : member.height;
    member.weight = weight !== undefined ? weight : member.weight;
    member.bloodGroup = bloodGroup !== undefined ? bloodGroup : member.bloodGroup;
    member.subscriptionStart = subscriptionStart || member.subscriptionStart;
    member.subscriptionEnd = subscriptionEnd || member.subscriptionEnd;
    if (plan !== undefined) member.plan = plan;

    autoRecalculateStatus(member);
    await member.save();

    res.json(member);
  } catch (error) {
    res.status(500).json({ message: 'Failed to update member.', error: error.message });
  }
};

// Delete Member
exports.deleteMember = async (req, res) => {
  try {
    const member = await Member.findByPk(req.params.id);
    if (!member) {
      return res.status(404).json({ message: 'Member not found.' });
    }

    await member.destroy();
    res.json({ message: 'Member deleted successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete member.', error: error.message });
  }
};

// Subscriptions expiring in next 10 days
exports.getUpcomingExpiries = async (req, res) => {
  try {
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];

    const tenDaysLater = new Date();
    tenDaysLater.setDate(today.getDate() + 10);
    const tenDaysLaterStr = tenDaysLater.toISOString().split('T')[0];

    // Find members whose subscriptionEnd lies between today and today + 10 days
    const members = await Member.findAll({
      where: {
        subscriptionEnd: {
          [Op.between]: [todayStr, tenDaysLaterStr],
        },
      },
      order: [['subscriptionEnd', 'ASC']],
    });

    // Make sure status is active/accurate
    for (const member of members) {
      autoRecalculateStatus(member);
      if (member.changed('status')) {
        await member.save();
      }
    }

    res.json(members);
  } catch (error) {
    res.status(500).json({ message: 'Failed to retrieve upcoming expiries.', error: error.message });
  }
};

// Expired members
exports.getExpiredMembers = async (req, res) => {
  try {
    const todayStr = new Date().toISOString().split('T')[0];

    const members = await Member.findAll({
      where: {
        subscriptionEnd: {
          [Op.lt]: todayStr,
        },
      },
      order: [['subscriptionEnd', 'DESC']],
    });

    for (const member of members) {
      autoRecalculateStatus(member);
      if (member.changed('status')) {
        await member.save();
      }
    }

    res.json(members);
  } catch (error) {
    res.status(500).json({ message: 'Failed to retrieve expired members.', error: error.message });
  }
};
