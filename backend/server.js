import 'dotenv/config'; // This MUST be the very first line!
import express from "express";
import cors from "cors"; // <-- 1. ADDED CORS IMPORT
import { createServer as createViteServer } from "vite";
import path from "path";
import { fileURLToPath } from "url";
import apiRoutes from './server/routes.js';
import { connectDB } from './server/db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  // Uses environment PORT if available, otherwise defaults to 3000
  const PORT = process.env.PORT || 3000;

  console.log("Starting LakbAi server...");

  // Connect to MongoDB
  await connectDB();

  // <-- 2. ADDED CORS MIDDLEWARE HERE BEFORE express.json()
  app.use(cors());

  // Middleware to parse incoming JSON payloads
  app.use(express.json({ limit: '10mb' }));

  // API Routes
  // This automatically prefixes all endpoints in routes.js with '/api'
  app.use("/api", apiRoutes);

  // Vite middleware for development vs static files for production
  const isProd = process.env.NODE_ENV === "production";
  
  if (!isProd) {
    console.log("Development mode: Initializing Vite middleware...");
    const vite = await createViteServer({
      server: { 
        middlewareMode: true,
        host: '0.0.0.0',
        port: PORT
      },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    console.log("Production mode: Serving static files...");
    const distPath = path.join(process.cwd(), "dist");
    
    // Serve static assets
    app.use(express.static(distPath));
    
    // Catch-all route to serve index.html for Single Page Application (SPA) routing
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`LakbAi Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer().catch((err) => {
  console.error("Failed to start server:", err);
  process.exit(1);
});