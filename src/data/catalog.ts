import { AtelierProfile, FitProfile, Measurements, OrderStage, Outfit } from "../types";

export const HERO_ATELIER_IMAGE =
  "/images/hero_atelier_studio_1794553282744.jpg";

export const DEFAULT_MEASUREMENTS: Measurements = {
  Chest: 96,
  Waist: 82,
  Hip: 100,
  Shoulder: 42,
  Sleeve: 60,
  Inseam: 78,
};

export const DEFAULT_FIT_PROFILE: FitProfile = {
  id: "profile-primary",
  label: "My Fit Profile",
  heightCm: 174,
  fitPreference: "Tailored",
  measurements: DEFAULT_MEASUREMENTS,
  analysis: null,
  updatedAt: "Baseline profile",
};

export const HOUSE_ATELIER: AtelierProfile = {
  id: "ifeoma-couture",
  name: "Ifeoma Couture",
  location: "Abuja, Nigeria",
  specialty: "Bespoke Ankara, Traditional & Contemporary Tailoring",
  rating: 4.9,
  completedCount: 340,
  turnaround: "7–14 days",
  surfaceTint: "#FFE9D9",
  startingPrice: "From ₦18,000",
  bio: "Private bespoke tailoring studio specializing in precision-cut Ankara silhouettes, contemporary Agbada ensembles, fluid silk boubous, and made-to-measure suiting.",
};

export const STUDIO_FABRICS = [
  "Use lookbook house fabric",
  "100% Dutch Wax Cotton (Ankara)",
  "Cashmere-Blend Guinea Brocade",
  "Breathable Belgian Linen",
  "Silk Crepe with Hand-Beading",
  "Super 120s Charcoal Merino Wool",
  "Client supplying own fabric",
];

export const FITTING_TIME_SLOTS = [
  "No appointment needed (measurements already scanned)",
  "Studio Fitting · Tomorrow 11:00 AM",
  "Studio Fitting · Tomorrow 3:00 PM",
  "Studio Fitting · This Friday 11:00 AM",
  "Virtual Video Check-In · Saturday 1:00 PM",
];

export const OUTFITS: Outfit[] = [
  {
    id: "ankara-elegance",
    name: "Ankara Elegance",
    category: "Ankara",
    priceNaira: 25000,
    priceLabel: "From ₦25,000",
    image: "/images/outfit_ankara_elegance_1794553281847.jpg",
    surfaceTint: "#FFE4EF",
    aspectClass: "aspect-[3/4]",
    fabric: "100% Dutch Wax Cotton",
    leadTime: "7–10 days",
    minDays: 7,
    description:
      "Structured square-neckline midi dress with sculpted volume sleeves and tailored waist darting cut to your exact bodice proportions.",
  },
  {
    id: "modern-agbada",
    name: "Modern Agbada",
    category: "Traditional",
    priceNaira: 45000,
    priceLabel: "From ₦45,000",
    image: "/images/outfit_modern_agbada_1794553282980.jpg",
    surfaceTint: "#EAE3FF",
    aspectClass: "aspect-[4/5]",
    fabric: "Midweight Cashmere-Blend Guinea Brocade",
    leadTime: "10–14 days",
    minDays: 10,
    description:
      "Architectural three-piece Agbada with tonal geometric neckline embroidery and crisp shoulder drape balanced to your frame height.",
  },
  {
    id: "minimalist-chic",
    name: "Minimalist Chic",
    category: "Casual",
    priceNaira: 18000,
    priceLabel: "From ₦18,000",
    image: "/images/outfit_minimalist_chic_1794553283564.jpg",
    surfaceTint: "#FFE9D9",
    aspectClass: "aspect-[4/5]",
    fabric: "Breathable Belgian Linen",
    leadTime: "5–7 days",
    minDays: 5,
    description:
      "Relaxed single-breasted linen blazer and high-waisted wide-leg trousers engineered for effortless daylight tailoring.",
  },
  {
    id: "classic-suit",
    name: "Classic Suit",
    category: "Formal",
    priceNaira: 55000,
    priceLabel: "From ₦55,000",
    image: "/images/outfit_classic_suit_1794553283624.jpg",
    surfaceTint: "#E5ECF6",
    aspectClass: "aspect-[3/4]",
    fabric: "Super 120s Charcoal Merino Wool",
    leadTime: "14–18 days",
    minDays: 14,
    description:
      "Full-canvas two-piece suit with clean peak lapels, natural roped shoulders, and trousers hemmed to your exact inseam.",
  },
  {
    id: "elegant-boubou",
    name: "Elegant Boubou",
    category: "Traditional",
    priceNaira: 35000,
    priceLabel: "From ₦35,000",
    image: "/images/outfit_elegant_boubou_1794553285121.jpg",
    surfaceTint: "#DDF5E8",
    aspectClass: "aspect-[3/4]",
    fabric: "Silk Crepe with Hand-Beaded Trim",
    leadTime: "8–12 days",
    minDays: 8,
    description:
      "Fluid full-length Boubou kaftan featuring artisanal beadwork along the keyhole collar and proportioned sleeve drop.",
  },
  {
    id: "weekend-fit",
    name: "Weekend Fit",
    category: "Casual",
    priceNaira: 20000,
    priceLabel: "From ₦20,000",
    image: "/images/outfit_weekend_fit_1794553285372.jpg",
    surfaceTint: "#FFE4EF",
    aspectClass: "aspect-[4/5]",
    fabric: "Slub Textured Cotton & Twill",
    leadTime: "5–8 days",
    minDays: 5,
    description:
      "Open camp-collar textured shirt paired with double-pleated tapered trousers designed for clean everyday movement.",
  },
];

export const HOW_IT_WORKS_STEPS = [
  {
    number: "01",
    title: "Choose or upload a look",
    subtitle: "Pick from the studio lookbook or upload your own inspiration photo.",
  },
  {
    number: "02",
    title: "Scan your fit profile",
    subtitle: "Capture front & optional side measurements in Fit Studio.",
  },
  {
    number: "03",
    title: "Select fabric & date",
    subtitle: "Choose fabric, schedule a fitting slot, and attach a fit profile.",
  },
  {
    number: "04",
    title: "Track WIP & delivery",
    subtitle: "Receive fitting photos, stage updates, and delivery notices.",
  },
];

export const ORDER_JOURNEY_STAGES: { stage: OrderStage; description: string }[] = [
  { stage: "Design selected", description: "Your style and measurements are received." },
  {
    stage: "Tailor confirmed",
    description: "The studio confirms fabric availability and cut schedule.",
  },
  { stage: "In production", description: "Your garment is being cut and sewn." },
  {
    stage: "Ready for delivery",
    description: "Your custom outfit is finished and ready for pickup or dispatch.",
  },
];
