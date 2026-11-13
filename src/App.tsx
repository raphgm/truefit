import React, { useEffect, useMemo, useState } from "react";
import { ArrowRight, Sparkles, Store } from "lucide-react";
import {
  DEFAULT_FIT_PROFILE,
  DEFAULT_MEASUREMENTS,
  HERO_ATELIER_IMAGE,
  HOUSE_ATELIER,
  OUTFITS,
} from "./data/catalog";
import {
  AppSettings,
  AuthView,
  CustomStyleAnalysis,
  FitProfile,
  MainTab,
  OrderStage,
  Outfit,
  OutfitCategory,
  PaymentStatus,
  TailoringOrder,
  UserAccount,
} from "./types";
import { AuthViews } from "./components/AuthViews";
import { DesktopTopBar, MobileBottomBar } from "./components/Navigation";
import { LookbookGrid } from "./components/LookbookGrid";
import { OutfitDetailModal } from "./components/OutfitDetailModal";
import { FitStudioView } from "./components/FitStudioView";
import { BookFittingView } from "./components/BookFittingView";
import { TailorDeskView } from "./components/TailorDeskView";
import { CutSheetModal } from "./components/CutSheetModal";
import {
  OrdersView,
  ProfileView,
  SavedLooksView,
} from "./components/ProfileAndSubViews";

const STORAGE_KEYS = {
  user: "truefit_user_v1",
  favorites: "truefit_favorites_v1",
  profiles: "truefit_fit_profiles_v1",
  activeProfileId: "truefit_active_profile_v1",
  orders: "truefit_orders_v2",
  settings: "truefit_settings_v1",
};

function loadFromStorage<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

