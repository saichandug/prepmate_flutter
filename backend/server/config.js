import dotenv from "dotenv";
import crypto from "node:crypto";

// .env.local wins over .env if both exist.
dotenv.config({ path: [".env.local", ".env"] });

export const isProduction = process.env.NODE_ENV === "production" || process.argv.includes("--prod");
export const PORT = Number(process.env.PORT) || 5000;
export const COOKIE_NAME = "prepmate_token";
export const TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

let jwtSecret = process.env.JWT_SECRET?.trim();
if (!jwtSecret) {
  if (isProduction) {
    console.error("JWT_SECRET is missing. Add a long random string to your .env file.");
    process.exit(1);
  }
  jwtSecret = crypto.randomBytes(48).toString("hex");
  console.warn("[auth] JWT_SECRET not set. Using a temporary secret, so logins reset whenever the server restarts.");
}
export const JWT_SECRET = jwtSecret;

/**
 * Builds the connection string from MONGODB_URL + MONGODB_PASSWORD.
 * Handles three cases:
 *  1. URL has a <db_password> / <password> placeholder -> replaced.
 *  2. URL has a username but no password (user@host)  -> password inserted.
 *  3. URL already contains the password               -> used as is.
 */
export function buildMongoUri() {
  const url = process.env.MONGODB_URL?.trim();
  const password = process.env.MONGODB_PASSWORD ?? "";
  if (!url) {
    throw new Error("MONGODB_URL is missing. Add it to your .env file.");
  }
  if (!password) return url;

  const encoded = encodeURIComponent(password);
  if (/<(db_)?password>/i.test(url)) return url.replace(/<(db_)?password>/i, encoded);
  return url.replace(/^(mongodb(?:\+srv)?:\/\/)([^:@/]+)@/i, `$1$2:${encoded}@`);
}

export const MONGODB_DB = process.env.MONGODB_DB?.trim() || "prepmate";
