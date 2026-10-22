import { PORT } from "./config.js";
import express from "express";
import cookieParser from "cookie-parser";
import cors from "cors";
import mongoose from "mongoose";
import { connectDB } from "./db.js";
import authRoutes from "./routes/auth.js";
import dataRoutes from "./routes/data.js";
import geminiRoutes from "./routes/gemini.js";

const app = express();
app.set("trust proxy", 1);
app.disable("x-powered-by");
// The Flutter app authenticates with a Bearer token (no cookies), so any origin may call the API.
app.use("/api", cors({ origin: process.env.CORS_ORIGIN || "*" }));
app.use(express.json({ limit: "1mb" }));
app.use(cookieParser());

app.get("/api/health", (_req, res) => {
  res.json({ ok: true, db: mongoose.connection.readyState === 1 ? "connected" : "disconnected" });
});

app.use("/api/auth", authRoutes);
app.use("/api/gemini", geminiRoutes);
app.use("/api", dataRoutes);

app.use("/api", (_req, res) => res.status(404).json({ error: "Not found." }));

app.get("/", (_req, res) => res.json({ name: "PrepMate API", ok: true }));

// eslint-disable-next-line no-unused-vars
app.use((error, _req, res, _next) => {
  if (error?.type === "entity.parse.failed") return res.status(400).json({ error: "Invalid JSON in request." });
  if (error?.type === "entity.too.large") return res.status(413).json({ error: "Request is too large." });
  console.error("[server]", error);
  res.status(500).json({ error: "Something went wrong on the server." });
});

try {
  await connectDB();
} catch (error) {
  console.error(`\n[db] Could not connect to MongoDB: ${error.message}`);
  console.error("[db] Check MONGODB_URL and MONGODB_PASSWORD in your .env file, and that your IP is allowed in Atlas Network Access.\n");
  process.exit(1);
}

app.listen(PORT, () => {
  console.log(`[server] PrepMate API running on http://localhost:${PORT}`);
});
