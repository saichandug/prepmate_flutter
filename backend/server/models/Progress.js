import mongoose from "mongoose";

const { Mixed } = mongoose.Schema.Types;

// One document per user: everything except applications (which have their own collection).
const progressSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },
    codingCompletion: { type: Mixed, default: {} },
    roadmapCompletion: { type: Mixed, default: {} },
    mockHistory: { type: [Mixed], default: [] },
    streak: { type: Mixed, default: {} },
    analyzer: { type: Mixed, default: { text: "", result: null } },
    roadmap: { type: Mixed, default: null },
  },
  { timestamps: true, minimize: false }
);

export default mongoose.model("Progress", progressSchema);
