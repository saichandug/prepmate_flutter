import { Router } from "express";
import rateLimit from "express-rate-limit";
import { generateGemini, DEFAULT_MODEL } from "../geminiCore.js";
import { requireAuth } from "../middleware/auth.js";

const router = Router();

const limiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many AI requests. Please wait a minute and try again." },
});

router.post("/", requireAuth, limiter, async (req, res) => {
  const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;
  if (!apiKey) return res.status(503).json({ error: "Gemini API key is not configured on the server." });

  try {
    const { mode, ...input } = req.body || {};
    const response = await generateGemini({
      mode,
      input,
      apiKey,
      model: process.env.GEMINI_MODEL || DEFAULT_MODEL,
    });
    res.json(response);
  } catch (error) {
    console.error("Gemini API error:", error?.message);
    // Never forward Gemini's own 401/403 as our status, or the app would think the user was signed out.
    res.status(502).json({ error: error?.message || "Gemini request failed." });
  }
});

export default router;
