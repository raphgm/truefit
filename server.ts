import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI, Type } from "@google/genai";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3000;

function getGeminiClient() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not configured in server environment.");
  }
  return new GoogleGenAI({
    apiKey,
    httpOptions: {
      headers: {
        "User-Agent": "aistudio-build",
      },
    },
  });
}

async function startServer() {
  const app = express();
  app.use(express.json({ limit: "18mb" }));

  app.get("/api/health", (_req, res) => {
    res.json({ ok: true });
  });

  app.post("/api/fit-analyze", async (req, res) => {
    try {
      const {
        heightCm,
        weightKg,
        fitPreference,
        garmentStyle,
        notes,
        imageBase64,
        imageMimeType,
        sideImageBase64,
        sideImageMimeType,
      } = req.body as {
        heightCm?: number;
        weightKg?: number;
        fitPreference?: string;
        garmentStyle?: string;
        notes?: string;
        imageBase64?: string;
        imageMimeType?: string;
        sideImageBase64?: string;
        sideImageMimeType?: string;
      };

      const ai = getGeminiClient();

      const promptLines = [
        "You are an expert bespoke master tailor and AI body-measurement vision specialist for TrueFit AI.",
        "Analyze the client's front photo (and optional side profile photo) along with calibration inputs to extract detailed anatomical garment proportions and measurements in centimeters (cm).",
        `Calibration Height: ${heightCm ?? 172} cm (use this as the vertical scale anchor when estimating lengths and circumferences).`,
        weightKg
          ? `Reference Weight: ${weightKg} kg.`
          : "Reference Weight: estimate visually from the photo(s).",
        `Preferred drape & ease: ${fitPreference || "Tailored"}.`,
        `Target garment style: ${garmentStyle || "Custom Outfit"}.`,
      ];
      if (notes && notes.trim()) {
        promptLines.push(`Client notes: ${notes.trim()}`);
      }
      if (imageBase64 && sideImageBase64) {
        promptLines.push(
          "Both a front-facing photo AND a side-profile photo are attached. Use the front photo for shoulder width, hip width, and torso ratio, and the side profile for chest/bust projection, waist depth, posture tilt, and sleeve/inseam proportion."
        );
      } else if (imageBase64) {
        promptLines.push(
          "A front-facing photo is attached. Inspect the person's silhouette, shoulder width and slope, chest/bust fullness, natural waist taper, hip breadth, torso-to-leg ratio, arm length proportion, posture, and framing/lighting quality."
        );
      } else {
        promptLines.push(
          "No photo was attached; infer balanced anthropometric proportions and note in lightingAndFraming that estimates were derived from height calibration."
        );
      }

      const parts: Array<
        | { text: string }
        | { inlineData: { mimeType: string; data: string } }
      > = [];

      if (imageBase64 && imageMimeType) {
        parts.push({
          inlineData: {
            mimeType: imageMimeType,
            data: imageBase64,
          },
        });
      }
      if (sideImageBase64 && sideImageMimeType) {
        parts.push({
          inlineData: {
            mimeType: sideImageMimeType,
            data: sideImageBase64,
          },
        });
      }
      parts.push({ text: promptLines.join("\n") });

      const response = await ai.models.generateContent({
        model: "gemini-4-hydrogen",
        contents: { parts },
        config: {
          systemInstruction:
            "Return precise, realistic adult garment measurements in centimeters within standard tailoring bounds (Chest 75-135, Waist 60-125, Hip 80-140, Shoulder 36-56, Sleeve 52-72, Inseam 68-92). Also extract concise, accurate tailoring observations in extractedDetails (bodyBuild, shoulderProfile, torsoProportion, postureNote, recommendedBaseSize, lightingAndFraming).",
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              measurements: {
                type: Type.OBJECT,
                properties: {
                  Chest: { type: Type.NUMBER },
                  Waist: { type: Type.NUMBER },
                  Hip: { type: Type.NUMBER },
                  Shoulder: { type: Type.NUMBER },
                  Sleeve: { type: Type.NUMBER },
                  Inseam: { type: Type.NUMBER },
                },
                required: [
                  "Chest",
                  "Waist",
                  "Hip",
                  "Shoulder",
                  "Sleeve",
                  "Inseam",
                ],
              },
              extractedDetails: {
                type: Type.OBJECT,
                properties: {
                  bodyBuild: { type: Type.STRING },
                  shoulderProfile: { type: Type.STRING },
                  torsoProportion: { type: Type.STRING },
                  postureNote: { type: Type.STRING },
                  recommendedBaseSize: { type: Type.STRING },
                  lightingAndFraming: { type: Type.STRING },
                },
                required: [
                  "bodyBuild",
                  "shoulderProfile",
                  "torsoProportion",
                  "postureNote",
                  "recommendedBaseSize",
                  "lightingAndFraming",
                ],
              },
              silhouetteNote: { type: Type.STRING },
              easeRecommendation: { type: Type.STRING },
              tailorNotes: {
                type: Type.ARRAY,
                items: { type: Type.STRING },
              },
            },
            required: [
              "measurements",
              "extractedDetails",
              "silhouetteNote",
              "easeRecommendation",
              "tailorNotes",
            ],
          },
        },
      });

      const raw = (response.text ?? "{}").trim();
      const parsed = JSON.parse(raw);
      res.json(parsed);
    } catch (error: unknown) {
      const msg =
        error instanceof Error
          ? error.message
          : "Unable to complete AI fit estimation right now.";
      res.status(500).json({ error: msg });
    }
  });

  app.post("/api/style-analyze", async (req, res) => {
    try {
      const { imageBase64, imageMimeType, heightCm } = req.body as {
        imageBase64?: string;
        imageMimeType?: string;
        heightCm?: number;
      };

      if (!imageBase64 || !imageMimeType) {
        res.status(400).json({ error: "Please attach an inspiration image." });
        return;
      }

      const ai = getGeminiClient();

      const response = await ai.models.generateContent({
        model: "gemini-4-hydrogen",
        contents: {
          parts: [
            {
              inlineData: {
                mimeType: imageMimeType,
                data: imageBase64,
              },
            },
            {
              text: `Inspect this custom outfit inspiration photo for a bespoke tailoring studio. Client height reference: ${
                heightCm ?? 172
              } cm. Identify the garment style, best matching category (Ankara, Traditional, Casual, or Formal), recommended fabric type, estimated fabric yardage needed, key construction details (neckline, sleeve cut, silhouette, closures), and realistic tailoring lead time.`,
            },
          ],
        },
        config: {
          systemInstruction:
            "Provide practical, accurate bespoke garment breakdown for a master tailor. categoryGuess must be one of: Ankara, Traditional, Casual, Formal.",
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              garmentTitle: { type: Type.STRING },
              categoryGuess: { type: Type.STRING },
              suggestedFabric: { type: Type.STRING },
              estimatedYards: { type: Type.STRING },
              constructionDetails: {
                type: Type.ARRAY,
                items: { type: Type.STRING },
              },
              estimatedLeadTime: { type: Type.STRING },
            },
            required: [
              "garmentTitle",
              "categoryGuess",
              "suggestedFabric",
              "estimatedYards",
              "constructionDetails",
              "estimatedLeadTime",
            ],
          },
        },
      });

      const raw = (response.text ?? "{}").trim();
      const parsed = JSON.parse(raw);
      res.json(parsed);
    } catch (error: unknown) {
      const msg =
        error instanceof Error
          ? error.message
          : "Unable to analyze inspiration photo.";
      res.status(500).json({ error: msg });
    }
  });

  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.resolve(__dirname, "dist");
    app.use(express.static(distPath));
    app.get("*", (_req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`TrueFit AI server running on http://localhost:${PORT}`);
  });
}

startServer();
