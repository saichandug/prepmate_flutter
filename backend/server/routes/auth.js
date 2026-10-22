import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import rateLimit from "express-rate-limit";
import User from "../models/User.js";
import { requireAuth } from "../middleware/auth.js";
import { COOKIE_NAME, JWT_SECRET, TOKEN_TTL_MS } from "../config.js";

const router = Router();

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many attempts. Please wait a few minutes and try again.", code: "RATE_LIMITED" },
});

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

// Sets the cookie (browsers) and returns the token (mobile apps send it as a Bearer header).
function issueSession(req, res, user) {
  const token = jwt.sign({ sub: user._id.toString() }, JWT_SECRET, { expiresIn: Math.floor(TOKEN_TTL_MS / 1000) });
  res.cookie(COOKIE_NAME, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: req.secure,
    maxAge: TOKEN_TTL_MS,
    path: "/",
  });
  return token;
}

function cleanEmail(value) {
  return String(value ?? "").trim().toLowerCase();
}

router.post("/signup", limiter, async (req, res, next) => {
  try {
    const name = String(req.body?.name ?? "").trim();
    const email = cleanEmail(req.body?.email);
    const password = String(req.body?.password ?? "");

    const errors = {};
    if (name.length < 2 || name.length > 60) errors.name = "Enter your name (2–60 characters).";
    if (!EMAIL_RE.test(email) || email.length > 254) errors.email = "Enter a valid email address.";
    if (password.length < 8) errors.password = "Password must be at least 8 characters.";
    else if (password.length > 128) errors.password = "Password must be 128 characters or fewer.";
    if (Object.keys(errors).length) {
      return res.status(400).json({ error: Object.values(errors)[0], fields: errors, code: "VALIDATION" });
    }

    if (await User.exists({ email })) {
      return res.status(409).json({
        error: "An account with this email already exists. Sign in instead.",
        code: "ACCOUNT_EXISTS",
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    let user;
    try {
      user = await User.create({ name, email, passwordHash });
    } catch (error) {
      if (error?.code === 11000) {
        return res.status(409).json({
          error: "An account with this email already exists. Sign in instead.",
          code: "ACCOUNT_EXISTS",
        });
      }
      throw error;
    }

    const token = issueSession(req, res, user);
    res.status(201).json({ user: user.toPublic(), token });
  } catch (error) {
    next(error);
  }
});

router.post("/login", limiter, async (req, res, next) => {
  try {
    const email = cleanEmail(req.body?.email);
    const password = String(req.body?.password ?? "");

    if (!EMAIL_RE.test(email) || !password) {
      return res.status(400).json({ error: "Enter your email and password.", code: "VALIDATION" });
    }

    const user = await User.findOne({ email }).select("+passwordHash");
    if (!user) {
      return res.status(404).json({
        error: "No account found for this email. Create one to get started.",
        code: "ACCOUNT_NOT_FOUND",
      });
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      return res.status(401).json({ error: "Incorrect password. Try again.", code: "INVALID_CREDENTIALS" });
    }

    const token = issueSession(req, res, user);
    res.json({ user: user.toPublic(), token });
  } catch (error) {
    next(error);
  }
});

router.post("/logout", (req, res) => {
  res.clearCookie(COOKIE_NAME, { httpOnly: true, sameSite: "lax", secure: req.secure, path: "/" });
  res.json({ ok: true });
});

router.get("/me", requireAuth, (req, res) => {
  res.json({ user: req.user.toPublic() });
});

export default router;
