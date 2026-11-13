import React, { useState } from "react";
import { Heart, Shirt } from "lucide-react";
import { Outfit } from "../types";

interface LookbookGridProps {
  outfits: Outfit[];
  favorites: string[];
  onToggleFavorite: (outfitId: string) => void;
  onSelectOutfit: (outfit: Outfit) => void;
}

export const LookbookGrid: React.FC<LookbookGridProps> = ({
  outfits,
  favorites,
  onToggleFavorite,
  onSelectOutfit,
}) => {
  const [failedImages, setFailedImages] = useState<Record<string, boolean>>({});

  if (outfits.length === 0) {
    return (
      <div className="rounded-3xl bg-white border border-[#211D2B]/8 p-12 text-center">
        <Shirt className="w-10 h-10 text-[#7654E8] mx-auto mb-3" />
        <h3 className="font-display text-xl font-bold text-[#211D2B]">
          No looks match this category
        </h3>
        <p className="text-sm text-[#6E687B] mt-1">
          Select &ldquo;For You&rdquo; to browse the full TrueFit AI lookbook.
        </p>
      </div>
    );
  }

  return (
    <div className="columns-1 sm:columns-2 lg:columns-3 gap-6 space-y-6">
      {outfits.map((outfit) => {
        const isSaved = favorites.includes(outfit.id);
        const imageBroken = failedImages[outfit.id];

        return (
          <article
            key={outfit.id}
            className="break-inside-avoid rounded-3xl bg-white border border-[#211D2B]/8 overflow-hidden transition-transform duration-200 hover:-translate-y-0.5 shadow-[0_8px_24px_rgba(33,29,43,0.04)]"
          >
            <div
              className={`relative w-full ${outfit.aspectClass} overflow-hidden cursor-pointer`}
              style={{ backgroundColor: outfit.surfaceTint }}
              onClick={() => onSelectOutfit(outfit)}
            >
              {!imageBroken ? (
                <img
                  src={outfit.image}
                  alt={`${outfit.name} — ${outfit.category} custom garment`}
                  referrerPolicy="no-referrer"
                  onError={() =>
                    setFailedImages((prev) => ({ ...prev, [outfit.id]: true }))
                  }
                  className="w-full h-full object-cover transition-transform duration-300 hover:scale-[1.03]"
                />
              ) : (
                <div className="w-full h-full flex flex-col items-center justify-center p-6 text-center">
                  <Shirt className="w-12 h-12 text-[#7654E8]/60 mb-2" />
                  <span className="text-sm font-semibold text-[#211D2B]">{outfit.name}</span>
                </div>
              )}

              <button
                type="button"
                aria-label={isSaved ? `Remove ${outfit.name} from saved` : `Save ${outfit.name}`}
                onClick={(e) => {
                  e.stopPropagation();
                  onToggleFavorite(outfit.id);
                }}
                className="absolute top-3 right-3 w-11 h-11 rounded-full bg-white/95 backdrop-blur-sm flex items-center justify-center shadow-sm hover:scale-105 transition-transform"
              >
                <Heart
                  className={`w-5 h-5 ${
                    isSaved ? "fill-[#E11D48] text-[#E11D48]" : "text-[#211D2B]"
                  }`}
                />
              </button>
            </div>

            <button
              type="button"
              onClick={() => onSelectOutfit(outfit)}
              className="w-full text-left p-4 sm:p-5 block focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#7654E8]"
            >
              <div className="flex items-center gap-2 text-xs text-[#6E687B]">
                <span>{outfit.category}</span>
                <span aria-hidden="true">·</span>
                <span>{outfit.leadTime}</span>
              </div>
              <div className="mt-1 flex items-baseline justify-between gap-3">
                <h3 className="text-base font-bold text-[#211D2B] truncate">
                  {outfit.name}
                </h3>
                <span className="text-sm font-semibold text-[#7654E8] tabular-nums whitespace-nowrap shrink-0">
                  {outfit.priceLabel}
                </span>
              </div>
              <p className="text-xs text-[#6E687B] mt-1.5 line-clamp-2 leading-relaxed">
                {outfit.fabric}
              </p>
            </button>
          </article>
        );
      })}
    </div>
  );
};
