import mongoose from "mongoose";

const applicationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    company: { type: String, required: true, trim: true, maxlength: 100 },
    role: { type: String, required: true, trim: true, maxlength: 120 },
    interviewDate: { type: String, required: true }, // YYYY-MM-DD, as the form produces it
    preparationHours: { type: Number, required: true, min: 0.1, max: 24 },
    experience: { type: String, required: true, maxlength: 40 },
    status: { type: String, required: true, maxlength: 40 },
    jd: { type: String, default: "", maxlength: 5000 },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: false,
      transform(_doc, ret) {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        delete ret.user;
        delete ret.updatedAt;
        return ret;
      },
    },
  }
);

export default mongoose.model("Application", applicationSchema);
