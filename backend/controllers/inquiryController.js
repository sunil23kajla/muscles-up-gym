const { Inquiry } = require('../models');

// 1. Submit a new Inquiry (Public - Landing Website)
exports.createInquiry = async (req, res) => {
  const { name, phone, packageName, message } = req.body;

  if (!name || !phone || !packageName) {
    return res.status(400).json({ message: 'Name, Phone, and Package choice are required.' });
  }

  // Verify phone number is exactly 10 digits
  const cleanPhone = phone.replace(/\D/g, '');
  if (cleanPhone.length !== 10) {
    return res.status(400).json({ message: 'Please enter a valid 10-digit phone number.' });
  }

  try {
    const inquiry = await Inquiry.create({
      name: name.trim(),
      phone: cleanPhone,
      packageName,
      message: message ? message.trim() : null,
    });
    res.status(201).json({ message: 'Inquiry submitted successfully!', inquiry });
  } catch (error) {
    res.status(500).json({ message: 'Failed to submit inquiry.', error: error.message });
  }
};

// 2. Get All Inquiries (Admin/Staff only)
exports.getAllInquiries = async (req, res) => {
  try {
    const inquiries = await Inquiry.findAll({
      order: [['createdAt', 'DESC']],
    });
    res.json(inquiries);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch inquiries.', error: error.message });
  }
};

// 3. Update Inquiry Status (Admin/Staff only)
exports.updateInquiryStatus = async (req, res) => {
  const { status } = req.body;
  const validStatuses = ['pending', 'contacted', 'joined'];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({ message: 'Invalid inquiry status.' });
  }

  try {
    const inquiry = await Inquiry.findByPk(req.params.id);
    if (!inquiry) {
      return res.status(404).json({ message: 'Inquiry not found.' });
    }

    inquiry.status = status;
    await inquiry.save();
    res.json({ message: 'Inquiry status updated successfully.', inquiry });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update status.', error: error.message });
  }
};

// 4. Delete Inquiry (Admin only)
exports.deleteInquiry = async (req, res) => {
  try {
    const inquiry = await Inquiry.findByPk(req.params.id);
    if (!inquiry) {
      return res.status(404).json({ message: 'Inquiry not found.' });
    }

    await inquiry.destroy();
    res.json({ message: 'Inquiry deleted successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete inquiry.', error: error.message });
  }
};
