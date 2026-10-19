const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment configuration keys
dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

// Establish Cloud Connection to MongoDB Atlas Mumbai Cluster
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected safely to MongoDB Atlas (Mumbai)'))
  .catch((err) => console.error('❌ MongoDB Atlas connection error:', err));

// Schema Definition mapping to your active "users" collection
const userSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true },
  email: { type: String, required: true },
  displayName: { type: String },
  photoUrl: { type: String },
  createdAt: { type: Date, default: Date.now }
}, { collection: 'users' });

const User = mongoose.model('User', userSchema);

// Sync Endpoint called by AuthWrapper's post-frame callback handler
app.post('/api/users', async (req, res) => {
  try {
    const { uid, email, displayName, photoUrl } = req.body;
    
    const updatedUser = await User.findOneAndUpdate(
      { uid },
      { email, displayName, photoUrl },
      { new: true, upsert: true }
    );
    
    res.status(200).json({ message: 'Profile synced smoothly.', user: updatedUser });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 API Server running smoothly on port ${PORT}`));
