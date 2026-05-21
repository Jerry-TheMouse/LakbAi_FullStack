import express from 'express';
import jwt from 'jsonwebtoken';
import { User } from './models/User.js';
import { Destination, Itinerary } from './models/Data.js';
import { GoogleGenAI } from "@google/genai";

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

// Middleware to verify JWT
const authenticate = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Unauthorized' });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.id).select('-password');
    if (!user) return res.status(401).json({ message: 'User not found' });
    
    req.user = user;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Invalid token' });
  }
};

// ==========================================
// AUTH ROUTES
// ==========================================
router.post('/auth/signup', async (req, res) => {
  const { name, email, password, role, region, contactNumber } = req.body;
  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: 'Email already exists' });

    const adminEmail = process.env.VITE_ADMIN_EMAIL;
    const finalRole = email.toLowerCase() === adminEmail?.toLowerCase() ? 'admin' : role;

    const user = new User({ name, email, password, role: finalRole, region, contactNumber });
    await user.save();

    const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user: { id: user._id, name, email, role: finalRole, region, contactNumber } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user._id, name: user.name, email: user.email, role: user.role, region: user.region, contactNumber: user.contactNumber } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/auth/me', authenticate, (req, res) => {
  res.json(req.user);
});

// ==========================================
// GEMINI ROUTE (LIVE STREAMING)
// ==========================================
router.post('/generate-itinerary', authenticate, async (req, res) => {
  const { destination, days, budget, interests } = req.body;
  if (!GEMINI_API_KEY) {
    return res.status(400).write("Error: Please add your GEMINI_API_KEY to your .env file.");
  }

  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.setHeader('Transfer-Encoding', 'chunked');

  try {
    const ai = new GoogleGenAI({ apiKey: GEMINI_API_KEY });
    const responseStream = await ai.models.generateContentStream({
      model: "gemini-2.5-flash",
      contents: `You are an expert travel planner. Create a detailed day-by-day itinerary for ${destination} for ${days} days. Budget level: ${budget}. Interests: ${interests.join(", ")}. Use standard Markdown format for structure.`,
    });

    for await (const chunk of responseStream) {
      if (chunk.text) {
        res.write(chunk.text);
      }
    }
    res.end();
  } catch (err) {
    console.error(err);
    res.write("\n\nFailed to complete the itinerary generation.");
    res.end();
  }
});

