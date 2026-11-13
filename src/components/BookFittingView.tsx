import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  AlertTriangle,
  Calendar,
  Check,
  Loader2,
  MapPin,
  Ruler,
  Scissors,
  Sparkles,
  Star,
  Upload,
} from "lucide-react";
import {
  FITTING_TIME_SLOTS,
  HOW_IT_WORKS_STEPS,
  HOUSE_ATELIER,
  OUTFITS,
  STUDIO_FABRICS,
} from "../data/catalog";
import { CustomStyleAnalysis, FitProfile, Outfit } from "../types";

interface BookFittingViewProps {
  profiles: FitProfile[];
  activeProfileId: string;
  onSelectProfile: (id: string) => void;
  preselectedOutfit: Outfit | null;
  onClearPreselected: () => void;
  onOpenFitStudio: () => void;
  onPlaceOrder: (params: {
    outfitName: string;
    outfitImage: string;
    priceLabel: string;
    isCustomInspiration: boolean;
    customStyleAnalysis?: CustomStyleAnalysis | null;
    fabricChoice: string;
    fabricNote: string;
    eventDate?: string;
    isRushOrder: boolean;
    appointmentSlot: string;
    profile: FitProfile;
  }) => void;
  onNotify: (msg: string) => void;
}

export const BookFittingView: React.FC<BookFittingViewProps> = ({
  profiles,
  activeProfileId,
  onSelectProfile,
  preselectedOutfit,
  onClearPreselected,
  onOpenFitStudio,
  onPlaceOrder,
  onNotify,
}) => {
  const [styleMode, setStyleMode] = useState<"lookbook" | "custom">("lookbook");
  const [selectedOutfitId, setSelectedOutfitId] = useState<string>(
    preselectedOutfit?.id ?? OUTFITS[0].id
  );
  const [customPhoto, setCustomPhoto] = useState<string | null>(null);
  const [customAnalysis, setCustomAnalysis] =
    useState<CustomStyleAnalysis | null>(null);
  const [isAnalyzingStyle, setIsAnalyzingStyle] = useState<boolean>(false);
  const [fabricChoice, setFabricChoice] = useState<string>(STUDIO_FABRICS[0]);
  const [eventDate, setEventDate] = useState<string>("");
  const [appointmentSlot, setAppointmentSlot] = useState<string>(
    FITTING_TIME_SLOTS[0]
  );
  const [fabricNote, setFabricNote] = useState<string>("");

  const customFileRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    if (preselectedOutfit) {
      setStyleMode("lookbook");
      setSelectedOutfitId(preselectedOutfit.id);
    }
  }, [preselectedOutfit]);

  const activeProfile =
    profiles.find((p) => p.id === activeProfileId) || profiles[0];

  const activeOutfit =
    OUTFITS.find((o) => o.id === selectedOutfitId) || OUTFITS[0];

  const isRushOrder = useMemo(() => {
    if (!eventDate) return false;
    const target = new Date(eventDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diffDays = Math.ceil(
      (target.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
    );
    const requiredDays = styleMode === "lookbook" ? activeOutfit.minDays : 10;
    return diffDays >= 0 && diffDays < requiredDays;
  }, [eventDate, styleMode, activeOutfit.minDays]);

  const handleCustomPhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      onNotify("Please upload a JPG, PNG, or WebP outfit photo.");
      return;
    }

    const reader = new FileReader();
    reader.onload = async () => {
      const dataUrl = reader.result as string;
      const base64 = dataUrl.split(",")[1] ?? "";
      setCustomPhoto(dataUrl);
      setCustomAnalysis(null);
      if (!base64) return;

      setIsAnalyzingStyle(true);
      try {
        const res = await fetch("/api/style-analyze", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            imageBase64: base64,
            imageMimeType: file.type,
            heightCm: activeProfile.heightCm,
          }),
        });
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.error || "Could not inspect inspiration photo.");
        }
        setCustomAnalysis(data as CustomStyleAnalysis);
        onNotify("Custom style analyzed with fabric & yardage estimate.");
      } catch (err: unknown) {
        onNotify(
          err instanceof Error
            ? err.message
            : "Uploaded photo saved. Add notes manually below."
        );
      } finally {
        setIsAnalyzingStyle(false);
      }
    };
    reader.readAsDataURL(file);
    e.target.value = "";
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (styleMode === "custom" && !customPhoto) {
      onNotify("Please upload an inspiration photo or switch to Lookbook Style.");
      return;
    }

    const chosenName =
      styleMode === "custom"
        ? customAnalysis?.garmentTitle || "Custom Inspiration Design"
        : activeOutfit.name;

    const chosenImage =
      styleMode === "custom" && customPhoto ? customPhoto : activeOutfit.image;

    const chosenPrice =
      styleMode === "custom" ? "Custom quote on review" : activeOutfit.priceLabel;

    onPlaceOrder({
      outfitName: chosenName,
      outfitImage: chosenImage,
      priceLabel: chosenPrice,
      isCustomInspiration: styleMode === "custom",
      customStyleAnalysis: styleMode === "custom" ? customAnalysis : null,
      fabricChoice,
      fabricNote: fabricNote.trim() || "Standard studio finish",
      eventDate: eventDate || undefined,
      isRushOrder,
      appointmentSlot,
      profile: activeProfile,
    });
    setFabricNote("");
    onClearPreselected();
  };

  return (
    <div className="max-w-6xl mx-auto px-5 sm:px-6 py-8 space-y-12">
      {/* Single Tailor Header */}
      <section className="rounded-3xl bg-white border border-[#211D2B]/8 p-6 sm:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6 shadow-[0_8px_24px_rgba(33,29,43,0.04)]">
        <div className="flex items-start gap-4 sm:gap-5">
          <div
            className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl flex items-center justify-center shrink-0"
            style={{ backgroundColor: HOUSE_ATELIER.surfaceTint }}
          >
            <Scissors className="w-8 h-8 text-[#7654E8]" />
          </div>
          <div className="space-y-1.5">
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
              <h1 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B] tracking-tight">
                {HOUSE_ATELIER.name}
              </h1>
              <span className="inline-flex items-center gap-1 text-sm font-bold text-[#211D2B] tabular-nums">
                <Star className="w-4 h-4 fill-[#F59E0B] text-[#F59E0B]" />
                {HOUSE_ATELIER.rating.toFixed(1)}
              </span>
            </div>
            <p className="text-xs sm:text-sm text-[#6E687B] flex items-center gap-1.5">
              <MapPin className="w-3.5 h-3.5 shrink-0 text-[#7654E8]" />
              <span>{HOUSE_ATELIER.location}</span>
              <span aria-hidden="true">·</span>
              <span>Turnaround {HOUSE_ATELIER.turnaround}</span>
            </p>
            <p className="text-sm text-[#6E687B] max-w-2xl leading-relaxed pt-1">
              {HOUSE_ATELIER.bio}
            </p>
          </div>
        </div>
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        <form
          onSubmit={handleSubmit}
          className="lg:col-span-7 bg-white rounded-3xl p-6 sm:p-8 border border-[#211D2B]/8 space-y-6 shadow-[0_8px_24px_rgba(33,29,43,0.04)]"
        >
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h2 className="font-display text-2xl font-bold text-[#211D2B]">
                Book a Custom Order
              </h2>
              <p className="text-xs text-[#6E687B] mt-0.5">
                Pick a studio look or upload your own style inspiration.
              </p>
            </div>

            <div className="inline-flex p-1 bg-[#FAF8FC] border border-[#211D2B]/10 rounded-xl self-start">
              <button
                type="button"
                onClick={() => setStyleMode("lookbook")}
                className={`px-3.5 py-2 rounded-lg text-xs font-semibold transition-colors ${
                  styleMode === "lookbook"
                    ? "bg-[#7654E8] text-white"
                    : "text-[#6E687B] hover:text-[#211D2B]"
                }`}
              >
                Lookbook Style
              </button>
              <button
                type="button"
                onClick={() => setStyleMode("custom")}
                className={`px-3.5 py-2 rounded-lg text-xs font-semibold transition-colors ${
                  styleMode === "custom"
                    ? "bg-[#7654E8] text-white"
                    : "text-[#6E687B] hover:text-[#211D2B]"
                }`}
              >
                Upload Custom Style
              </button>
            </div>
          </div>

          {styleMode === "lookbook" ? (
            <div>
              <label className="block text-xs font-semibold text-[#211D2B] mb-2">
                Select Style from Lookbook
              </label>
              <select
                value={selectedOutfitId}
                onChange={(e) => setSelectedOutfitId(e.target.value)}
                className="w-full px-4 py-3.5 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-sm text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
              >
                {OUTFITS.map((o) => (
                  <option key={o.id} value={o.id}>
                    {o.name} — {o.priceLabel} ({o.leadTime})
                  </option>
                ))}
              </select>
            </div>
          ) : (
            <div className="space-y-3">
              <label className="block text-xs font-semibold text-[#211D2B]">
                Upload Inspiration Photo (&ldquo;Bring Your Own Style&rdquo;)
              </label>
              <button
                type="button"
                onClick={() => customFileRef.current?.click()}
                className="w-full py-5 px-4 rounded-2xl border border-dashed border-[#7654E8]/45 bg-[#EAE3FF]/30 hover:bg-[#EAE3FF]/50 transition-colors flex flex-col items-center justify-center gap-2 text-center"
              >
                {isAnalyzingStyle ? (
                  <>
                    <Loader2 className="w-6 h-6 text-[#7654E8] animate-spin" />
                    <span className="text-xs font-semibold text-[#211D2B]">
                      Inspecting garment silhouette &amp; estimating fabric yardage...
                    </span>
                  </>
                ) : (
                  <>
                    <Upload className="w-6 h-6 text-[#7654E8]" />
                    <span className="text-xs font-semibold text-[#211D2B]">
                      {customPhoto
                        ? "Replace Custom Outfit Photo"
                        : "Upload Photo or Screenshot of Outfit"}
                    </span>
                    <span className="text-[11px] text-[#6E687B]">
                      AI estimates required yardage and neckline/sleeve details automatically
                    </span>
                  </>
                )}
              </button>
              <input
                ref={customFileRef}
                type="file"
                accept="image/*"
                onChange={handleCustomPhotoUpload}
                className="hidden"
              />
            </div>
          )}

          {/* Fit Profile Selector */}
          <div className="rounded-2xl bg-[#FAF8FC] p-4 sm:p-5 border border-[#211D2B]/8 space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold text-[#211D2B]">
                  Attach Fit Profile:
                </span>
                <select
                  value={activeProfile.id}
                  onChange={(e) => onSelectProfile(e.target.value)}
                  className="px-3 py-1.5 rounded-lg bg-white border border-[#211D2B]/12 text-xs font-semibold text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
                >
                  {profiles.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.label}
                    </option>
                  ))}
                </select>
              </div>

              <button
                type="button"
                onClick={onOpenFitStudio}
                className="text-xs font-semibold text-[#7654E8] hover:underline inline-flex items-center gap-1"
              >
                <Ruler className="w-3.5 h-3.5" />
                <span>Edit in Fit Studio</span>
              </button>
            </div>

            <div className="grid grid-cols-3 gap-2.5 text-xs font-mono tabular-nums text-[#211D2B]">
              <span>Chest: {activeProfile.measurements.Chest.toFixed(1)}</span>
              <span>Waist: {activeProfile.measurements.Waist.toFixed(1)}</span>
              <span>Hip: {activeProfile.measurements.Hip.toFixed(1)}</span>
              <span>
                Shoulder: {activeProfile.measurements.Shoulder.toFixed(1)}
              </span>
              <span>Sleeve: {activeProfile.measurements.Sleeve.toFixed(1)}</span>
              <span>Inseam: {activeProfile.measurements.Inseam.toFixed(1)}</span>
            </div>
          </div>

          {/* Fabric & Event Date + Appointment */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                Fabric Selection
              </label>
              <select
                value={fabricChoice}
                onChange={(e) => setFabricChoice(e.target.value)}
                className="w-full px-3.5 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-sm text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
              >
                {STUDIO_FABRICS.map((f) => (
                  <option key={f} value={f}>
                    {f}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                Target Event / Needed By Date
              </label>
              <div className="relative">
                <Calendar className="w-4 h-4 text-[#6E687B] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <input
                  type="date"
                  value={eventDate}
                  onChange={(e) => setEventDate(e.target.value)}
                  className="w-full pl-10 pr-3.5 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-sm text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
                />
              </div>
            </div>
          </div>

          {isRushOrder && (
            <div className="rounded-2xl bg-[#FFE9D9] p-4 flex items-start gap-3 text-xs text-[#7C2D12]">
              <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
              <p className="leading-relaxed">
                <strong>Rush Turnaround Notice:</strong> This event date is sooner than the
                standard garment lead time. {HOUSE_ATELIER.name} will confirm express slot
                availability upon reviewing your request.
              </p>
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
              Fitting Check-In Appointment
            </label>
            <select
              value={appointmentSlot}
              onChange={(e) => setAppointmentSlot(e.target.value)}
              className="w-full px-3.5 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-sm text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
            >
              {FITTING_TIME_SLOTS.map((slot) => (
                <option key={slot} value={slot}>
                  {slot}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
              Custom Notes (color, neckline, sleeve adjustments)
            </label>
            <textarea
              rows={3}
              value={fabricNote}
              onChange={(e) => setFabricNote(e.target.value)}
              placeholder="Preferred shade, embroidery placement, or fit preference..."
              className="w-full px-4 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-sm text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
            />
          </div>

          <button
            type="submit"
            disabled={isAnalyzingStyle}
            className="w-full py-3.5 px-6 rounded-xl bg-[#7654E8] text-white font-semibold text-sm hover:bg-[#6442D6] transition-colors flex items-center justify-center gap-2 min-h-[48px] disabled:opacity-60"
          >
            <Check className="w-4 h-4" />
            <span>
              Submit Order to {HOUSE_ATELIER.name} (
              {styleMode === "custom" ? "Custom Quote" : activeOutfit.priceLabel})
            </span>
          </button>
        </form>

        {/* Right: Design & AI Style Breakdown Preview */}
        <aside className="lg:col-span-5 bg-white rounded-3xl overflow-hidden border border-[#211D2B]/8 shadow-[0_8px_24px_rgba(33,29,43,0.04)]">
          {styleMode === "custom" ? (
            <>
              {customPhoto ? (
                <div className="aspect-[4/3] w-full overflow-hidden bg-[#FAF8FC]">
                  <img
                    src={customPhoto}
                    alt="Uploaded custom outfit inspiration"
                    className="w-full h-full object-cover"
                  />
                </div>
              ) : (
                <div className="aspect-[4/3] w-full bg-[#EAE3FF]/50 flex flex-col items-center justify-center p-8 text-center">
                  <Sparkles className="w-10 h-10 text-[#7654E8] mb-2" />
                  <p className="text-sm font-bold text-[#211D2B]">
                    Custom Style Preview
                  </p>
                  <p className="text-xs text-[#6E687B] mt-1">
                    Upload an inspiration photo to preview and estimate fabric yardage.
                  </p>
                </div>
              )}

              <div className="p-6 space-y-3">
                {customAnalysis ? (
                  <>
                    <p className="text-xs text-[#6E687B]">
                      {customAnalysis.categoryGuess} ·{" "}
                      {customAnalysis.estimatedLeadTime}
                    </p>
                    <h3 className="font-display text-xl font-bold text-[#211D2B]">
                      {customAnalysis.garmentTitle}
                    </h3>
                    <div className="text-xs space-y-1.5 text-[#211D2B] pt-1">
                      <p>
                        <span className="text-[#6E687B]">Suggested fabric: </span>
                        <span className="font-semibold">
                          {customAnalysis.suggestedFabric}
                        </span>
                      </p>
                      <p>
                        <span className="text-[#6E687B]">Estimated yardage: </span>
                        <span className="font-semibold tabular-nums">
                          {customAnalysis.estimatedYards}
                        </span>
                      </p>
                    </div>
                    {customAnalysis.constructionDetails.length > 0 && (
                      <ul className="text-xs text-[#6E687B] list-disc pl-4 space-y-1 pt-2 border-t border-[#211D2B]/8">
                        {customAnalysis.constructionDetails.map((d, i) => (
                          <li key={i}>{d}</li>
                        ))}
                      </ul>
                    )}
                  </>
                ) : (
                  <p className="text-xs text-[#6E687B]">
                    Upload any dress, Agbada, suit, or kaftan photo for automatic construction &amp; yardage analysis.
                  </p>
                )}
              </div>
            </>
          ) : (
            <>
              <div
                className="aspect-[4/3] w-full overflow-hidden"
                style={{ backgroundColor: activeOutfit.surfaceTint }}
              >
                <img
                  src={activeOutfit.image}
                  alt={activeOutfit.name}
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="p-6 space-y-2.5">
                <p className="text-xs text-[#6E687B]">
                  {activeOutfit.category} · {activeOutfit.leadTime}
                </p>
                <div className="flex items-baseline justify-between gap-3">
                  <h3 className="font-display text-xl font-bold text-[#211D2B]">
                    {activeOutfit.name}
                  </h3>
                  <span className="text-sm font-bold text-[#7654E8] tabular-nums">
                    {activeOutfit.priceLabel}
                  </span>
                </div>
                <p className="text-xs text-[#6E687B] leading-relaxed">
                  {activeOutfit.description}
                </p>
                <p className="text-xs font-medium text-[#211D2B] pt-1">
                  House material: {activeOutfit.fabric}
                </p>
              </div>
            </>
          )}
        </aside>
      </div>

      {/* 4-Step Bespoke Process */}
      <section className="space-y-5">
        <h2 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B]">
          How your order works
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {HOW_IT_WORKS_STEPS.map((item) => (
            <div
              key={item.number}
              className="bg-white rounded-2xl p-5 border border-[#211D2B]/8 space-y-2.5"
            >
              <span className="inline-flex w-10 h-10 rounded-full bg-[#EAE3FF] text-[#7654E8] font-mono text-sm font-bold items-center justify-center">
                {item.number}
              </span>
              <h3 className="text-sm font-bold text-[#211D2B]">{item.title}</h3>
              <p className="text-xs text-[#6E687B] leading-relaxed">
                {item.subtitle}
              </p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};
