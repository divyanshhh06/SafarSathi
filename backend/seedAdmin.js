require('dotenv').config();

const bcrypt = require('bcryptjs');
const connectDB = require('./db');
const Admin = require('./models/Admin');

const seedAdmin = async () => {
  try {
    await connectDB();

    const passwordHash = await bcrypt.hash('SafarSathi@123', 10);

    const existingAdmin = await Admin.findOne({
      username: 'admin'
    });

    if (existingAdmin) {
      console.log('Admin already exists');
      process.exit(0);
    }

    await Admin.create({
      username: 'admin',
      passwordHash
    });

    console.log('Admin created successfully');
    console.log('Username: admin');
    console.log('Password: SafarSathi@123');

    process.exit(0);
  } catch (error) {
    console.error('Admin seed failed:', error.message);
    process.exit(1);
  }
};

seedAdmin();