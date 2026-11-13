// TrueFit AI API on Cloudflare Workers (free plan, no card needed).
// Same two endpoints as server.ts, so the apps don't change:
//   POST /api/fit-analyze    body measurements from front (+ optional side) photo
//   POST /api/style-analyze  garment breakdown from an inspiration photo
//   GET  /api/health
// The Gemini key is a Worker secret (GEMINI_API_KEY); it never reaches the phone.

const STR = { type: "STRING" };
const NUM = { type: "NUMBER" };
const KEYS = ["Chest", "Waist", "Hip", "Shoulder", "Sleeve", "Inseam"];
const DETAILS = ["bodyBuild", "shoulderProfile", "torsoProportion", "postureNote", "recommendedBaseSize", "lightingAndFraming"];

const FIT_SCHEMA = {
  type: "OBJECT",
  properties: {
    measurements: { type: "OBJECT", properties: Object.fromEntries(KEYS.map((k) => [k, NUM])), required: KEYS },
    extractedDetails: { type: "OBJECT", properties: Object.fromEntries(DETAILS.map((k) => [k, STR])), required: DETAILS },
    silhouetteNote: STR,
    easeRecommendation: STR,
    tailorNotes: { type: "ARRAY", items: STR },
  },
  required: ["measurements", "extractedDetails", "silhouetteNote", "easeRecommendation", "tailorNotes"],
};

const STYLE_FIELDS = ["garmentTitle", "categoryGuess", "suggestedFabric", "estimatedYards", "constructionDetails", "estimatedLeadTime"];
const STYLE_SCHEMA = {
  type: "OBJECT",
  properties: {
    garmentTitle: STR, categoryGuess: STR, suggestedFabric: STR, estimatedYards: STR,
    constructionDetails: { type: "ARRAY", items: STR }, estimatedLeadTime: STR,
  },
  required: STYLE_FIELDS,
};

function cors(env, request) {
  const allowed = (env.ALLOWED_ORIGINS || "*").split(",").map((o) => o.trim());
  const origin = request.headers.get("Origin");
  const h = { "Access-Control-Allow-Headers": "Content-Type", "Access-Control-Allow-Methods": "GET, POST, OPTIONS" };
  if (allowed.includes("*")) h["Access-Control-Allow-Origin"] = "*";
  else if (origin && allowed.includes(origin)) { h["Access-Control-Allow-Origin"] = origin; h["Vary"] = "Origin"; }
  return h;
}

const json = (data, status, headers) =>
  new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json", ...headers } });

async function gemini(env, parts, systemText, schema) {
  if (!env.GEMINI_API_KEY) throw new Error("GEMINI_API_KEY is not configured on the server.");
  const model = env.GEMINI_MODEL || "gemini-4-hydrogen";
  const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": env.GEMINI_API_KEY },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: systemText }] },
      contents: [{ role: "user", parts }],
      generationConfig: { responseMimeType: "application/json", responseSchema: schema },
    }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.error?.message || `Gemini request failed (HTTP ${res.status}).`);
  const text = (data?.candidates?.[0]?.content?.parts || []).map((p) => p.text || "").join("").trim();
  if (!text) throw new Error("The AI returned no result. Try a clearer photo.");
  return JSON.parse(text);
}

const image = (b64, mime) => ({ inlineData: { mimeType: mime, data: b64 } });