export default function App() {
  const [user, setUser] = useState<UserAccount | null>(() =>
    loadFromStorage<UserAccount | null>(STORAGE_KEYS.user, null)
  );
  const [authView, setAuthView] = useState<AuthView>("welcome");
  const [activeTab, setActiveTab] = useState<MainTab>("home");
  const [selectedCategory, setSelectedCategory] = useState<
    "For You" | OutfitCategory
  >("For You");
  const [favorites, setFavorites] = useState<string[]>(() =>
    loadFromStorage<string[]>(STORAGE_KEYS.favorites, [])
  );
  const [fitProfiles, setFitProfiles] = useState<FitProfile[]>(() => {
    const stored = loadFromStorage<FitProfile[]>(STORAGE_KEYS.profiles, []);
    return stored.length > 0 ? stored : [DEFAULT_FIT_PROFILE];
  });
  const [activeProfileId, setActiveProfileId] = useState<string>(() =>
    loadFromStorage<string>(
      STORAGE_KEYS.activeProfileId,
      DEFAULT_FIT_PROFILE.id
    )
  );
  const [orders, setOrders] = useState<TailoringOrder[]>(() =>
    loadFromStorage<TailoringOrder[]>(STORAGE_KEYS.orders, [])
  );
  const [settings, setSettings] = useState<AppSettings>(() =>
    loadFromStorage<AppSettings>(STORAGE_KEYS.settings, {
      notifications: true,
      measurementPrivacy: true,
    })
  );

  const [selectedOutfit, setSelectedOutfit] = useState<Outfit | null>(null);
  const [preselectedOutfit, setPreselectedOutfit] = useState<Outfit | null>(null);
  const [cutSheetOrder, setCutSheetOrder] = useState<TailoringOrder | null>(
    null
  );
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    try {
      if (user) {
        localStorage.setItem(STORAGE_KEYS.user, JSON.stringify(user));
      } else {
        localStorage.removeItem(STORAGE_KEYS.user);
      }
    } catch {
      // Ignore storage quota issues
    }
  }, [user]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.favorites, JSON.stringify(favorites));
    } catch {
      // Ignore storage quota issues
    }
  }, [favorites]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.profiles, JSON.stringify(fitProfiles));
    } catch {
      // Ignore storage quota issues
    }
  }, [fitProfiles]);

  useEffect(() => {
    try {
      localStorage.setItem(
        STORAGE_KEYS.activeProfileId,
        JSON.stringify(activeProfileId)
      );
    } catch {
      // Ignore storage quota issues
    }
  }, [activeProfileId]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.orders, JSON.stringify(orders));
    } catch {
      // Ignore storage quota issues
    }
  }, [orders]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.settings, JSON.stringify(settings));
    } catch {
      // Ignore storage quota issues
    }
  }, [settings]);

  const notify = (msg: string) => {
    setToast(msg);
  };

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const toggleFavorite = (outfitId: string) => {
    setFavorites((prev) => {
      const exists = prev.includes(outfitId);
      const next = exists
        ? prev.filter((id) => id !== outfitId)
        : [...prev, outfitId];
      notify(exists ? "Removed from Saved Looks." : "Added to Saved Looks.");
      return next;
    });
  };

  const handleCreateFitProfile = (label: string) => {
    const newId = `profile-${Date.now()}`;
    const created: FitProfile = {
      id: newId,
      label,
      heightCm: 170,
      fitPreference: "Tailored",
      measurements: { ...DEFAULT_MEASUREMENTS },
      analysis: null,
      updatedAt: "New profile",
    };
    setFitProfiles((prev) => [...prev, created]);
    setActiveProfileId(newId);
    notify(`Created profile "${label}".`);
  };

  const handleDeleteFitProfile = (id: string) => {
    if (fitProfiles.length <= 1) return;
    setFitProfiles((prev) => {
      const remaining = prev.filter((p) => p.id !== id);
      if (activeProfileId === id && remaining.length > 0) {
        setActiveProfileId(remaining[0].id);
      }
      return remaining;
    });
    notify("Fit profile removed.");
  };

  const handleUpdateActiveProfile = (updater: (prev: FitProfile) => FitProfile) => {
    setFitProfiles((prev) =>
      prev.map((p) => (p.id === activeProfileId ? updater(p) : p))
    );
  };

  const handleSaveFitProfile = (profile: FitProfile) => {
    setFitProfiles((prev) =>
      prev.map((p) => (p.id === profile.id ? profile : p))
    );
    notify(`"${profile.label}" saved.`);
  };

  const handleBookFitting = (outfit: Outfit) => {
    setSelectedOutfit(null);
    setPreselectedOutfit(outfit);
    setActiveTab("book");
  };

  const handlePlaceOrder = ({
    outfitName,
    outfitImage,
    priceLabel,
    isCustomInspiration,
    customStyleAnalysis,
    fabricChoice,
    fabricNote,
    eventDate,
    isRushOrder,
    appointmentSlot,
    profile,
  }: {
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
  }) => {
    const guidanceParts: string[] = [];
    if (profile.analysis?.easeRecommendation) {
      guidanceParts.push(`Ease: ${profile.analysis.easeRecommendation}`);
    }
    if (profile.analysis?.extractedDetails?.postureNote) {
      guidanceParts.push(
        `Posture: ${profile.analysis.extractedDetails.postureNote}`
      );
    }
    if (customStyleAnalysis) {
      guidanceParts.push(
        `Yardage: ${customStyleAnalysis.estimatedYards} (${customStyleAnalysis.suggestedFabric})`
      );
    }

    const newOrder: TailoringOrder = {
      id: `TF-${Math.floor(1000 + Math.random() * 9000)}`,
      outfitName,
      outfitImage,
      isCustomInspiration,
      customStyleAnalysis: customStyleAnalysis || null,
      atelierName: HOUSE_ATELIER.name,
      atelierLocation: HOUSE_ATELIER.location,
      priceLabel,
      stage: "Design selected",
      paymentStatus: "Deposit pending",
      createdAt: new Date().toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      }),
      eventDate,
      isRushOrder,
      appointmentSlot,
      fabricChoice,
      fabricNote,
      fitProfileLabel: profile.label,
      measurementsSnapshot: { ...profile.measurements },
      tailorGuidance: guidanceParts.join(" · ") || undefined,
      messages: [],
    };
    setOrders((prev) => [newOrder, ...prev]);
    setActiveTab("orders");
    notify(`Order ${newOrder.id} submitted to ${HOUSE_ATELIER.name}.`);
  };

  const handleSetOrderStage = (orderId: string, stage: OrderStage) => {
    setOrders((prev) =>
      prev.map((order) => (order.id === orderId ? { ...order, stage } : order))
    );
    notify(`Order ${orderId} moved to "${stage}".`);
  };

  const handleSetPaymentStatus = (orderId: string, paymentStatus: PaymentStatus) => {
    setOrders((prev) =>
      prev.map((order) =>
        order.id === orderId ? { ...order, paymentStatus } : order
      )
    );
    notify(`Payment status updated to "${paymentStatus}".`);
  };

  const handlePostOrderMessage = (
    orderId: string,
    sender: "Client" | "Tailor",
    text: string,
    imageDataUrl?: string
  ) => {
    const timestamp = new Date().toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
    });
    setOrders((prev) =>
      prev.map((order) => {
        if (order.id !== orderId) return order;
        return {
          ...order,
          messages: [
            ...order.messages,
            {
              id: `msg-${Date.now()}`,
              sender,
              text,
              imageDataUrl,
              timestamp,
            },
          ],
        };
      })
    );
    notify(
      sender === "Tailor"
        ? "Fitting update sent to client."
        : "Message sent to the studio."
    );
  };

  const filteredOutfits = useMemo(() => {
    if (selectedCategory === "For You") return OUTFITS;
    return OUTFITS.filter((o) => o.category === selectedCategory);
  }, [selectedCategory]);

  const categories: ("For You" | OutfitCategory)[] = [
    "For You",
    "Ankara",
    "Traditional",
    "Casual",
    "Formal",
  ];

  if (!user) {
    return (
      <>
        <AuthViews
          view={authView}
          onChangeView={setAuthView}
          onAuthenticate={(account) => {
            setUser(account);
            setActiveTab("home");
          }}
          onNotify={notify}
        />
        {toast && <ToastBanner message={toast} />}
      </>
    );
  }

  return (
    <div className="min-h-screen bg-[#FAF8FC] text-[#211D2B] pb-20 md:pb-8 flex flex-col">
      <DesktopTopBar
        activeTab={activeTab}
        onSelectTab={setActiveTab}
        user={user}
        savedCount={favorites.length}
        ordersCount={orders.length}
      />

      <main className="flex-1">
        {activeTab === "home" && (
          <div className="max-w-6xl mx-auto px-5 sm:px-6 py-8 space-y-10">
            {/* Editorial Split Hero */}
            <section className="rounded-3xl bg-[#211D2B] text-white overflow-hidden grid grid-cols-1 lg:grid-cols-12 items-stretch shadow-[0_20px_50px_rgba(33,29,43,0.12)]">
              <div className="lg:col-span-7 p-7 sm:p-10 lg:p-12 flex flex-col justify-center space-y-5">
                <p className="text-xs font-semibold tracking-wider uppercase text-[#EAE3FF]">
                  {HOUSE_ATELIER.name} · Bespoke Studio
                </p>
                <h1 className="font-display text-3xl sm:text-5xl font-bold leading-[1.1] tracking-tight text-balance">
                  Your perfect fit. Your own style.
                </h1>
                <p className="text-sm sm:text-base text-white/80 max-w-lg leading-relaxed">
                  Explore made-to-measure Ankara, traditional, and contemporary silhouettes,
                  capture your measurements automatically, or upload your own style inspiration.
                </p>
                <div className="pt-2 flex flex-wrap items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setActiveTab("studio")}
                    className="px-6 py-3.5 rounded-xl bg-white text-[#7654E8] font-bold text-sm hover:bg-[#EAE3FF] transition-colors min-h-[48px] whitespace-nowrap"
                  >
                    Create My Fit Profile
                  </button>
                  <button
                    type="button"
                    onClick={() => setActiveTab("book")}
                    className="px-5 py-3.5 rounded-xl border border-white/25 text-white font-semibold text-sm hover:bg-white/10 transition-colors min-h-[48px] whitespace-nowrap"
                  >
                    Book a Fitting
                  </button>
                </div>
              </div>

              <div className="lg:col-span-5 relative min-h-[240px] lg:min-h-full">
                <img
                  src={HERO_ATELIER_IMAGE}
                  alt="TrueFit AI tailoring studio"
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t lg:bg-gradient-to-r from-[#211D2B]/70 via-transparent to-transparent" />
              </div>
            </section>

            {/* AI Measurement Studio Callout Strip */}
            <section>
              <button
                type="button"
                onClick={() => setActiveTab("studio")}
                className="w-full text-left rounded-2xl bg-[#EAE3FF] hover:bg-[#E1D7FF] transition-colors px-5 py-4 sm:px-6 sm:py-5 flex items-center justify-between gap-4"
              >
                <div className="flex items-center gap-4 min-w-0">
                  <div className="w-11 h-11 rounded-xl bg-white text-[#7654E8] flex items-center justify-center shrink-0">
                    <Sparkles className="w-5 h-5" />
                  </div>
                  <div className="min-w-0">
                    <h2 className="text-sm sm:text-base font-bold text-[#211D2B] truncate">
                      AI Measurement Studio
                    </h2>
                    <p className="text-xs text-[#6E687B] mt-0.5 truncate">
                      Two-angle photo scan &amp; named fit profiles for individual or group fittings.
                    </p>
                  </div>
                </div>
                <ArrowRight className="w-5 h-5 text-[#7654E8] shrink-0" />
              </button>
            </section>

            {/* Lookbook Category Tabs + Staggered Grid */}
            <section className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
                <div>
                  <h2 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B] tracking-tight">
                    Find your next look
                  </h2>
                </div>

                <div className="flex items-center gap-1.5 overflow-x-auto pb-1">
                  {categories.map((cat) => {
                    const active = selectedCategory === cat;
                    return (
                      <button
                        key={cat}
                        type="button"
                        onClick={() => setSelectedCategory(cat)}
                        className={`px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap shrink-0 min-h-[40px] transition-colors ${
                          active
                            ? "bg-[#7654E8] text-white"
                            : "bg-white text-[#211D2B] border border-[#211D2B]/8 hover:bg-[#EAE3FF]/60"
                        }`}
                      >
                        {cat}
                      </button>
                    );
                  })}
                </div>
              </div>

              <LookbookGrid
                outfits={filteredOutfits}
                favorites={favorites}
                onToggleFavorite={toggleFavorite}
                onSelectOutfit={setSelectedOutfit}
              />
            </section>

            {/* Single Atelier Booking Banner */}
            <section className="rounded-3xl bg-[#DDF5E8] p-7 sm:p-9 flex flex-col sm:flex-row sm:items-center justify-between gap-6">
              <div className="space-y-2 max-w-xl">
                <Store className="w-6 h-6 text-[#1E7E50]" />
                <h2 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B]">
                  Ready for your custom piece?
                </h2>
                <p className="text-sm text-[#395246]">
                  Choose a lookbook piece or upload your own style inspiration, select your fabric
                  and event date, and book directly with {HOUSE_ATELIER.name}.
                </p>
              </div>
              <button
                type="button"
                onClick={() => setActiveTab("book")}
                className="px-6 py-3.5 rounded-xl bg-[#1E7E50] text-white font-semibold text-sm hover:bg-[#176540] transition-colors min-h-[48px] whitespace-nowrap shrink-0 self-start sm:self-center"
              >
                Book Your Fitting
              </button>
            </section>
          </div>
        )}

        {activeTab === "studio" && (
          <FitStudioView
            profiles={fitProfiles}
            activeProfileId={activeProfileId}
            onSelectProfile={setActiveProfileId}
            onCreateProfile={handleCreateFitProfile}
            onDeleteProfile={handleDeleteFitProfile}
            onUpdateActiveProfile={handleUpdateActiveProfile}
            onSaveProfile={handleSaveFitProfile}
            onNotify={notify}
          />
        )}

        {activeTab === "book" && (
          <BookFittingView
            profiles={fitProfiles}
            activeProfileId={activeProfileId}
            onSelectProfile={setActiveProfileId}
            preselectedOutfit={preselectedOutfit}
            onClearPreselected={() => setPreselectedOutfit(null)}
            onOpenFitStudio={() => setActiveTab("studio")}
            onPlaceOrder={handlePlaceOrder}
            onNotify={notify}
          />
        )}

        {activeTab === "saved" && (
          <SavedLooksView
            favorites={favorites}
            onToggleFavorite={toggleFavorite}
            onSelectOutfit={setSelectedOutfit}
            onExplore={() => setActiveTab("home")}
          />
        )}

        {activeTab === "orders" && (
          <OrdersView
            orders={orders}
            onBookFitting={() => setActiveTab("book")}
            onOpenCutSheet={setCutSheetOrder}
            onSendClientMessage={(orderId, text) =>
              handlePostOrderMessage(orderId, "Client", text)
            }
            onOpenTailorDesk={() => setActiveTab("tailor-desk")}
          />
        )}

        {activeTab === "tailor-desk" && (
          <TailorDeskView
            orders={orders}
            onSetOrderStage={handleSetOrderStage}
            onSetPaymentStatus={handleSetPaymentStatus}
            onPostTailorUpdate={(orderId, text, imageDataUrl) =>
              handlePostOrderMessage(orderId, "Tailor", text, imageDataUrl)
            }
            onOpenCutSheet={setCutSheetOrder}
          />
        )}

        {activeTab === "profile" && (
          <ProfileView
            user={user}
            savedCount={favorites.length}
            ordersCount={orders.length}
            profilesCount={fitProfiles.length}
            settings={settings}
            onUpdateSettings={(next) => {
              setSettings(next);
              notify("Preferences updated.");
            }}
            onNavigate={setActiveTab}
            onSignOut={() => {
              setUser(null);
              setAuthView("welcome");
              notify("Signed out.");
            }}
          />
        )}
      </main>

      <MobileBottomBar activeTab={activeTab} onSelectTab={setActiveTab} />

      <OutfitDetailModal
        outfit={selectedOutfit}
        isSaved={selectedOutfit ? favorites.includes(selectedOutfit.id) : false}
        onClose={() => setSelectedOutfit(null)}
        onToggleSave={toggleFavorite}
        onBookFitting={handleBookFitting}
      />

      <CutSheetModal
        order={cutSheetOrder}
        onClose={() => setCutSheetOrder(null)}
      />

      {toast && <ToastBanner message={toast} />}
    </div>
  );
}

function ToastBanner({ message }: { message: string }) {
  return (
    <div
      role="status"
      aria-live="polite"
      className="fixed bottom-20 md:bottom-6 left-1/2 -translate-x-1/2 z-[60] px-5 py-3 rounded-2xl bg-[#211D2B] text-white text-xs sm:text-sm font-medium shadow-xl max-w-[90vw] text-center"
    >
      {message}
    </div>
  );
}
