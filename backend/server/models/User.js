import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['tourist', 'tourism_office', 'admin'], default: 'tourist' },
  region: { 
    type: String, 
    enum: ['Luzon', 'Visayas', 'Mindanao', null] 
  },
  contactNumber: { type: String },
  createdAt: { type: Date, default: Date.now }
});

// Hash password before saving - Fixed to ensure 'next' is always valid
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  try {
    this.password = await bcrypt.hash(this.password, 10);
    next();
  } catch (err) {
    // If an error occurs, pass it to next instead of crashing
    next(err);
  }
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

export const User = mongoose.model('User', userSchema);