async function fitAnalyze(env, body) {
  const { heightCm, weightKg, fitPreference, garmentStyle, notes, imageBase64, imageMimeType, sideImageBase64, sideImageMimeType } = body;
  const lines = [
    "You are an expert bespoke master tailor and AI body-measurement vision specialist for TrueFit AI.",
    "Analyze the client's front photo (and optional side profile photo) along with calibration inputs to extract detailed anatomical garment proportions and measurements in centimeters (cm).",
    `Calibration Height: ${heightCm ?? 172} cm (use this as the vertical scale anchor when estimating lengths and circumferences).`,
    weightKg ? `Reference Weight: ${weightKg} kg.` : "Reference Weight: estimate visually from the photo(s).",
    `Preferred drape & ease: ${fitPreference || "Tailored"}.`,
    `Target garment style: ${garmentStyle || "Custom Outfit"}.`,
  ];
  if (notes && String(notes).trim()) lines.push(`Client notes: ${String(notes).trim()}`);
  if (imageBase64 && sideImageBase64) {
    lines.push("Both a front-facing photo AND a side-profile photo are attached. Use the front photo for shoulder width, hip width, and torso ratio, and the side profile for chest/bust projection, waist depth, posture tilt, and sleeve/inseam proportion.");
  } else if (imageBase64) {
    lines.push("A front-facing photo is attached. Inspect the person's silhouette, shoulder width and slope, chest/bust fullness, natural waist taper, hip breadth, torso-to-leg ratio, arm length proportion, posture, and framing/lighting quality.");
  } else {
    lines.push("No photo was attached; infer balanced anthropometric proportions and note in lightingAndFraming that estimates were derived from height calibration.");
  }
  const parts = [];
  if (imageBase64 && imageMimeType) parts.push(image(imageBase64, imageMimeType));
  if (sideImageBase64 && sideImageMimeType) parts.push(image(sideImageBase64, sideImageMimeType));
  parts.push({ text: lines.join("\n") });
  return gemini(env, parts,
    "Return precise, realistic adult garment measurements in centimeters within standard tailoring bounds (Chest 75-135, Waist 60-125, Hip 80-140, Shoulder 36-56, Sleeve 52-72, Inseam 68-92). Also extract concise, accurate tailoring observations in extractedDetails (bodyBuild, shoulderProfile, torsoProportion, postureNote, recommendedBaseSize, lightingAndFraming).",
    FIT_SCHEMA);
}

async function styleAnalyze(env, body) {
  const { imageBase64, imageMimeType, heightCm } = body;
  if (!imageBase64 || !imageMimeType) {
    const e = new Error("Please attach an inspiration image.");
    e.status = 400;
    throw e;
  }
  return gemini(env, [
    image(imageBase64, imageMimeType),
    { text: `Inspect this custom outfit inspiration photo for a bespoke tailoring studio. Client height reference: ${heightCm ?? 172} cm. Identify the garment style, best matching category (Ankara, Traditional, Casual, or Formal), recommended fabric type, estimated fabric yardage needed, key construction details (neckline, sleeve cut, silhouette, closures), and realistic tailoring lead time.` },
  ], "Provide practical, accurate bespoke garment breakdown for a master tailor. categoryGuess must be one of: Ankara, Traditional, Casual, Formal.", STYLE_SCHEMA);
}

export default {
  async fetch(request, env) {
    const h = cors(env, request);
    const { pathname } = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: h });
    if (pathname === "/" || pathname === "") {
      return json({ ok: true, service: "TrueFit AI API", health: "/api/health", geminiKeySet: Boolean(env.GEMINI_API_KEY) }, 200, h);
    }
    if (pathname === "/api/health") {
      return json({ ok: true, model: env.GEMINI_MODEL || "gemini-4-hydrogen", geminiKeySet: Boolean(env.GEMINI_API_KEY) }, 200, h);
    }
    const route = { "/api/fit-analyze": fitAnalyze, "/api/style-analyze": styleAnalyze }[pathname];
    if (!route) return json({ error: "Not found" }, 404, h);
    if (request.method !== "POST") return json({ error: "Use POST." }, 405, h);
    let body;
    try { body = await request.json(); } catch { return json({ error: "Send a JSON body." }, 400, h); }
    try {
      return json(await route(env, body), 200, h);
    } catch (e) {
      return json({ error: e?.message || "AI request failed." }, e?.status || 500, h);
    }
  },
};
