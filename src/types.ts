export type OutfitCategory = "Ankara" | "Traditional" | "Casual" | "Formal";

export interface Outfit {
  id: string;
  name: string;
  category: OutfitCategory;
  priceNaira: number;
  priceLabel: string;
  image: string;
  surfaceTint: string;
  aspectClass: string;
  fabric: string;
  leadTime: string;
  minDays: number;
  description: string;
}

export interface AtelierProfile {
  id: string;
  name: string;
  location: string;
  specialty: string;
  rating: number;
  completedCount: number;
  turnaround: string;
  surfaceTint: string;
  bio: string;
  startingPrice: string;
}

export type MeasurementKey =
  | "Chest"
  | "Waist"
  | "Hip"
  | "Shoulder"
  | "Sleeve"
  | "Inseam";

export type Measurements = Record<MeasurementKey, number>;

export interface ExtractedBodyDetails {
  bodyBuild: string;
  shoulderProfile: string;
  torsoProportion: string;
  postureNote: string;
  recommendedBaseSize: string;
  lightingAndFraming: string;
}

export interface FitAnalysisResult {
  measurements: Measurements;
  extractedDetails: ExtractedBodyDetails;
  silhouetteNote: string;
  easeRecommendation: string;
  tailorNotes: string[];
}

export interface FitProfile {
  id: string;
  label: string;
  heightCm: number;
  fitPreference: "Tailored" | "Relaxed" | "Structured";
  measurements: Measurements;
  analysis?: FitAnalysisResult | null;
  updatedAt: string;
}

export interface CustomStyleAnalysis {
  garmentTitle: string;
  categoryGuess: OutfitCategory;
  suggestedFabric: string;
  estimatedYards: string;
  constructionDetails: string[];
  estimatedLeadTime: string;
}

export type OrderStage =
  | "Design selected"
  | "Tailor confirmed"
  | "In production"
  | "Ready for delivery";

export type PaymentStatus =
  | "Deposit pending"
  | "50% deposit paid"
  | "Paid in full";

export interface OrderMessage {
  id: string;
  sender: "Client" | "Tailor";
  text: string;
  imageDataUrl?: string;
  timestamp: string;
}

export interface TailoringOrder {
  id: string;
  outfitName: string;
  outfitImage: string;
  isCustomInspiration?: boolean;
  customStyleAnalysis?: CustomStyleAnalysis | null;
  atelierName: string;
  atelierLocation: string;
  priceLabel: string;
  stage: OrderStage;
  paymentStatus: PaymentStatus;
  createdAt: string;
  eventDate?: string;
  isRushOrder?: boolean;
  appointmentSlot?: string;
  fabricChoice: string;
  fabricNote: string;
  fitProfileLabel: string;
  measurementsSnapshot: Measurements;
  tailorGuidance?: string;
  messages: OrderMessage[];
}

export interface UserAccount {
  name: string;
  email: string;
  isGuest?: boolean;
}

export interface AppSettings {
  notifications: boolean;
  measurementPrivacy: boolean;
}

export type MainTab =
  | "home"
  | "studio"
  | "book"
  | "saved"
  | "orders"
  | "profile"
  | "tailor-desk";

export type AuthView = "welcome" | "login" | "signup" | "forgot";
