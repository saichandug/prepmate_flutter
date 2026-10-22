import mongoose from "mongoose";
import { buildMongoUri, MONGODB_DB } from "./config.js";

export async function connectDB() {
  mongoose.set("strictQuery", true);
  await mongoose.connect(buildMongoUri(), {
    dbName: MONGODB_DB,
    serverSelectionTimeoutMS: 10000,
  });
  console.log(`[db] Connected to MongoDB (database: ${MONGODB_DB})`);
}
