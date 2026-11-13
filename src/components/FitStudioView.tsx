import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Camera,
  Check,
  Loader2,
  Plus,
  RotateCcw,
  Sparkles,
  Trash2,
  Upload,
  X,
} from "lucide-react";
import {
  FitAnalysisResult,
  FitProfile,
  MeasurementKey,
  Measurements,
} from "../types";
import { DEFAULT_MEASUREMENTS } from "../data/catalog";

interface FitStudioViewProps {
  profiles: FitProfile[];
  activeProfileId: string;
  onSelectProfile: (id: string) => void;
  onCreateProfile: (label: string) => void;
  onDeleteProfile: (id: string) => void;
  onUpdateActiveProfile: (updater: (prev: FitProfile) => FitProfile) => void;
  onSaveProfile: (profile: FitProfile) => void;
  onNotify: (msg: string) => void;
}

const MEASUREMENT_BOUNDS: Record<
  MeasurementKey,
  { min: number; max: number; helper: string }
> = {
  Chest: { min: 70, max: 140, helper: "Fullest part of chest / bust" },
  Waist: { min: 55, max: 130, helper: "Natural waistline above navel" },
  Hip: { min: 75, max: 145, helper: "Widest point across seat" },
  Shoulder: { min: 34, max: 60, helper: "Acromion bone to bone" },
  Sleeve: { min: 48, max: 75, helper: "Shoulder seam to wrist bone" },
  Inseam: { min: 62, max: 96, helper: "Inner thigh to ankle" },
};

const DEFAULT_CAPTURE_SECONDS = 8;

