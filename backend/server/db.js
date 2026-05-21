import mongoose from 'mongoose';

export const connectDB = async () => {
  try {
    const uri = process.env.MONGODB_URI;
    if (!uri) {
      console.warn("MONGODB_URI not found in environment variables. Database features may be limited.");
      return;
    }
    await mongoose.connect(uri);
    console.log("MongoDB Atlas connected successfully");
  } catch (err) {
    console.error("MongoDB connection error:", err);
  }
};