// ==========================================
// DATA ROUTES (DESTINATIONS)
// ==========================================
router.get('/destinations', async (req, res) => {
  try {
    const destinations = await Destination.find({ status: 'approved' }).sort({ createdAt: -1 });
    res.json(destinations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/destinations/pending', authenticate, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Admin only' });
  try {
    const pending = await Destination.find({ status: 'pending' }).sort({ createdAt: -1 });
    res.json(pending);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/destinations', authenticate, async (req, res) => {
  if (req.user.role !== 'admin' && req.user.role !== 'tourism_office') {
    return res.status(403).json({ message: 'Forbidden' });
  }

  try {
    const status = req.user.role === 'admin' ? 'approved' : 'pending';
    const destination = new Destination({ 
      ...req.body, 
      status,
      submittedBy: { 
        name: req.user.name, 
        email: req.user.email,
        phone: req.user.contactNumber
      }
    });
    await destination.save();
    res.status(201).json(destination);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ==========================================
// RATE DESTINATION ROUTE
// ==========================================
router.post('/destinations/:id/rate', authenticate, async (req, res) => {
  try {
    const { rating } = req.body;
    const dest = await Destination.findById(req.params.id);
    
    if (!dest) return res.status(404).json({ message: 'Destination not found' });

    // Failsafe: Ensure the ratings array exists
    if (!dest.ratings) dest.ratings = [];

    // Check if this user already rated
    const existingRatingIndex = dest.ratings.findIndex(r => r.userId === req.user._id.toString());
    
    if (existingRatingIndex >= 0) {
      dest.ratings[existingRatingIndex].value = rating; // Update existing
    } else {
      dest.ratings.push({ userId: req.user._id.toString(), value: rating }); // Add new
    }
    
    await dest.save();
    res.json(dest);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/destinations/:id/approve', authenticate, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Admin only' });
  try {
    const updated = await Destination.findByIdAndUpdate(req.params.id, { status: 'approved' }, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/destinations/:id/reject', authenticate, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Admin only' });
  try {
    await Destination.findByIdAndDelete(req.params.id);
    res.json({ message: 'Rejected and deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/destinations/:id', authenticate, async (req, res) => {
  try {
    await Destination.findByIdAndDelete(req.params.id);
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/destinations/:id', authenticate, async (req, res) => {
  try {
    const updated = await Destination.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ==========================================
// ITINERARY ROUTES (CRUD)
// ==========================================
router.get('/itineraries', authenticate, async (req, res) => {
  try {
    const itineraries = await Itinerary.find({ userId: req.user._id }).sort({ createdAt: -1 });
    res.json(itineraries);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/itineraries', authenticate, async (req, res) => {
  try {
    const itinerary = new Itinerary({ ...req.body, userId: req.user._id });
    await itinerary.save();
    res.status(201).json(itinerary);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/itineraries/:id', authenticate, async (req, res) => {
  const { destination, days, budget, interests, content } = req.body; 
  try {
    const updatedItinerary = await Itinerary.findByIdAndUpdate(
      req.params.id,
      { destination, days, budget, interests, content },
      { new: true }
    );
    
    if (!updatedItinerary) return res.status(404).json({ message: 'Itinerary not found' });
    res.json(updatedItinerary);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/itineraries/:id', authenticate, async (req, res) => {
  try {
    await Itinerary.findByIdAndDelete(req.params.id);
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ==========================================
// MONGODB ANALYTICS
// ==========================================
router.get('/analytics', authenticate, async (req, res) => {
  if (req.user.role !== 'admin' && req.user.role !== 'tourism_office') {
    return res.status(403).json({ message: 'Forbidden' });
  }

  try {
    const isAdmin = req.user.role === 'admin';
    const targetRegion = isAdmin ? null : req.user.region;

    const destQuery = { status: 'approved' };
    if (targetRegion) destQuery.region = targetRegion;
    const activeDestinationsCount = await Destination.countDocuments(destQuery);

    const pendingQuery = { status: 'pending' };
    if (targetRegion) pendingQuery.region = targetRegion;
    const pendingDestinationsCount = await Destination.countDocuments(pendingQuery);

    const totalUsersCount = await User.countDocuments();

    let itineraryMatch = {};
    if (targetRegion) {
       const dests = await Destination.find({ region: targetRegion }).select('name');
       const destNames = dests.map(d => d.name);
       itineraryMatch = { destination: { $in: destNames } };
    }
    const totalItinerariesCount = await Itinerary.countDocuments(itineraryMatch);

    const topDestinationsAgg = await Itinerary.aggregate([
      { $match: itineraryMatch },
      { $group: { _id: "$destination", visitors: { $sum: 1 } } },
      { $sort: { visitors: -1 } },
      { $limit: 5 },
      { $project: { name: "$_id", visitors: 1, _id: 0 } }
    ]);

    const currentYear = new Date().getFullYear();
    const monthlyMatch = {
       ...itineraryMatch,
       createdAt: {
         $gte: new Date(`${currentYear}-01-01`),
         $lte: new Date(`${currentYear}-12-31`)
       }
    };

    const monthlyVisitsAgg = await Itinerary.aggregate([
      { $match: monthlyMatch },
      { $group: { _id: { $month: "$createdAt" }, visits: { $sum: 1 } } },
      { $sort: { "_id": 1 } }
    ]);

    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    let monthlyVisits = monthNames.map((month) => ({ month, visits: 0 }));
    let peakMonthValue = 0;
    let peakSeason = 'N/A';

    monthlyVisitsAgg.forEach(item => {
      const monthIndex = item._id - 1;
      monthlyVisits[monthIndex].visits = item.visits;
      if (item.visits > peakMonthValue) {
        peakMonthValue = item.visits;
        peakSeason = monthNames[monthIndex];
      }
    });

    const avgDaily = Math.ceil(totalItinerariesCount / 30) || 0;

    let destinationsByRegion = [];
    let destinationsByCategory = [];
    
    if (isAdmin) {
      destinationsByRegion = await Destination.aggregate([
        { $match: { status: 'approved' } },
        { $group: { _id: "$region", count: { $sum: 1 } } },
        { $project: { region: { $ifNull: ["$_id", "Unspecified"] }, count: 1, _id: 0 } }
      ]);

      destinationsByCategory = await Destination.aggregate([
        { $match: { status: 'approved' } },
        { $group: { _id: "$category", count: { $sum: 1 } } },
        { $project: { category: { $ifNull: ["$_id", "Uncategorized"] }, count: 1, _id: 0 } }
      ]);
    }

    res.json({
      stats: {
        totalVisitors: totalItinerariesCount.toString(),
        avgDaily: avgDaily.toString(),
        activeDestinations: activeDestinationsCount.toString(),
        peakSeason: peakSeason,
        pendingRequests: pendingDestinationsCount.toString(),
        totalUsers: totalUsersCount.toString()
      },
      monthlyVisits,
      topDestinations: topDestinationsAgg,
      destinationsByRegion,
      destinationsByCategory
    });

  } catch (err) {
    res.status(500).json({ message: 'Failed to load analytics data' });
  }
});

export default router;