const { Member, Payment } = require('../models');
const { Op } = require('sequelize');

exports.getDashboardStats = async (req, res) => {
  try {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    const todayStr = `${year}-${month}-${day}`;
    
    // Start of month & year
    const startOfMonthStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-01`;
    const startOfYearStr = `${today.getFullYear()}-01-01`;

    // 1. Total Members Counts
    const totalMembers = await Member.count();
    const activeMembers = await Member.count({ where: { status: 'active' } });
    const expiredMembers = await Member.count({ where: { status: 'expired' } });
    const pendingMembers = await Member.count({ where: { status: 'pending' } });

    // 2. Today's Admissions
    // Count only members whose subscription starts today (joining date)
    const newAdmissionsToday = await Member.count({
      where: {
        subscriptionStart: todayStr
      }
    });

    // 3. Collection totals (Today, Monthly, Yearly)
    const todayPayments = await Payment.findAll({
      where: { paymentDate: todayStr }
    });
    const todayCollection = todayPayments.reduce((sum, p) => sum + p.amount, 0);

    const monthlyPayments = await Payment.findAll({
      where: {
        paymentDate: {
          [Op.gte]: startOfMonthStr,
          [Op.lte]: todayStr,
        },
      },
    });
    const monthlyCollection = monthlyPayments.reduce((sum, p) => sum + p.amount, 0);

    const yearlyPayments = await Payment.findAll({
      where: {
        paymentDate: {
          [Op.gte]: startOfYearStr,
          [Op.lte]: todayStr,
        },
      },
    });
    const yearlyCollection = yearlyPayments.reduce((sum, p) => sum + p.amount, 0);

    // 4. Retrieve list of upcoming expirations (next 10 days) for quick dashboard widgets
    const tenDaysLater = new Date();
    tenDaysLater.setDate(today.getDate() + 10);
    const tenDaysLaterStr = tenDaysLater.toISOString().split('T')[0];

    const upcomingExpirationsCount = await Member.count({
      where: {
        subscriptionEnd: {
          [Op.between]: [todayStr, tenDaysLaterStr],
        },
      },
    });

    res.json({
      members: {
        total: totalMembers,
        active: activeMembers,
        expired: expiredMembers,
        pending: pendingMembers,
        newToday: newAdmissionsToday,
      },
      collections: {
        today: todayCollection,
        monthly: monthlyCollection,
        yearly: yearlyCollection,
      },
      alerts: {
        upcomingExpirations: upcomingExpirationsCount,
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to aggregate dashboard metrics.', error: error.message });
  }
};