export const FitStudioView: React.FC<FitStudioViewProps> = ({
  profiles,
  activeProfileId,
  onSelectProfile,
  onCreateProfile,
  onDeleteProfile,
  onUpdateActiveProfile,
  onSaveProfile,
  onNotify,
}) => {
  const activeProfile =
    profiles.find((p) => p.id === activeProfileId) || profiles[0];

  const [unit, setUnit] = useState<"cm" | "in">("cm");
  const [garmentStyle, setGarmentStyle] = useState<string>("Ankara / Couture");
  const [captureDelay, setCaptureDelay] = useState<5 | 8 | 12>(
    DEFAULT_CAPTURE_SECONDS
  );
  const [frontPreview, setFrontPreview] = useState<string | null>(null);
  const [frontBase64, setFrontBase64] = useState<string | null>(null);
  const [frontMime, setFrontMime] = useState<string | null>(null);
  const [sidePreview, setSidePreview] = useState<string | null>(null);
  const [sideBase64, setSideBase64] = useState<string | null>(null);
  const [sideMime, setSideMime] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState<boolean>(false);
  const [cameraActive, setCameraActive] = useState<boolean>(false);
  const [cameraReady, setCameraReady] = useState<boolean>(false);
  const [cameraWarmingUp, setCameraWarmingUp] = useState<boolean>(false);
  const [timerPaused, setTimerPaused] = useState<boolean>(false);
  const [countdown, setCountdown] = useState<number | null>(null);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [addingProfile, setAddingProfile] = useState<boolean>(false);
  const [newProfileName, setNewProfileName] = useState<string>("");

  const frontInputRef = useRef<HTMLInputElement | null>(null);
  const sideInputRef = useRef<HTMLInputElement | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    setCameraActive(false);
    setCameraReady(false);
    setCameraWarmingUp(false);
    setTimerPaused(false);
    setCountdown(null);
  }, []);

  useEffect(() => {
    return () => {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((track) => track.stop());
      }
    };
  }, []);

  const extractDetailsFromPhotos = useCallback(
    async (
      primaryBase64: string,
      primaryMime: string,
      optionalSideBase64?: string | null,
      optionalSideMime?: string | null
    ) => {
      setIsAnalyzing(true);
      try {
        const res = await fetch("/api/fit-analyze", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            heightCm: activeProfile.heightCm,
            fitPreference: activeProfile.fitPreference,
            garmentStyle,
            imageBase64: primaryBase64,
            imageMimeType: primaryMime,
            sideImageBase64: optionalSideBase64 || undefined,
            sideImageMimeType: optionalSideMime || undefined,
          }),
        });
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.error || "AI extraction failed.");
        }

        const result = data as FitAnalysisResult;
        const clamped: Measurements = { ...activeProfile.measurements };
        (Object.keys(MEASUREMENT_BOUNDS) as MeasurementKey[]).forEach((key) => {
          const raw = Number(result.measurements?.[key]);
          if (!Number.isNaN(raw)) {
            const { min, max } = MEASUREMENT_BOUNDS[key];
            clamped[key] =
              Math.round(Math.min(max, Math.max(min, raw)) * 10) / 10;
          }
        });

        onUpdateActiveProfile((prev) => ({
          ...prev,
          measurements: clamped,
          analysis: result,
          updatedAt: new Date().toLocaleDateString("en-US", {
            month: "short",
            day: "numeric",
          }),
        }));

        onNotify(
          optionalSideBase64
            ? "Front & side scans analyzed. Measurements updated."
            : "Photo captured and fit details extracted."
        );
      } catch (err: unknown) {
        const msg =
          err instanceof Error
            ? err.message
            : "Could not extract fit details from photo.";
        onNotify(msg);
      } finally {
        setIsAnalyzing(false);
      }
    },
    [activeProfile, garmentStyle, onNotify, onUpdateActiveProfile]
  );

  const captureAndExtract = useCallback(() => {
    const video = videoRef.current;
    if (!video || video.videoWidth === 0) return;

    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    const dataUrl = canvas.toDataURL("image/jpeg", 0.88);
    const base64 = dataUrl.split(",")[1] ?? "";

    setFrontPreview(dataUrl);
    setFrontBase64(base64);
    setFrontMime("image/jpeg");
    stopCamera();
    if (base64) {
      void extractDetailsFromPhotos(base64, "image/jpeg", sideBase64, sideMime);
    }
  }, [extractDetailsFromPhotos, sideBase64, sideMime, stopCamera]);

  const captureRef = useRef(captureAndExtract);
  useEffect(() => {
    captureRef.current = captureAndExtract;
  }, [captureAndExtract]);

  // Wait 1.2s after video starts playing so camera exposure/preview settles before countdown begins
  useEffect(() => {
    if (!cameraActive || !cameraReady || !cameraWarmingUp) return;
    const warmTimer = window.setTimeout(() => {
      setCameraWarmingUp(false);
      setCountdown(captureDelay);
    }, 1200);
    return () => window.clearTimeout(warmTimer);
  }, [cameraActive, cameraReady, cameraWarmingUp, captureDelay]);

  // Steady 1-second interval tick only after warm-up finishes and while not paused
  useEffect(() => {
    if (!cameraActive || !cameraReady || cameraWarmingUp || timerPaused) return;
    if (countdown === null) return;
    if (countdown <= 0) {
      captureRef.current();
      return;
    }
    const timer = window.setTimeout(() => {
      setCountdown((prev) => (prev !== null ? prev - 1 : null));
    }, 1000);
    return () => window.clearTimeout(timer);
  }, [cameraActive, cameraReady, cameraWarmingUp, timerPaused, countdown]);

  const startAutoScan = async () => {
    setCameraError(null);
    setFrontPreview(null);

    if (!navigator.mediaDevices?.getUserMedia) {
      setCameraError(
        "Live camera is unavailable in this browser. Upload a front photo below to extract measurements automatically."
      );
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: "user",
          width: { ideal: 1280 },
          height: { ideal: 960 },
        },
      });
      streamRef.current = stream;
      setCameraActive(true);
      setCameraReady(false);
      setCameraWarmingUp(true);
      setTimerPaused(false);
      setCountdown(captureDelay);
      requestAnimationFrame(() => {
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
        }
      });
    } catch {
      setCameraError(
        "Camera permission was declined or unavailable. Upload a photo instead and extraction will run automatically."
      );
    }
  };

  const handleFrontUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      onNotify("Please choose an image file (JPG, PNG, or WebP).");
      return;
    }
    stopCamera();
    setCameraError(null);
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = reader.result as string;
      const base64 = dataUrl.split(",")[1] ?? "";
      setFrontPreview(dataUrl);
      setFrontBase64(base64);
      setFrontMime(file.type);
      if (base64) {
        void extractDetailsFromPhotos(base64, file.type, sideBase64, sideMime);
      }
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  };

  const handleSideUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      onNotify("Please choose an image file (JPG, PNG, or WebP).");
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = reader.result as string;
      const base64 = dataUrl.split(",")[1] ?? "";
      setSidePreview(dataUrl);
      setSideBase64(base64);
      setSideMime(file.type);
      if (frontBase64 && frontMime && base64) {
        void extractDetailsFromPhotos(frontBase64, frontMime, base64, file.type);
      } else {
        onNotify("Side profile attached. Capture or upload a front photo to run two-angle scan.");
      }
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  };

  const handleAddProfileSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = newProfileName.trim();
    if (!trimmed) {
      onNotify("Enter a name for the new fit profile.");
      return;
    }
    onCreateProfile(trimmed);
    setNewProfileName("");
    setAddingProfile(false);
  };

  const formatVal = (cmVal: number) => {
    const displayed = unit === "cm" ? cmVal : cmVal / 2.54;
    return `${displayed.toFixed(1)} ${unit}`;
  };

  const analysisResult = activeProfile.analysis ?? null;

  return (
    <div className="max-w-6xl mx-auto px-5 sm:px-6 py-8 space-y-8">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-[#211D2B] tracking-tight">
            Fit Studio
          </h1>
          <p className="text-sm sm:text-base text-[#6E687B] mt-1">
            Save named measurement profiles for yourself, group fittings, or family events.
          </p>
        </div>

        <div className="inline-flex items-center p-1 bg-[#EAE3FF]/70 rounded-xl self-start">
          <button
            type="button"
            onClick={() => setUnit("cm")}
            className={`px-4 py-2 text-xs font-semibold rounded-lg transition-colors min-h-[40px] ${
              unit === "cm"
                ? "bg-white text-[#211D2B] shadow-sm"
                : "text-[#6E687B] hover:text-[#211D2B]"
            }`}
          >
            Centimeters (cm)
          </button>
          <button
            type="button"
            onClick={() => setUnit("in")}
            className={`px-4 py-2 text-xs font-semibold rounded-lg transition-colors min-h-[40px] ${
              unit === "in"
                ? "bg-white text-[#211D2B] shadow-sm"
                : "text-[#6E687B] hover:text-[#211D2B]"
            }`}
          >
            Inches (in)
          </button>
        </div>
      </div>

      {/* Named Fit Profiles Switcher */}
      <section className="bg-white rounded-2xl p-4 sm:p-5 border border-[#211D2B]/8 space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <span className="text-xs font-bold uppercase tracking-wider text-[#6E687B]">
            Fit Profiles ({profiles.length})
          </span>
          <div className="flex items-center gap-2">
            {profiles.length > 1 && (
              <button
                type="button"
                onClick={() => onDeleteProfile(activeProfile.id)}
                className="px-3 py-1.5 rounded-xl text-xs font-semibold text-[#9F1239] hover:bg-[#FFE4EF] transition-colors inline-flex items-center gap-1 min-h-[36px]"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>Delete Selected</span>
              </button>
            )}
            <button
              type="button"
              onClick={() => setAddingProfile((v) => !v)}
              className="px-3.5 py-1.5 rounded-xl bg-[#EAE3FF] text-[#7654E8] text-xs font-semibold hover:bg-[#DFD4FF] transition-colors inline-flex items-center gap-1 min-h-[36px]"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>New Profile</span>
            </button>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {profiles.map((prof) => {
            const active = prof.id === activeProfile.id;
            return (
              <button
                key={prof.id}
                type="button"
                onClick={() => onSelectProfile(prof.id)}
                className={`px-4 py-2 rounded-xl text-xs font-semibold transition-colors min-h-[40px] ${
                  active
                    ? "bg-[#7654E8] text-white"
                    : "bg-[#FAF8FC] text-[#211D2B] border border-[#211D2B]/10 hover:bg-[#EAE3FF]/50"
                }`}
              >
                {prof.label}
              </button>
            );
          })}
        </div>

        {addingProfile && (
          <form
            onSubmit={handleAddProfileSubmit}
            className="pt-2 flex flex-col sm:flex-row gap-2"
          >
            <input
              type="text"
              value={newProfileName}
              onChange={(e) => setNewProfileName(e.target.value)}
              placeholder="Profile name (e.g. Partner, Bridesmaid, Mum)"
              className="flex-1 px-3.5 py-2.5 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-sm focus:outline-none focus:border-[#7654E8]"
            />
            <button
              type="submit"
              className="px-5 py-2.5 rounded-xl bg-[#7654E8] text-white text-xs font-semibold min-h-[42px]"
            >
              Create Profile
            </button>
          </form>
        )}
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left: Automatic Two-Angle AI Photo Scan */}
        <section className="lg:col-span-5 rounded-3xl bg-[#211D2B] text-white p-6 sm:p-7 space-y-5 shadow-[0_16px_40px_rgba(33,29,43,0.14)]">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-[#7654E8] flex items-center justify-center shrink-0">
              <Camera className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="font-display text-xl font-bold text-white">
                AI Photo Scan ({activeProfile.label})
              </h2>
              <p className="text-xs text-white/75">
                Auto-captures in 3s · Optional side photo for depth accuracy
              </p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs text-white/80 mb-1.5">
                Height Anchor (cm)
              </label>
              <input
                type="number"
                min={140}
                max={215}
                value={activeProfile.heightCm}
                onChange={(e) =>
                  onUpdateActiveProfile((prev) => ({
                    ...prev,
                    heightCm: Number(e.target.value) || 170,
                  }))
                }
                className="w-full px-3.5 py-2.5 rounded-xl bg-white/10 border border-white/15 text-sm text-white tabular-nums focus:outline-none focus:border-[#EAE3FF]"
              />
            </div>
            <div>
              <label className="block text-xs text-white/80 mb-1.5">
                Garment Style
              </label>
              <select
                value={garmentStyle}
                onChange={(e) => setGarmentStyle(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-white/10 border border-white/15 text-sm text-white focus:outline-none focus:border-[#EAE3FF]"
              >
                <option value="Ankara / Couture" className="text-[#211D2B]">
                  Ankara / Couture
                </option>
                <option value="Modern Agbada" className="text-[#211D2B]">
                  Modern Agbada
                </option>
                <option value="Classic Suit" className="text-[#211D2B]">
                  Classic Suit
                </option>
                <option value="Casual Co-ord" className="text-[#211D2B]">
                  Casual Co-ord
                </option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs text-white/80 mb-1.5">
              Preferred Drape
            </label>
            <div className="grid grid-cols-3 gap-2">
              {(["Tailored", "Relaxed", "Structured"] as const).map((pref) => (
                <button
                  key={pref}
                  type="button"
                  onClick={() =>
                    onUpdateActiveProfile((prev) => ({
                      ...prev,
                      fitPreference: pref,
                    }))
                  }
                  className={`py-2 px-2 rounded-xl text-xs font-semibold transition-colors min-h-[40px] ${
                    activeProfile.fitPreference === pref
                      ? "bg-[#7654E8] text-white"
                      : "bg-white/10 text-white/80 hover:bg-white/15"
                  }`}
                >
                  {pref}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-xs text-white/80 mb-1.5">
              Self-Timer Before Auto-Capture
            </label>
            <div className="grid grid-cols-3 gap-2">
              {([5, 8, 12] as const).map((sec) => (
                <button
                  key={sec}
                  type="button"
                  onClick={() => {
                    setCaptureDelay(sec);
                    if (cameraActive) {
                      setCountdown(sec);
                    }
                  }}
                  className={`py-2 px-2 rounded-xl text-xs font-semibold tabular-nums transition-colors min-h-[40px] ${
                    captureDelay === sec
                      ? "bg-[#7654E8] text-white"
                      : "bg-white/10 text-white/80 hover:bg-white/15"
                  }`}
                >
                  {sec} seconds
                </button>
              ))}
            </div>
          </div>

          {cameraActive ? (
            <div className="space-y-3">
              <div className="relative rounded-2xl overflow-hidden bg-black aspect-[3/4]">
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                  onPlaying={() => setCameraReady(true)}
                  className="w-full h-full object-cover"
                />
                <svg
                  viewBox="0 0 200 260"
                  aria-hidden="true"
                  className="absolute inset-0 w-full h-full pointer-events-none opacity-65"
                >
                  <path
                    d="M100 22 C112 22 120 31 120 43 C120 55 112 63 100 63 C88 63 80 55 80 43 C80 31 88 22 100 22 Z M64 78 C75 70 125 70 136 78 L156 142 L140 148 L128 102 L126 168 L134 242 L112 242 L100 176 L88 242 L66 242 L74 168 L72 102 L60 148 L44 142 Z"
                    fill="none"
                    stroke="#EAE3FF"
                    strokeWidth="2"
                    strokeDasharray="6 5"
                  />
                </svg>

                <div className="absolute inset-x-3 bottom-3 bg-[#211D2B]/85 backdrop-blur-md rounded-xl px-4 py-3 space-y-2">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className="text-xs font-semibold text-white">
                        {!cameraReady
                          ? "Opening camera..."
                          : cameraWarmingUp
                            ? "Camera adjusting — step back into frame"
                            : timerPaused
                              ? "Timer paused — adjust your stance"
                              : countdown !== null && countdown > 0
                                ? `Hold steady · Capturing in ${countdown}s`
                                : "Capturing frame..."}
                      </p>
                      <p className="text-[11px] text-white/70">
                        Align shoulders &amp; hips inside the silhouette
                      </p>
                    </div>
                    {cameraReady && !cameraWarmingUp && countdown !== null && countdown > 0 && (
                      <span className="font-mono text-2xl font-bold text-[#EAE3FF] tabular-nums">
                        {countdown}
                      </span>
                    )}
                  </div>
                  {cameraReady && !cameraWarmingUp && countdown !== null && (
                    <div className="w-full h-1.5 rounded-full bg-white/15 overflow-hidden">
                      <div
                        className="h-full bg-[#EAE3FF] transition-all duration-500"
                        style={{
                          width: `${Math.max(
                            0,
                            Math.min(100, (countdown / captureDelay) * 100)
                          )}%`,
                        }}
                      />
                    </div>
                  )}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2">
                <button
                  type="button"
                  disabled={!cameraReady || cameraWarmingUp}
                  onClick={() => setTimerPaused((p) => !p)}
                  className="py-3 rounded-xl bg-white/15 text-white text-xs font-semibold min-h-[44px] disabled:opacity-50"
                >
                  {timerPaused ? "Resume" : "Pause"}
                </button>
                <button
                  type="button"
                  disabled={!cameraReady}
                  onClick={captureAndExtract}
                  className="py-3 rounded-xl bg-white text-[#7654E8] text-xs font-bold min-h-[44px] disabled:opacity-50"
                >
                  Capture Now
                </button>
                <button
                  type="button"
                  onClick={stopCamera}
                  className="py-3 rounded-xl bg-white/15 text-white text-xs font-semibold min-h-[44px]"
                >
                  Cancel
                </button>
              </div>
            </div>
          ) : frontPreview ? (
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div className="relative rounded-2xl overflow-hidden bg-black/30 aspect-[3/4]">
                  <img
                    src={frontPreview}
                    alt="Front scan"
                    className="w-full h-full object-cover"
                  />
                  {!isAnalyzing && (
                    <button
                      type="button"
                      onClick={() => {
                        setFrontPreview(null);
                        setFrontBase64(null);
                        setFrontMime(null);
                      }}
                      aria-label="Clear front photo"
                      className="absolute top-2 right-2 w-8 h-8 rounded-full bg-[#211D2B]/80 text-white flex items-center justify-center"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>

                {sidePreview ? (
                  <div className="relative rounded-2xl overflow-hidden bg-black/30 aspect-[3/4]">
                    <img
                      src={sidePreview}
                      alt="Side profile scan"
                      className="w-full h-full object-cover"
                    />
                    {!isAnalyzing && (
                      <button
                        type="button"
                        onClick={() => {
                          setSidePreview(null);
                          setSideBase64(null);
                          setSideMime(null);
                        }}
                        aria-label="Clear side photo"
                        className="absolute top-2 right-2 w-8 h-8 rounded-full bg-[#211D2B]/80 text-white flex items-center justify-center"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>
                ) : (
                  <button
                    type="button"
                    disabled={isAnalyzing}
                    onClick={() => sideInputRef.current?.click()}
                    className="rounded-2xl border border-dashed border-white/25 bg-white/5 hover:bg-white/10 aspect-[3/4] flex flex-col items-center justify-center p-3 text-center gap-2 transition-colors"
                  >
                    <Upload className="w-5 h-5 text-[#EAE3FF]" />
                    <span className="text-xs font-semibold text-white">
                      Add Side Profile
                    </span>
                    <span className="text-[11px] text-white/65">
                      Optional depth scan
                    </span>
                  </button>
                )}
              </div>

              {isAnalyzing && (
                <div className="rounded-xl bg-white/10 px-4 py-3 flex items-center gap-3">
                  <Loader2 className="w-5 h-5 text-white animate-spin shrink-0" />
                  <p className="text-xs font-semibold text-white">
                    Extracting body proportions &amp; measurements...
                  </p>
                </div>
              )}

              <div className="grid grid-cols-2 gap-2.5">
                <button
                  type="button"
                  disabled={isAnalyzing}
                  onClick={startAutoScan}
                  className="py-3 px-3 rounded-xl bg-white text-[#7654E8] text-xs font-bold flex items-center justify-center gap-1.5 min-h-[44px] disabled:opacity-50"
                >
                  <Camera className="w-4 h-4" />
                  <span>Retake Auto Scan</span>
                </button>
                <button
                  type="button"
                  disabled={isAnalyzing}
                  onClick={() => frontInputRef.current?.click()}
                  className="py-3 px-3 rounded-xl bg-white/15 hover:bg-white/20 text-white text-xs font-semibold flex items-center justify-center gap-1.5 min-h-[44px] disabled:opacity-50"
                >
                  <Upload className="w-4 h-4" />
                  <span>Replace Front</span>
                </button>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              <button
                type="button"
                onClick={startAutoScan}
                className="w-full py-3.5 px-5 rounded-xl bg-white text-[#7654E8] font-bold text-sm hover:bg-[#EAE3FF] transition-colors flex items-center justify-center gap-2 min-h-[48px]"
              >
                <Camera className="w-4 h-4" />
                <span>Start Automatic AI Scan</span>
              </button>

              <div className="grid grid-cols-2 gap-2.5">
                <button
                  type="button"
                  onClick={() => frontInputRef.current?.click()}
                  className="py-3 px-3 rounded-xl bg-white/10 hover:bg-white/15 border border-white/15 text-white text-xs font-semibold flex items-center justify-center gap-1.5 min-h-[44px]"
                >
                  <Upload className="w-4 h-4" />
                  <span>Upload Front</span>
                </button>
                <button
                  type="button"
                  onClick={() => sideInputRef.current?.click()}
                  className="py-3 px-3 rounded-xl bg-white/10 hover:bg-white/15 border border-white/15 text-white text-xs font-semibold flex items-center justify-center gap-1.5 min-h-[44px]"
                >
                  <Upload className="w-4 h-4" />
                  <span>{sidePreview ? "Side Ready" : "Add Side Photo"}</span>
                </button>
              </div>
            </div>
          )}

          <input
            ref={frontInputRef}
            type="file"
            accept="image/*"
            onChange={handleFrontUpload}
            className="hidden"
          />
          <input
            ref={sideInputRef}
            type="file"
            accept="image/*"
            onChange={handleSideUpload}
            className="hidden"
          />

          {cameraError && (
            <p className="text-xs text-[#FFE9D9] leading-relaxed">
              {cameraError}
            </p>
          )}

          {analysisResult && (
            <div className="pt-4 border-t border-white/15 space-y-4">
              <div className="flex items-center gap-2 text-[#EAE3FF] text-xs font-bold uppercase tracking-wider">
                <Sparkles className="w-3.5 h-3.5" />
                <span>Extracted Profile Details</span>
              </div>

              <dl className="grid grid-cols-2 gap-x-4 gap-y-3 text-xs">
                <div>
                  <dt className="text-white/60">Body Build</dt>
                  <dd className="font-semibold text-white mt-0.5">
                    {analysisResult.extractedDetails.bodyBuild}
                  </dd>
                </div>
                <div>
                  <dt className="text-white/60">Base Size</dt>
                  <dd className="font-semibold text-white mt-0.5 tabular-nums">
                    {analysisResult.extractedDetails.recommendedBaseSize}
                  </dd>
                </div>
                <div>
                  <dt className="text-white/60">Shoulder Profile</dt>
                  <dd className="font-semibold text-white mt-0.5">
                    {analysisResult.extractedDetails.shoulderProfile}
                  </dd>
                </div>
                <div>
                  <dt className="text-white/60">Torso Ratio</dt>
                  <dd className="font-semibold text-white mt-0.5">
                    {analysisResult.extractedDetails.torsoProportion}
                  </dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-white/60">Posture Observation</dt>
                  <dd className="font-medium text-white/90 mt-0.5">
                    {analysisResult.extractedDetails.postureNote}
                  </dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-white/60">Scan Quality</dt>
                  <dd className="text-white/80 mt-0.5">
                    {analysisResult.extractedDetails.lightingAndFraming}
                  </dd>
                </div>
              </dl>

              <div className="pt-3 border-t border-white/10 space-y-2 text-xs text-white/85">
                <p className="font-semibold text-[#EAE3FF]">
                  {analysisResult.silhouetteNote}
                </p>
                <p>Ease: {analysisResult.easeRecommendation}</p>
                {analysisResult.tailorNotes.length > 0 && (
                  <ul className="list-disc pl-4 space-y-1 text-white/75">
                    {analysisResult.tailorNotes.map((note, idx) => (
                      <li key={idx}>{note}</li>
                    ))}
                  </ul>
                )}
              </div>
            </div>
          )}
        </section>

        {/* Right: Extracted & Manual Measurement Sliders */}
        <section className="lg:col-span-7 space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <h2 className="font-display text-2xl font-bold text-[#211D2B]">
                {analysisResult
                  ? `Extracted Measurements · ${activeProfile.label}`
                  : `Manual Fit Profile · ${activeProfile.label}`}
              </h2>
              <p className="text-xs text-[#6E687B] mt-0.5">
                Review AI estimates or fine-tune any dimension before saving.
              </p>
            </div>
            <button
              type="button"
              onClick={() => {
                onUpdateActiveProfile((prev) => ({
                  ...prev,
                  measurements: DEFAULT_MEASUREMENTS,
                  analysis: null,
                }));
                onNotify("Reset measurements to baseline values.");
              }}
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-semibold text-[#6E687B] hover:text-[#211D2B] hover:bg-white transition-colors min-h-[40px]"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Reset</span>
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {(Object.keys(MEASUREMENT_BOUNDS) as MeasurementKey[]).map((key) => {
              const { min, max, helper } = MEASUREMENT_BOUNDS[key];
              const value = activeProfile.measurements[key];

              return (
                <div
                  key={key}
                  className="bg-white rounded-2xl p-5 border border-[#211D2B]/8 space-y-3"
                >
                  <div className="flex items-baseline justify-between gap-2">
                    <div>
                      <h3 className="text-sm font-bold text-[#211D2B]">{key}</h3>
                      <p className="text-[11px] text-[#6E687B]">{helper}</p>
                    </div>
                    <span className="font-mono text-base font-semibold text-[#7654E8] tabular-nums whitespace-nowrap">
                      {formatVal(value)}
                    </span>
                  </div>

                  <input
                    type="range"
                    aria-label={`${key} measurement in cm`}
                    min={min}
                    max={max}
                    step={0.5}
                    value={value}
                    onChange={(e) =>
                      onUpdateActiveProfile((prev) => ({
                        ...prev,
                        measurements: {
                          ...prev.measurements,
                          [key]: Number(e.target.value),
                        },
                      }))
                    }
                    className="w-full atelier-slider"
                  />

                  <div className="flex justify-between text-[11px] text-[#6E687B] font-mono tabular-nums">
                    <span>{formatVal(min)}</span>
                    <span>{formatVal(max)}</span>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="pt-2 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 bg-[#EAE3FF]/60 rounded-2xl p-5">
            <div className="text-xs text-[#211D2B] space-y-0.5">
              <p className="font-bold">Save &ldquo;{activeProfile.label}&rdquo;</p>
              <p className="text-[#6E687B]">
                Choose this profile when booking a custom fitting.
              </p>
            </div>
            <button
              type="button"
              onClick={() => onSaveProfile(activeProfile)}
              className="px-6 py-3.5 rounded-xl bg-[#7654E8] text-white font-semibold text-sm hover:bg-[#6442D6] transition-colors inline-flex items-center justify-center gap-2 min-h-[48px] whitespace-nowrap shrink-0"
            >
              <Check className="w-4 h-4" />
              <span>Save Profile</span>
            </button>
          </div>
        </section>
      </div>
    </div>
  );
};
