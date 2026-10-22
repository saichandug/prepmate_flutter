import jwt from "jsonwebtoken";
import { COOKIE_NAME, JWT_SECRET } from "../config.js";
import User from "../models/User.js";

export async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const token = req.cookies?.[COOKIE_NAME] || (header.startsWith("Bearer ") ? header.slice(7) : null);
    if (!token) return res.status(401).json({ error: "Please sign in to continue.", code: "UNAUTHENTICATED" });

    let payload;
    try {
      payload = jwt.verify(token, JWT_SECRET);
    } catch {
      return res.status(401).json({ error: "Your session has expired. Please sign in again.", code: "UNAUTHENTICATED" });
    }

    const user = await User.findById(payload.sub);
    if (!user) return res.status(401).json({ error: "Account not found. Please sign in again.", code: "UNAUTHENTICATED" });

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
}
