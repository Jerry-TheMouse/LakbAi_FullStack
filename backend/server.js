import 'dotenv/config'; // This MUST be the very first line!
import express from "express";
import cors from "cors"; 
import path from "path";
import { fileURLToPath } from "url";
import apiRoutes from './server/routes.js';
import { connectDB } from './server/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const PORT = process.env.PORT || 3000;

  console.log("Starting LakbAi server...");

  // Connect to MongoDB
  await connectDB();

  app.use(cors());
  app.use(express.json({ limit: '10mb' }));

  // API Routes
  app.use("/api", apiRoutes);

  // --- THE FIX FOR LOCALHOST:3000 WHITE SCREEN ---
  // We removed the old React 'Vite' server. Now, if you visit the backend URL directly,
  // it will show a friendly LakbAi API status page instead of a broken white screen!
  app.get("/", (req, res) => {
    res.send(`
      <html>
        <head>
          <title>LakbAi API Server</title>
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #ECFDF5; color: #064E3B; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; }
            .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); text-align: center; border: 2px solid #34D399; max-width: 500px; }
            h1 { margin-top: 0; color: #059669; font-size: 28px; }
            p { font-size: 16px; color: #064E3B; line-height: 1.5; }
            .badge { background: #D1FAE5; color: #059669; padding: 8px 16px; border-radius: 20px; font-weight: bold; display: inline-block; margin-top: 20px; }
          </style>
        </head>
        <body>
          <div class="card">
            <h1>🌿 LakbAi Backend API</h1>
            <p>The Node.js & MongoDB Server is <strong>Online and Running!</strong></p>
            <p>This server handles data for the LakbAi Flutter Mobile Application. It processes AI Itineraries, manages destinations, and handles offline syncing.</p>
            <div class="badge">API Status: Active</div>
          </div>
        </body>
      </html>
    `);
  });

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`LakbAi Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer().catch((err) => {
  console.error("Failed to start server:", err);
  process.exit(1);
});