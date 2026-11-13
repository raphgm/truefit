import React, { useState } from "react";
import {
  Briefcase,
  CheckCircle2,
  ChevronRight,
  FileText,
  Heart,
  HelpCircle,
  LogOut,
  MessageSquare,
  Printer,
  Ruler,
  Send,
  Settings,
  Shield,
  ShoppingBag,
  Store,
  User,
  X,
} from "lucide-react";
import { ORDER_JOURNEY_STAGES, OUTFITS } from "../data/catalog";
import {
  AppSettings,
  MainTab,
  Outfit,
  TailoringOrder,
  UserAccount,
} from "../types";
import { LookbookGrid } from "./LookbookGrid";

export const SavedLooksView: React.FC<{
  favorites: string[];
  onToggleFavorite: (id: string) => void;
  onSelectOutfit: (outfit: Outfit) => void;
  onExplore: () => void;
}> = ({ favorites, onToggleFavorite, onSelectOutfit, onExplore }) => {
  const savedOutfits = OUTFITS.filter((o) => favorites.includes(o.id));

  return (
    <div className="max-w-6xl mx-auto px-5 sm:px-6 py-8 space-y-8">
      <div>
        <h1 className="font-display text-3xl sm:text-4xl font-bold text-[#211D2B] tracking-tight">
          Saved Looks
        </h1>
        <p className="text-sm text-[#6E687B] mt-1">
          Your personal curation of custom styles ready to commission.
        </p>
      </div>

      {savedOutfits.length === 0 ? (
        <div className="rounded-3xl bg-white border border-[#211D2B]/8 p-12 text-center max-w-xl mx-auto">
          <Heart className="w-12 h-12 text-[#7654E8] mx-auto mb-3" />
          <h2 className="font-display text-2xl font-bold text-[#211D2B]">
            No saved looks yet
          </h2>
          <p className="text-sm text-[#6E687B] mt-1.5">
            Explore the lookbook and tap the heart on any design you love.
          </p>
          <button
            type="button"
            onClick={onExplore}
            className="mt-6 px-6 py-3 rounded-xl bg-[#7654E8] text-white text-sm font-semibold hover:bg-[#6442D6] transition-colors min-h-[44px]"
          >
            Browse Lookbook
          </button>
        </div>
      ) : (
        <LookbookGrid
          outfits={savedOutfits}
          favorites={favorites}
          onToggleFavorite={onToggleFavorite}
          onSelectOutfit={onSelectOutfit}
        />
      )}
    </div>
  );
};

