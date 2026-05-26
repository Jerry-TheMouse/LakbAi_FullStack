import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['tourist', 'tourism_office', 'admin'], default: 'tourist' },
  region: { 
    type: String, 
    enum: ['Luzon', 'Visayas', 'Mindanao', null],
    default: 'Luzon'
  },
<<<<<<< HEAD
  contactNumber: { type: String, default: '' }, // Added for Tourism Office
  createdAt: { type: Date, default: Date.now }
});

// FIX 1: Removed 'next' parameter. Modern Mongoose handles async saves automatically.
=======
  contactNumber: { type: String, default: '' }, 
  tawiTawiId: { type: String, unique: true, sparse: true }, // NEW FIELD FOR SSO
  createdAt: { type: Date, default: Date.now }
});

>>>>>>> bc09327 (change something)
userSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

<<<<<<< HEAD
// FIX 2: Ensure comparePassword is bound correctly to the schema methods
=======
>>>>>>> bc09327 (change something)
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

export const User = mongoose.model('User', userSchema);