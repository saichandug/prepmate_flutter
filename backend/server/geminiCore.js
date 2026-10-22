const DEFAULT_MODEL = "gemini-2.5-flash-lite";
const FALLBACK_MODELS = ["gemini-2.5-flash-lite", "gemini-flash-latest"];

function extractJson(text) {
  const cleaned = String(text || "")
    .trim()
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/```$/i, "")
    .trim();
  try {
    return JSON.parse(cleaned);
  } catch {
    const starts = [cleaned.indexOf("{"), cleaned.indexOf("[")].filter((n) => n >= 0);
    const start = starts.length ? Math.min(...starts) : -1;
    const end = Math.max(cleaned.lastIndexOf("}"), cleaned.lastIndexOf("]"));
    if (start >= 0 && end > start) return JSON.parse(cleaned.slice(start, end + 1));
    throw new Error("Gemini returned an invalid JSON response.");
  }
}

function promptFor(mode, input) {
  if (mode === "jd") {
    return `You are PrepMate's placement assistant. Analyze this software job description for a college student. Return ONLY valid JSON with this exact shape:
{"summary":"string","skills":[{"name":"string","category":"Programming|Web|Database|Cloud|DevOps|Data|AI|Soft Skills|Other","priority":"HIGH|MEDIUM|LOW"}],"categories":["string"],"education":"string","experience":"string","responsibilities":["string"],"keywords":["string"],"missingSkillSuggestions":["string"]}
Rules: only include skills actually supported by the text; do not invent company requirements; keep arrays concise (max 12 skills, 8 responsibilities, 12 keywords, 8 suggestions). If the text is not a genuine job description, return empty arrays and say so in summary.
JOB DESCRIPTION:\n${input.text}`;
  }

  if (mode === "questions") {
    return `You are a technical placement interviewer. Generate a varied mock interview for the candidate.
Return ONLY valid JSON with this exact shape: {"questions":[{"question":"string","topic":"string","difficulty":"Easy|Medium|Hard","concepts":["string"]}]}
Generate 7 questions. Mix conceptual, practical, problem-solving and role-specific questions. Avoid repeating common boilerplate. Do not claim these are official company questions. Company and role are context only.
Company: ${input.company}\nRole: ${input.role}\nDifficulty: ${input.difficulty}`;
  }

  if (mode === "evaluate") {
    return `Evaluate a candidate's answer to a technical interview question. Return ONLY valid JSON with this exact shape: {"score":0,"matchedConcepts":["string"],"strengths":["string"],"weaknesses":["string"],"feedback":"string"}
Score from 0 to 100. A random, irrelevant, or empty answer must receive 0-15. Do not award points merely for answer length. Give substantial credit only when the answer correctly addresses the question and key concepts. Keep feedback concise.
QUESTION: ${input.question}\nEXPECTED CONCEPTS: ${input.concepts.join(", ")}\nCANDIDATE ANSWER: ${input.answer}`;
  }

  throw new Error("Unsupported Gemini mode.");
}

function isTransient(status) {
  return status === 408 || status === 429 || status === 500 || status === 502 || status === 503 || status === 504;
}

function friendlyError(data, status) {
  const message = data?.error?.message || "Gemini request failed.";
  if (status === 503 || /high demand|unavailable|overloaded/i.test(message)) {
    return "Gemini is temporarily busy. PrepMate tried the free Flash-Lite model and will retry automatically. Please try again in a moment.";
  }
  if (status === 429) {
    return "Gemini free-tier limit was reached. Please wait briefly and try again.";
  }
  if (status === 401 || status === 403) {
    return "Gemini API key was rejected. Check that your new key is valid and has Gemini API access.";
  }
  if (status === 404) {
    return `Gemini model was not found. Check GEMINI_MODEL (currently ${process.env.GEMINI_MODEL || DEFAULT_MODEL}).`;
  }
  return message;
}

async function requestModel({ model, prompt, apiKey }) {
  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
        responseMimeType: "application/json",
      },
    }),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(friendlyError(data, response.status));
    error.status = response.status;
    error.rawMessage = data?.error?.message || "";
    throw error;
  }

  const text = data?.candidates?.[0]?.content?.parts?.map((part) => part.text || "").join("") || "";
  if (!text) throw new Error("Gemini returned no content.");
  return extractJson(text);
}

async function requestWithRetry({ model, prompt, apiKey }) {
  let lastError;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      return await requestModel({ model, prompt, apiKey });
    } catch (error) {
      lastError = error;
      if (!isTransient(error.status) || attempt === 1) break;
      await new Promise((resolve) => setTimeout(resolve, 900 * 2 ** attempt + Math.random() * 500));
    }
  }
  throw lastError;
}

export async function generateGemini({ mode, input, apiKey, model = DEFAULT_MODEL }) {
  if (!apiKey) throw new Error("Gemini API key is not configured.");
  if (!mode) throw new Error("Missing mode.");

  const prompt = promptFor(mode, input || {});
  const models = [...new Set([model, ...FALLBACK_MODELS])];
  let lastError;

  for (const candidateModel of models) {
    try {
      const result = await requestWithRetry({ model: candidateModel, prompt, apiKey });
      return { result, model: candidateModel };
    } catch (error) {
      lastError = error;
      // Only move to another model for temporary capacity/rate-limit failures.
      // Invalid keys, bad requests, and permission errors should be reported directly.
      if (!isTransient(error.status)) throw error;
    }
  }

  throw lastError || new Error("Gemini request failed.");
}

export { DEFAULT_MODEL };