export const OrdersView: React.FC<{
  orders: TailoringOrder[];
  onBookFitting: () => void;
  onOpenCutSheet: (order: TailoringOrder) => void;
  onSendClientMessage: (orderId: string, text: string) => void;
  onOpenTailorDesk: () => void;
}> = ({
  orders,
  onBookFitting,
  onOpenCutSheet,
  onSendClientMessage,
  onOpenTailorDesk,
}) => {
  const [drafts, setDrafts] = useState<Record<string, string>>({});

  const submitMessage = (orderId: string) => {
    const text = (drafts[orderId] || "").trim();
    if (!text) return;
    onSendClientMessage(orderId, text);
    setDrafts((prev) => ({ ...prev, [orderId]: "" }));
  };

  return (
    <div className="max-w-5xl mx-auto px-5 sm:px-6 py-8 space-y-10">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="font-display text-3xl sm:text-4xl font-bold text-[#211D2B] tracking-tight">
            My Orders
          </h1>
          <p className="text-sm text-[#6E687B] mt-1">
            Track each custom garment, inspect fitting updates, and print your measurement sheet.
          </p>
        </div>

        <button
          type="button"
          onClick={onOpenTailorDesk}
          className="px-4 py-2.5 rounded-xl bg-white border border-[#211D2B]/12 text-xs font-semibold text-[#211D2B] hover:bg-[#EAE3FF]/50 transition-colors inline-flex items-center gap-2 self-start min-h-[42px]"
        >
          <Briefcase className="w-4 h-4 text-[#7654E8]" />
          <span>Tailor Studio Desk</span>
        </button>
      </div>

      {orders.length === 0 ? (
        <div className="rounded-3xl bg-[#EAE3FF]/70 p-8 sm:p-10 text-center space-y-3">
          <ShoppingBag className="w-11 h-11 text-[#7654E8] mx-auto" />
          <h2 className="font-display text-2xl font-bold text-[#211D2B]">
            Your tailoring orders
          </h2>
          <p className="text-sm text-[#6E687B] max-w-md mx-auto">
            Your custom commissions will appear here once you submit a fitting request.
          </p>
          <div className="pt-2">
            <button
              type="button"
              onClick={onBookFitting}
              className="px-6 py-3 rounded-xl bg-[#7654E8] text-white text-sm font-semibold hover:bg-[#6442D6] transition-colors min-h-[44px]"
            >
              Book a Fitting
            </button>
          </div>
        </div>
      ) : (
        <div className="space-y-6">
          {orders.map((order) => {
            const stageIdx = ORDER_JOURNEY_STAGES.findIndex(
              (s) => s.stage === order.stage
            );

            return (
              <article
                key={order.id}
                className="bg-white rounded-3xl p-5 sm:p-6 border border-[#211D2B]/8 space-y-5 shadow-[0_8px_24px_rgba(33,29,43,0.04)]"
              >
                <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
                  <div className="flex items-start gap-4">
                    <img
                      src={order.outfitImage}
                      alt={order.outfitName}
                      referrerPolicy="no-referrer"
                      className="w-16 h-22 rounded-2xl object-cover bg-[#EAE3FF] shrink-0"
                    />
                    <div className="space-y-1">
                      <p className="text-xs text-[#6E687B] font-mono tabular-nums">
                        {order.id} · {order.createdAt}
                        {order.isRushOrder ? " · Rush request" : ""}
                      </p>
                      <h2 className="text-lg font-bold text-[#211D2B]">
                        {order.outfitName}
                      </h2>
                      <p className="text-xs text-[#6E687B]">
                        {order.atelierName} · Profile: {order.fitProfileLabel} ·{" "}
                        {order.priceLabel}
                      </p>
                      <p className="text-xs text-[#6E687B]">
                        Fabric: {order.fabricChoice}
                        {order.eventDate ? ` · Event: ${order.eventDate}` : ""}
                      </p>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-2.5 self-start">
                    <span className="text-xs font-semibold text-[#7654E8]">
                      {order.stage} · {order.paymentStatus}
                    </span>
                    <button
                      type="button"
                      onClick={() => onOpenCutSheet(order)}
                      className="px-3.5 py-2 rounded-xl border border-[#211D2B]/12 text-xs font-semibold text-[#211D2B] hover:bg-[#FAF8FC] inline-flex items-center gap-1.5 min-h-[38px]"
                    >
                      <Printer className="w-3.5 h-3.5 text-[#7654E8]" />
                      <span>Cut-Sheet</span>
                    </button>
                  </div>
                </div>

                {/* Stage Progress Bar */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-3 border-t border-[#211D2B]/8">
                  {ORDER_JOURNEY_STAGES.map((step, idx) => {
                    const reached = idx <= stageIdx;
                    return (
                      <div key={step.stage} className="space-y-1">
                        <div
                          className={`h-1.5 rounded-full ${
                            reached ? "bg-[#7654E8]" : "bg-[#EAE3FF]"
                          }`}
                        />
                        <p
                          className={`text-xs font-semibold ${
                            reached ? "text-[#211D2B]" : "text-[#6E687B]"
                          }`}
                        >
                          {step.stage}
                        </p>
                      </div>
                    );
                  })}
                </div>

                {/* Client–Tailor WIP Updates & Thread */}
                <div className="pt-4 border-t border-[#211D2B]/8 space-y-3">
                  <div className="flex items-center gap-2 text-xs font-bold text-[#211D2B]">
                    <MessageSquare className="w-3.5 h-3.5 text-[#7654E8]" />
                    <span>Studio Updates &amp; Fitting Notes</span>
                  </div>

                  {order.messages.length === 0 ? (
                    <p className="text-xs text-[#6E687B]">
                      No fitting photos or notes posted yet. Leave a question for the studio below.
                    </p>
                  ) : (
                    <div className="space-y-2.5">
                      {order.messages.map((msg) => (
                        <div
                          key={msg.id}
                          className={`rounded-2xl p-3.5 text-xs space-y-2 ${
                            msg.sender === "Tailor"
                              ? "bg-[#EAE3FF]/50 text-[#211D2B]"
                              : "bg-[#FAF8FC] border border-[#211D2B]/8 text-[#211D2B]"
                          }`}
                        >
                          <div className="flex items-center justify-between gap-2 text-[11px] text-[#6E687B]">
                            <span className="font-bold text-[#211D2B]">
                              {msg.sender === "Tailor"
                                ? order.atelierName
                                : "You"}
                            </span>
                            <span>{msg.timestamp}</span>
                          </div>
                          <p className="leading-relaxed">{msg.text}</p>
                          {msg.imageDataUrl && (
                            <img
                              src={msg.imageDataUrl}
                              alt="Work in progress fitting update"
                              className="w-40 h-40 object-cover rounded-xl border border-[#211D2B]/10"
                            />
                          )}
                        </div>
                      ))}
                    </div>
                  )}

                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={drafts[order.id] || ""}
                      onChange={(e) =>
                        setDrafts((prev) => ({
                          ...prev,
                          [order.id]: e.target.value,
                        }))
                      }
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          e.preventDefault();
                          submitMessage(order.id);
                        }
                      }}
                      placeholder="Message the studio about your fitting or delivery..."
                      className="flex-1 px-3.5 py-2.5 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/12 text-xs text-[#211D2B] focus:outline-none focus:border-[#7654E8]"
                    />
                    <button
                      type="button"
                      onClick={() => submitMessage(order.id)}
                      className="px-4 py-2.5 rounded-xl bg-[#7654E8] text-white text-xs font-semibold inline-flex items-center gap-1.5 hover:bg-[#6442D6] min-h-[40px]"
                    >
                      <Send className="w-3.5 h-3.5" />
                      <span>Send</span>
                    </button>
                  </div>
                </div>
              </article>
            );
          })}
        </div>
      )}

      <section className="space-y-4">
        <h2 className="font-display text-xl sm:text-2xl font-bold text-[#211D2B]">
          Order journey
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {ORDER_JOURNEY_STAGES.map((item) => (
            <div
              key={item.stage}
              className="bg-white rounded-2xl p-4 border border-[#211D2B]/8 flex items-start gap-3.5"
            >
              <div className="w-10 h-10 rounded-full bg-[#EAE3FF] text-[#7654E8] flex items-center justify-center shrink-0">
                <CheckCircle2 className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-[#211D2B]">{item.stage}</h3>
                <p className="text-xs text-[#6E687B] mt-0.5">{item.description}</p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

export const ProfileView: React.FC<{
  user: UserAccount;
  savedCount: number;
  ordersCount: number;
  profilesCount: number;
  settings: AppSettings;
  onUpdateSettings: (next: AppSettings) => void;
  onNavigate: (tab: MainTab) => void;
  onSignOut: () => void;
}> = ({
  user,
  savedCount,
  ordersCount,
  profilesCount,
  settings,
  onUpdateSettings,
  onNavigate,
  onSignOut,
}) => {
  const [activeSheet, setActiveSheet] = useState<
    null | "settings" | "terms" | "privacy" | "help"
  >(null);

  const menuRows: {
    icon: React.ComponentType<{ className?: string }>;
    title: string;
    subtitle: string;
    action: () => void;
  }[] = [
    {
      icon: Heart,
      title: "Saved Looks",
      subtitle: `${savedCount} saved ${savedCount === 1 ? "design" : "designs"}`,
      action: () => onNavigate("saved"),
    },
    {
      icon: Ruler,
      title: "My Fit Profiles",
      subtitle: `${profilesCount} measurement ${profilesCount === 1 ? "profile" : "profiles"} saved`,
      action: () => onNavigate("studio"),
    },
    {
      icon: ShoppingBag,
      title: "My Orders",
      subtitle: `${ordersCount} custom ${ordersCount === 1 ? "order" : "orders"}`,
      action: () => onNavigate("orders"),
    },
    {
      icon: Store,
      title: "Book a Fitting",
      subtitle: "Studio details & submit a custom order",
      action: () => onNavigate("book"),
    },
    {
      icon: Briefcase,
      title: "Tailor Studio Desk",
      subtitle: "Manage incoming orders, WIP photos, payments & cut-sheets",
      action: () => onNavigate("tailor-desk"),
    },
    {
      icon: Settings,
      title: "Settings & Privacy",
      subtitle: "Notifications and measurement privacy",
      action: () => setActiveSheet("settings"),
    },
    {
      icon: HelpCircle,
      title: "Help & Support",
      subtitle: "Measuring tips and order assistance",
      action: () => setActiveSheet("help"),
    },
  ];

  return (
    <div className="max-w-3xl mx-auto px-5 sm:px-6 py-8 space-y-8">
      <div className="bg-white rounded-3xl p-6 sm:p-8 border border-[#211D2B]/8 flex flex-col sm:flex-row items-center gap-5 text-center sm:text-left">
        <div className="w-20 h-20 rounded-full bg-[#FFE4EF] text-[#7654E8] flex items-center justify-center shrink-0">
          <User className="w-9 h-9" />
        </div>
        <div className="flex-1 min-w-0">
          <h1 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B]">
            {user.name}
          </h1>
          <p className="text-sm text-[#6E687B] mt-0.5">{user.email}</p>
          <p className="text-xs text-[#6E687B] mt-2">
            Personal fashion space · {savedCount} saved · {ordersCount} orders
          </p>
        </div>
        <button
          type="button"
          onClick={onSignOut}
          className="px-4 py-2.5 rounded-xl border border-[#211D2B]/15 text-xs font-semibold text-[#211D2B] hover:bg-[#FFE4EF]/60 transition-colors inline-flex items-center gap-2 min-h-[44px]"
        >
          <LogOut className="w-4 h-4" />
          <span>Sign Out</span>
        </button>
      </div>

      <div className="bg-white rounded-3xl border border-[#211D2B]/8 divide-y divide-[#211D2B]/8 overflow-hidden">
        {menuRows.map((row) => {
          const Icon = row.icon;
          return (
            <button
              key={row.title}
              type="button"
              onClick={row.action}
              className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-[#FAF8FC] transition-colors min-h-[68px]"
            >
              <div className="w-11 h-11 rounded-2xl bg-[#EAE3FF] text-[#7654E8] flex items-center justify-center shrink-0">
                <Icon className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-[#211D2B]">{row.title}</p>
                <p className="text-xs text-[#6E687B] mt-0.5">{row.subtitle}</p>
              </div>
              <ChevronRight className="w-4 h-4 text-[#6E687B] shrink-0" />
            </button>
          );
        })}
      </div>

      {activeSheet && (
        <div
          className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-[#211D2B]/55 backdrop-blur-sm p-0 md:p-6"
          onClick={() => setActiveSheet(null)}
        >
          <div
            role="dialog"
            aria-modal="true"
            onClick={(e) => e.stopPropagation()}
            className="w-full md:max-w-lg bg-[#FAF8FC] rounded-t-3xl md:rounded-3xl p-6 sm:p-7 shadow-2xl space-y-5"
          >
            <div className="flex items-center justify-between">
              <h2 className="font-display text-2xl font-bold text-[#211D2B]">
                {activeSheet === "settings" && "Settings & Privacy"}
                {activeSheet === "terms" && "Terms & Conditions"}
                {activeSheet === "privacy" && "Privacy Policy"}
                {activeSheet === "help" && "Help & Support"}
              </h2>
              <button
                type="button"
                aria-label="Close panel"
                onClick={() => setActiveSheet(null)}
                className="w-10 h-10 rounded-full bg-white border border-[#211D2B]/10 flex items-center justify-center"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {activeSheet === "settings" && (
              <div className="space-y-4">
                <label className="flex items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-[#211D2B]/8 cursor-pointer">
                  <div>
                    <p className="text-sm font-bold text-[#211D2B]">
                      Notifications
                    </p>
                    <p className="text-xs text-[#6E687B]">
                      Get style curation and tailoring order updates
                    </p>
                  </div>
                  <input
                    type="checkbox"
                    checked={settings.notifications}
                    onChange={(e) =>
                      onUpdateSettings({
                        ...settings,
                        notifications: e.target.checked,
                      })
                    }
                    className="w-5 h-5 accent-[#7654E8]"
                  />
                </label>

                <label className="flex items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-[#211D2B]/8 cursor-pointer">
                  <div>
                    <p className="text-sm font-bold text-[#211D2B]">
                      Measurement privacy
                    </p>
                    <p className="text-xs text-[#6E687B]">
                      Share measurements only when submitting a custom order
                    </p>
                  </div>
                  <input
                    type="checkbox"
                    checked={settings.measurementPrivacy}
                    onChange={(e) =>
                      onUpdateSettings({
                        ...settings,
                        measurementPrivacy: e.target.checked,
                      })
                    }
                    className="w-5 h-5 accent-[#7654E8]"
                  />
                </label>

                <div className="pt-2 space-y-2">
                  <button
                    type="button"
                    onClick={() => setActiveSheet("terms")}
                    className="w-full flex items-center gap-3 p-3.5 rounded-2xl bg-white border border-[#211D2B]/8 text-left hover:bg-[#EAE3FF]/40"
                  >
                    <FileText className="w-4 h-4 text-[#7654E8]" />
                    <span className="text-sm font-medium text-[#211D2B]">
                      Terms &amp; Conditions
                    </span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setActiveSheet("privacy")}
                    className="w-full flex items-center gap-3 p-3.5 rounded-2xl bg-white border border-[#211D2B]/8 text-left hover:bg-[#EAE3FF]/40"
                  >
                    <Shield className="w-4 h-4 text-[#7654E8]" />
                    <span className="text-sm font-medium text-[#211D2B]">
                      Privacy Policy
                    </span>
                  </button>
                </div>
              </div>
            )}

            {activeSheet === "terms" && (
              <div className="text-sm text-[#6E687B] space-y-3 leading-relaxed">
                <p>
                  TrueFit AI provides style inspiration, AI-assisted measurement estimates, and
                  custom fitting workflows for the studio.
                </p>
                <p>
                  Always review AI-generated measurements against a physical tape measure before
                  final cutting on bespoke commissions.
                </p>
                <button
                  type="button"
                  onClick={() => setActiveSheet("settings")}
                  className="text-xs font-semibold text-[#7654E8] hover:underline"
                >
                  Back to Settings
                </button>
              </div>
            )}

            {activeSheet === "privacy" && (
              <div className="text-sm text-[#6E687B] space-y-3 leading-relaxed">
                <p>
                  Your measurement profiles, saved looks, and order records are stored locally in
                  your browser and attached only when you submit a fitting request.
                </p>
                <p>
                  Photos uploaded to Fit Studio or Book Fitting are analyzed on demand and are not
                  stored permanently on the server.
                </p>
                <button
                  type="button"
                  onClick={() => setActiveSheet("settings")}
                  className="text-xs font-semibold text-[#7654E8] hover:underline"
                >
                  Back to Settings
                </button>
              </div>
            )}

            {activeSheet === "help" && (
              <div className="text-sm text-[#6E687B] space-y-3 leading-relaxed">
                <p className="font-semibold text-[#211D2B]">
                  Tips for accurate AI Fit Studio scans
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li>Stand straight in natural daylight wearing fitted clothing.</li>
                  <li>Add an optional side-profile photo for sharper bust/waist/hip depth.</li>
                  <li>Save separate profiles for group or Aso-ebi orders in Fit Studio.</li>
                </ul>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
