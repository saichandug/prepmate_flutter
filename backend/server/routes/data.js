import { Router } from "express";
import mongoose from "mongoose";
import Application from "../models/Application.js";
import Progress from "../models/Progress.js";
import { requireAuth } from "../middleware/auth.js";
import { validateApplication } from "../validation.js";

const router = Router();
const isObject = (v) => v && typeof v === "object" && !Array.isArray(v);

// Mongo field names can't contain "." or start with "$".
function safeMap(value) {
  if (!isObject(value)) return {};
  return Object.fromEntries(Object.entries(value).filter(([k]) => k && !k.includes(".") && !k.startsWith("$")));
}

function defaultStreak() {
  return { current: 0, best: 0, todayActivities: [], lastQualifiedDate: null, activityDates: {} };
}

function progressToClient(doc) {
  return {
    codingCompletion: safeMap(doc?.codingCompletion),
    roadmapCompletion: safeMap(doc?.roadmapCompletion),
    mockHistory: Array.isArray(doc?.mockHistory) ? doc.mockHistory : [],
    streak: isObject(doc?.streak) && Object.keys(doc.streak).length ? doc.streak : defaultStreak(),
    analyzer: isObject(doc?.analyzer) ? doc.analyzer : { text: "", result: null },
    roadmap: doc?.roadmap ?? null,
  };
}

function pickApplication(body) {
  return {
    company: String(body?.company ?? "").trim(),
    role: String(body?.role ?? "").trim(),
    interviewDate: String(body?.interviewDate ?? "").trim(),
    preparationHours: Number(body?.preparationHours),
    experience: String(body?.experience ?? "").trim(),
    status: String(body?.status ?? "").trim(),
    jd: String(body?.jd ?? ""),
  };
}

function checkApplication(body) {
  const errors = validateApplication(body || {});
  if (Object.keys(errors).length) return errors;
  if (String(body.jd ?? "").length > 2000) return { jd: "Job description must be 2000 characters or fewer." };
  return null;
}

async function findDuplicate(userId, { company, role }, excludeId) {
  const query = {
    user: userId,
    company: new RegExp(`^${company.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i"),
    role: new RegExp(`^${role.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i"),
  };
  if (excludeId) query._id = { $ne: excludeId };
  return Application.exists(query);
}

// Everything the workspace needs in one request.
router.get("/data", requireAuth, async (req, res, next) => {
  try {
    const [applications, progress] = await Promise.all([
      Application.find({ user: req.user._id }).sort({ createdAt: 1 }),
      Progress.findOne({ user: req.user._id }).lean(),
    ]);
    res.json({ applications, progress: progressToClient(progress) });
  } catch (error) {
    next(error);
  }
});

router.post("/applications", requireAuth, async (req, res, next) => {
  try {
    const errors = checkApplication(req.body);
    if (errors) return res.status(400).json({ error: Object.values(errors)[0], fields: errors, code: "VALIDATION" });

    const data = pickApplication(req.body);
    if (await findDuplicate(req.user._id, data)) {
      return res.status(409).json({ error: "An application for this company and role already exists.", code: "DUPLICATE" });
    }
    const created = await Application.create({ ...data, user: req.user._id });
    res.status(201).json({ application: created });
  } catch (error) {
    next(error);
  }
});

router.put("/applications/:id", requireAuth, async (req, res, next) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(404).json({ error: "Application not found." });

    const errors = checkApplication(req.body);
    if (errors) return res.status(400).json({ error: Object.values(errors)[0], fields: errors, code: "VALIDATION" });

    const data = pickApplication(req.body);
    if (await findDuplicate(req.user._id, data, req.params.id)) {
      return res.status(409).json({ error: "An application for this company and role already exists.", code: "DUPLICATE" });
    }
    const updated = await Application.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { $set: data },
      { new: true, runValidators: true }
    );
    if (!updated) return res.status(404).json({ error: "Application not found." });
    res.json({ application: updated });
  } catch (error) {
    next(error);
  }
});

router.delete("/applications/:id", requireAuth, async (req, res, next) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(404).json({ error: "Application not found." });
    const deleted = await Application.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!deleted) return res.status(404).json({ error: "Application not found." });
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

router.put("/progress", requireAuth, async (req, res, next) => {
  try {
    const body = req.body || {};
    const next_ = {
      codingCompletion: safeMap(body.codingCompletion),
      roadmapCompletion: safeMap(body.roadmapCompletion),
      mockHistory: Array.isArray(body.mockHistory) ? body.mockHistory.slice(0, 200) : [],
      streak: isObject(body.streak) ? body.streak : defaultStreak(),
      analyzer: isObject(body.analyzer) ? body.analyzer : { text: "", result: null },
      roadmap: isObject(body.roadmap) ? body.roadmap : null,
    };
    await Progress.findOneAndUpdate(
      { user: req.user._id },
      { $set: next_, $setOnInsert: { user: req.user._id } },
      { upsert: true, new: true }
    );
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

export default router;
