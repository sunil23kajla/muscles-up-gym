const { Payment, Member } = require('../models');
const { Op } = require('sequelize');

// Enter manual payment
exports.createPayment = async (req, res) => {
  const { memberId, amount, paymentDate, notes } = req.body;

  try {
    const member = await Member.findByPk(memberId);
    if (!member) {
      return res.status(404).json({ message: 'Member not found.' });
    }

    const todayStr = new Date().toISOString().split('T')[0];
    if (paymentDate && paymentDate > todayStr) {
      return res.status(400).json({ message: 'Payment date cannot be in the future.' });
    }

    const payment = await Payment.create({
      memberId,
      amount,
      paymentDate: paymentDate || new Date().toISOString().split('T')[0],
      notes,
    });

    res.status(201).json(payment);
  } catch (error) {
    res.status(500).json({ message: 'Failed to record payment.', error: error.message });
  }
};

// Retrieve payment log history
exports.getAllPayments = async (req, res) => {
  try {
    const payments = await Payment.findAll({
      include: [{ model: Member, as: 'member', attributes: ['name', 'phone', 'photo'] }],
      order: [['paymentDate', 'DESC'], ['createdAt', 'DESC']],
    });
    res.json(payments);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch payment history.', error: error.message });
  }
};

// Financial reports breakdowns (daily, monthly, yearly)
exports.getFinancialReports = async (req, res) => {
  try {
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];
    
    // Start of current month
    const startOfMonthStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-01`;
    
    // Start of current year
    const startOfYearStr = `${today.getFullYear()}-01-01`;

    // 1. Get Today's collection
    const todayPayments = await Payment.findAll({
      where: { paymentDate: todayStr }
    });
    const todayTotal = todayPayments.reduce((sum, p) => sum + p.amount, 0);

    // 2. Get Month's collection
    const monthlyPayments = await Payment.findAll({
      where: {
        paymentDate: {
          [Op.gte]: startOfMonthStr,
          [Op.lte]: todayStr,
        },
      },
    });
    const monthlyTotal = monthlyPayments.reduce((sum, p) => sum + p.amount, 0);

    // 3. Get Year's collection
    const yearlyPayments = await Payment.findAll({
      where: {
        paymentDate: {
          [Op.gte]: startOfYearStr,
          [Op.lte]: todayStr,
        },
      },
    });
    const yearlyTotal = yearlyPayments.reduce((sum, p) => sum + p.amount, 0);

    // 4. Generate daily history for the current month for chart mapping in Flutter
    const dailyBreakdown = {};
    monthlyPayments.forEach(p => {
      dailyBreakdown[p.paymentDate] = (dailyBreakdown[p.paymentDate] || 0) + p.amount;
    });

    const dailyChartData = Object.keys(dailyBreakdown).map(date => ({
      date,
      amount: dailyBreakdown[date],
    })).sort((a, b) => a.date.localeCompare(b.date));

    res.json({
      summary: {
        today: todayTotal,
        monthly: monthlyTotal,
        yearly: yearlyTotal,
      },
      dailyChartData,
      monthlyPaymentsCount: monthlyPayments.length,
      yearlyPaymentsCount: yearlyPayments.length,
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to generate financial reports.', error: error.message });
  }
};
