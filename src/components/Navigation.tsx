import React from "react";
import { Home, Ruler, Scissors, User } from "lucide-react";
import { MainTab, UserAccount } from "../types";

interface NavigationProps {
  activeTab: MainTab;
  onSelectTab: (tab: MainTab) => void;
  user: UserAccount;
  savedCount: number;
  ordersCount: number;
}

export const DesktopTopBar: React.FC<NavigationProps> = ({
  activeTab,
  onSelectTab,
  user,
  savedCount,
  ordersCount,
}) => {
  const navItems: { id: MainTab; label: string }[] = [
    { id: "home", label: "Home" },
    { id: "studio", label: "Fit Studio" },
    { id: "book", label: "Book Fitting" },
    { id: "saved", label: savedCount > 0 ? `Saved (${savedCount})` : "Saved" },
    { id: "orders", label: ordersCount > 0 ? `Orders (${ordersCount})` : "Orders" },
  ];

  return (
    <header className="sticky top-0 z-30 bg-[#FAF8FC]/90 backdrop-blur-md border-b border-[#211D2B]/8">
      <div className="max-w-6xl mx-auto px-5 sm:px-6 h-14 md:h-16 flex items-center justify-between gap-8">
        <button
          type="button"
          onClick={() => onSelectTab("home")}
          className="font-display text-xl font-bold tracking-tight text-[#211D2B] whitespace-nowrap shrink-0 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#7654E8] rounded-md"
        >
          TrueFit AI
        </button>

        <nav className="hidden md:flex items-center gap-7" aria-label="Primary">
          {navItems.map((item) => {
            const active = activeTab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => onSelectTab(item.id)}
                className={`text-sm font-medium whitespace-nowrap shrink-0 py-1.5 border-b-2 transition-colors ${
                  active
                    ? "text-[#7654E8] border-[#7654E8] font-semibold"
                    : "text-[#6E687B] border-transparent hover:text-[#211D2B]"
                }`}
              >
                {item.label}
              </button>
            );
          })}
        </nav>

        <div className="flex items-center shrink-0">
          <button
            type="button"
            onClick={() => onSelectTab("profile")}
            className={`px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap shrink-0 transition-colors min-h-[40px] ${
              activeTab === "profile"
                ? "bg-[#211D2B] text-white"
                : "bg-[#7654E8] text-white hover:bg-[#6442D6]"
            }`}
          >
            {user.isGuest ? "Account" : user.name.split(" ")[0]}
          </button>
        </div>
      </div>
    </header>
  );
};

export const MobileBottomBar: React.FC<{
  activeTab: MainTab;
  onSelectTab: (tab: MainTab) => void;
}> = ({ activeTab, onSelectTab }) => {
  const items: { id: MainTab; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
    { id: "home", label: "Home", icon: Home },
    { id: "studio", label: "Fit Studio", icon: Ruler },
    { id: "book", label: "Book", icon: Scissors },
    { id: "profile", label: "Profile", icon: User },
  ];

  const resolvedTab =
    activeTab === "saved" || activeTab === "orders" ? "profile" : activeTab;

  return (
    <nav
      aria-label="Mobile Navigation"
      className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-[#211D2B]/10"
    >
      <div className="grid grid-cols-4 h-16 items-center">
        {items.map((item) => {
          const Icon = item.icon;
          const active = resolvedTab === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onSelectTab(item.id)}
              className={`flex flex-col items-center justify-center min-h-[44px] transition-colors ${
                active ? "text-[#7654E8]" : "text-[#6E687B]"
              }`}
            >
              <Icon className="w-5 h-5" />
              <span className={`text-[11px] mt-1 leading-none ${active ? "font-semibold" : "font-medium"}`}>
                {item.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
