import React from "react";
import { Heart, Scissors, X } from "lucide-react";
import { Outfit } from "../types";
import { HOUSE_ATELIER } from "../data/catalog";

interface OutfitDetailModalProps {
  outfit: Outfit | null;
  isSaved: boolean;
  onClose: () => void;
  onToggleSave: (outfitId: string) => void;
  onBookFitting: (outfit: Outfit) => void;
}

export const OutfitDetailModal: React.FC<OutfitDetailModalProps> = ({
  outfit,
  isSaved,
  onClose,
  onToggleSave,
  onBookFitting,
}) => {
  if (!outfit) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-[#211D2B]/55 backdrop-blur-sm p-0 md:p-6"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="outfit-modal-title"
        onClick={(e) => e.stopPropagation()}
        className="w-full md:max-w-3xl bg-[#FAF8FC] rounded-t-3xl md:rounded-3xl overflow-hidden shadow-2xl max-h-[90vh] overflow-y-auto"
      >
        <div className="md:hidden w-10 h-1.5 bg-[#211D2B]/20 rounded-full mx-auto my-3" />

        <div className="grid grid-cols-1 md:grid-cols-12">
          <div
            className="md:col-span-6 relative aspect-[4/3] md:aspect-auto md:min-h-[420px]"
            style={{ backgroundColor: outfit.surfaceTint }}
          >
            <img
              src={outfit.image}
              alt={outfit.name}
              referrerPolicy="no-referrer"
              className="w-full h-full object-cover"
            />
            <button
              type="button"
              onClick={onClose}
              aria-label="Close outfit details"
              className="absolute top-4 right-4 md:hidden w-10 h-10 rounded-full bg-white/95 text-[#211D2B] flex items-center justify-center shadow-sm"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="md:col-span-6 p-6 sm:p-8 flex flex-col justify-between gap-6">
            <div>
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-xs font-medium text-[#6E687B]">
                    {outfit.category} · {outfit.leadTime}
                  </p>
                  <h2
                    id="outfit-modal-title"
                    className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B] mt-1"
                  >
                    {outfit.name}
                  </h2>
                </div>
                <button
                  type="button"
                  onClick={onClose}
                  aria-label="Close outfit details"
                  className="hidden md:flex w-10 h-10 rounded-full bg-white border border-[#211D2B]/10 text-[#211D2B] items-center justify-center hover:bg-[#EAE3FF] transition-colors shrink-0"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <p className="text-lg font-bold text-[#7654E8] tabular-nums mt-2">
                {outfit.priceLabel}
              </p>

              <p className="text-sm text-[#6E687B] leading-relaxed mt-4">
                {outfit.description}
              </p>

              <div className="mt-5 pt-5 border-t border-[#211D2B]/10 space-y-2.5 text-sm">
                <div className="flex items-center justify-between gap-4">
                  <span className="text-[#6E687B]">Fabric</span>
                  <span className="font-semibold text-[#211D2B] text-right">
                    {outfit.fabric}
                  </span>
                </div>
                <div className="flex items-center justify-between gap-4">
                  <span className="text-[#6E687B]">Crafted By</span>
                  <span className="font-semibold text-[#211D2B] text-right">
                    {HOUSE_ATELIER.name} · {HOUSE_ATELIER.location}
                  </span>
                </div>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row gap-3">
              <button
                type="button"
                onClick={() => onToggleSave(outfit.id)}
                className={`flex-1 py-3.5 px-4 rounded-xl border font-semibold text-sm flex items-center justify-center gap-2 transition-colors min-h-[48px] ${
                  isSaved
                    ? "border-[#E11D48]/30 bg-[#FFE4EF] text-[#9F1239]"
                    : "border-[#211D2B]/15 bg-white text-[#211D2B] hover:bg-[#EAE3FF]/50"
                }`}
              >
                <Heart
                  className={`w-4 h-4 ${isSaved ? "fill-[#E11D48] text-[#E11D48]" : ""}`}
                />
                <span>{isSaved ? "Saved" : "Save Look"}</span>
              </button>

              <button
                type="button"
                onClick={() => onBookFitting(outfit)}
                className="flex-1 py-3.5 px-4 rounded-xl bg-[#7654E8] text-white font-semibold text-sm flex items-center justify-center gap-2 hover:bg-[#6442D6] transition-colors min-h-[48px]"
              >
                <Scissors className="w-4 h-4" />
                <span>Book Fitting</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
