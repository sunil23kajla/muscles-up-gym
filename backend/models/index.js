const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

// 1. User Model (Auth, Admins, and Staff Request Approvals)
const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  role: {
    type: DataTypes.ENUM('admin', 'staff'),
    defaultValue: 'staff',
  },
  status: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected'),
    defaultValue: 'pending',
  },
});

// 2. Member Model
const Member = sequelize.define('Member', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  photo: {
    type: DataTypes.TEXT, // Base64 encoding for simplicity of storing images locally
    allowNull: true,
  },
  height: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  weight: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  bloodGroup: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  subscriptionStart: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  subscriptionEnd: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  plan: {
    type: DataTypes.STRING,
    allowNull: true,
    defaultValue: '1 Month',
  },
  status: {
    type: DataTypes.ENUM('active', 'expired', 'pending'),
    defaultValue: 'pending',
  },
});

// 3. Payment Model
const Payment = sequelize.define('Payment', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  amount: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
  paymentDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  notes: {
    type: DataTypes.STRING,
    allowNull: true,
  },
});

// 4. Attendance Model
const Attendance = sequelize.define('Attendance', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  date: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('present', 'absent'),
    defaultValue: 'present',
  },
});

// 5. Workout Model (Workout plans per member)
const Workout = sequelize.define('Workout', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  planName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  details: {
    type: DataTypes.TEXT, // Stored as serialized JSON details (list of exercises, sets, reps)
    allowNull: true,
  },
});

// 6. Inquiry Model (Website inquiries / Leads)
const Inquiry = sequelize.define('Inquiry', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  packageName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('pending', 'contacted', 'joined'),
    defaultValue: 'pending',
  },
});

// 7. WebsiteSetting Model (Dynamic configs like announcement banner, counters, videos, gallery images)
const WebsiteSetting = sequelize.define('WebsiteSetting', {
  key: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    primaryKey: true,
  },
  value: {
    type: DataTypes.TEXT, // JSON Stringified configurations
    allowNull: false,
  },
});

// Relationships Setup
Member.hasMany(Payment, { foreignKey: 'memberId', as: 'payments', onDelete: 'CASCADE' });
Payment.belongsTo(Member, { foreignKey: 'memberId', as: 'member' });

Member.hasMany(Attendance, { foreignKey: 'memberId', as: 'attendance', onDelete: 'CASCADE' });
Attendance.belongsTo(Member, { foreignKey: 'memberId', as: 'member' });

Member.hasOne(Workout, { foreignKey: 'memberId', as: 'workout', onDelete: 'CASCADE' });
Workout.belongsTo(Member, { foreignKey: 'memberId', as: 'member' });

module.exports = {
  sequelize,
  User,
  Member,
  Payment,
  Attendance,
  Workout,
  Inquiry,
  WebsiteSetting,
};
