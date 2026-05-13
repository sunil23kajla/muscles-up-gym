const { Attendance, Member, Workout } = require('../models');

// 1. Mark Attendance for a member for today or a specific date
exports.markAttendance = async (req, res) => {
  const { memberId, date, status } = req.body;

  if (!memberId || !date || !status) {
    return res.status(400).json({ message: 'MemberId, date, and status are required.' });
  }

  try {
    const member = await Member.findByPk(memberId);
    if (!member) {
      return res.status(404).json({ message: 'Member not found.' });
    }

    // Check if attendance already marked for this date
    let attendance = await Attendance.findOne({ where: { memberId, date } });

    if (attendance) {
      attendance.status = status;
      await attendance.save();
    } else {
      attendance = await Attendance.create({ memberId, date, status });
    }

    res.json({ message: 'Attendance marked successfully.', attendance });
  } catch (error) {
    res.status(500).json({ message: 'Failed to record attendance.', error: error.message });
  }
};

// 2. Fetch daily attendance overview by date
exports.getDailyAttendance = async (req, res) => {
  const { date } = req.query;

  if (!date) {
    return res.status(400).json({ message: 'Date query parameter is required (YYYY-MM-DD).' });
  }

  try {
    // We want to fetch all active members, and join their attendance record for this date (if any)
    const members = await Member.findAll({
      where: { status: 'active' },
      attributes: ['id', 'name', 'phone', 'photo'],
      include: [{
        model: Attendance,
        as: 'attendance',
        where: { date },
        required: false, // LEFT JOIN
      }],
    });

    const report = members.map(member => {
      const attendanceRecord = member.attendance && member.attendance[0];
      return {
        id: member.id,
        name: member.name,
        phone: member.phone,
        photo: member.photo,
        status: attendanceRecord ? attendanceRecord.status : 'unmarked', // 'present', 'absent' or 'unmarked'
      };
    });

    res.json(report);
  } catch (error) {
    res.status(500).json({ message: 'Failed to retrieve attendance logs.', error: error.message });
  }
};

// 3. Assign/Update Workout plan for a member
exports.assignWorkoutPlan = async (req, res) => {
  const { memberId, planName, details } = req.body; // Details can be a JSON string of structure

  try {
    const member = await Member.findByPk(memberId);
    if (!member) {
      return res.status(404).json({ message: 'Member not found.' });
    }

    let workout = await Workout.findOne({ where: { memberId } });

    if (workout) {
      workout.planName = planName || workout.planName;
      workout.details = details !== undefined ? details : workout.details;
      await workout.save();
    } else {
      workout = await Workout.create({ memberId, planName, details });
    }

    res.json({ message: 'Workout plan updated successfully.', workout });
  } catch (error) {
    res.status(500).json({ message: 'Failed to assign workout plan.', error: error.message });
  }
};

// 4. Get Workout plan for a member
exports.getWorkoutPlan = async (req, res) => {
  const { memberId } = req.params;

  try {
    const workout = await Workout.findOne({ where: { memberId } });
    if (!workout) {
      return res.json(null); // Return empty plan
    }
    res.json(workout);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch workout plan.', error: error.message });
  }
};
