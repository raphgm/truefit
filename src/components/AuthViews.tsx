import React, { useState } from "react";
import { ArrowLeft, Eye, EyeOff, Lock, Mail, Shirt, Sparkles, User } from "lucide-react";
import { AuthView, UserAccount } from "../types";
import { HERO_ATELIER_IMAGE } from "../data/catalog";

interface AuthViewsProps {
  view: AuthView;
  onChangeView: (view: AuthView) => void;
  onAuthenticate: (user: UserAccount) => void;
  onNotify: (msg: string) => void;
}

export const AuthViews: React.FC<AuthViewsProps> = ({
  view,
  onChangeView,
  onAuthenticate,
  onNotify,
}) => {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [acceptedTerms, setAcceptedTerms] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password) {
      onNotify("Please enter your email and password.");
      return;
    }
    const inferredName = email.split("@")[0]?.replace(/[._-]/g, " ") || "Atelier Guest";
    const formattedName = inferredName
      .split(" ")
      .filter(Boolean)
      .map((s) => s.charAt(0).toUpperCase() + s.slice(1))
      .join(" ");
    onAuthenticate({ name: formattedName, email: email.trim() });
    onNotify(`Welcome back, ${formattedName}.`);
  };

  const handleSignUp = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !email.trim() || password.length < 6) {
      onNotify("Enter your details. Password must be at least 6 characters.");
      return;
    }
    if (!acceptedTerms) {
      onNotify("Please accept the Terms and Privacy Policy to continue.");
      return;
    }
    onAuthenticate({ name: name.trim(), email: email.trim() });
    onNotify(`Account created for ${name.trim()}.`);
  };

  const handleForgot = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) {
      onNotify("Enter your email address to reset your password.");
      return;
    }
    onNotify(`If an account exists for ${email.trim()}, reset instructions have been queued.`);
    onChangeView("login");
  };

  if (view === "welcome") {
    return (
      <div className="min-h-screen bg-[#FAF8FC] text-[#211D2B] flex flex-col">
        <header className="w-full max-w-6xl mx-auto px-6 py-5 flex items-center justify-between gap-8">
          <div className="flex items-center gap-3 whitespace-nowrap shrink-0">
            <span className="w-10 h-10 rounded-xl bg-[#7654E8] text-white flex items-center justify-center">
              <Shirt className="w-5 h-5" />
            </span>
            <span className="font-display text-xl font-bold tracking-tight text-[#211D2B]">
              TrueFit AI
            </span>
          </div>
          <div className="flex items-center gap-3 shrink-0">
            <button
              type="button"
              onClick={() => onChangeView("login")}
              className="px-4 py-2 text-sm font-medium text-[#211D2B] hover:text-[#7654E8] transition-colors whitespace-nowrap shrink-0 min-h-[44px]"
            >
              Sign In
            </button>
            <button
              type="button"
              onClick={() => onChangeView("signup")}
              className="px-5 py-2.5 text-sm font-semibold rounded-xl bg-[#7654E8] text-white hover:bg-[#6442D6] transition-colors whitespace-nowrap shrink-0 min-h-[44px]"
            >
              Get Started
            </button>
          </div>
        </header>

        <main className="flex-1 w-full max-w-6xl mx-auto px-6 py-8 lg:py-14 grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-12 items-center">
          <div className="lg:col-span-6 space-y-6">
            <p className="text-xs font-semibold tracking-wider uppercase text-[#7654E8]">
              Bespoke Fashion &amp; Smart Tailoring
            </p>
            <h1 className="font-display text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight text-[#211D2B] leading-[1.08] text-balance">
              Your style. Your perfect fit.
            </h1>
            <p className="text-base sm:text-lg text-[#6E687B] leading-relaxed max-w-xl">
              Browse curated Ankara, traditional, and contemporary silhouettes, capture your
              AI-assisted measurements automatically, and book your custom piece directly with the studio.
            </p>

            <div className="flex flex-col sm:flex-row gap-3 pt-2">
              <button
                type="button"
                onClick={() => onChangeView("signup")}
                className="px-7 py-3.5 rounded-2xl bg-[#7654E8] text-white font-semibold text-sm hover:bg-[#6442D6] transition-colors min-h-[48px] whitespace-nowrap"
              >
                Get Started
              </button>
              <button
                type="button"
                onClick={() => onChangeView("login")}
                className="px-7 py-3.5 rounded-2xl border border-[#7654E8] text-[#7654E8] font-semibold text-sm hover:bg-[#EAE3FF]/50 transition-colors min-h-[48px] whitespace-nowrap"
              >
                I already have an account
              </button>
            </div>

            <div className="pt-2">
              <button
                type="button"
                onClick={() =>
                  onAuthenticate({
                    name: "Style Explorer",
                    email: "guest@truefit.ai",
                    isGuest: true,
                  })
                }
                className="text-sm font-medium text-[#6E687B] underline underline-offset-4 hover:text-[#211D2B] transition-colors min-h-[44px] inline-flex items-center"
              >
                Explore lookbook &amp; Fit Studio without signing in
              </button>
            </div>

            <div className="pt-6 border-t border-[#211D2B]/8 flex flex-wrap items-center gap-x-6 gap-y-2 text-xs text-[#6E687B]">
              <span>Automatic AI Photo Scan</span>
              <span aria-hidden="true">·</span>
              <span>Private Studio Fitting</span>
              <span aria-hidden="true">·</span>
              <span>Made-to-Measure Tracking</span>
            </div>
          </div>

          <div className="lg:col-span-6">
            <div className="relative rounded-3xl overflow-hidden bg-[#EAE3FF] aspect-[4/3] lg:aspect-[5/4] shadow-[0_20px_50px_rgba(33,29,43,0.08)]">
              <img
                src={HERO_ATELIER_IMAGE}
                alt="TrueFit AI modern bespoke tailoring atelier"
                referrerPolicy="no-referrer"
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#211D2B]/65 via-transparent to-transparent" />
              <div className="absolute bottom-5 left-5 right-5 flex items-end justify-between gap-4">
                <div className="bg-white/95 backdrop-blur-md rounded-2xl px-4 py-3 shadow-sm">
                  <div className="flex items-center gap-2 text-[#211D2B] font-semibold text-sm">
                    <Sparkles className="w-4 h-4 text-[#7654E8]" />
                    <span>AI Fit Studio</span>
                  </div>
                  <p className="text-xs text-[#6E687B] mt-0.5">
                    Smart measurements ready in seconds
                  </p>
                </div>
              </div>
            </div>
          </div>
        </main>

        <footer className="w-full max-w-6xl mx-auto px-6 py-5 text-xs text-[#6E687B] flex items-center justify-between border-t border-[#211D2B]/5">
          <span>Made for your style. Built for your fit.</span>
          <span>TrueFit AI</span>
        </footer>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#FAF8FC] text-[#211D2B] flex flex-col justify-center px-6 py-10">
      <div className="w-full max-w-md mx-auto">
        <button
          type="button"
          onClick={() => onChangeView(view === "forgot" ? "login" : "welcome")}
          className="inline-flex items-center gap-2 text-sm font-medium text-[#6E687B] hover:text-[#211D2B] mb-6 min-h-[44px]"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </button>

        <div className="bg-white rounded-3xl p-7 sm:p-8 shadow-[0_12px_36px_rgba(33,29,43,0.06)] border border-[#211D2B]/5">
          <div className="w-12 h-12 rounded-2xl bg-[#EAE3FF] text-[#7654E8] flex items-center justify-center mb-5">
            <Shirt className="w-6 h-6" />
          </div>

          {view === "login" && (
            <>
              <h1 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B] tracking-tight">
                Welcome back
              </h1>
              <p className="text-sm text-[#6E687B] mt-1.5">
                Sign in to continue your style journey.
              </p>

              <form onSubmit={handleLogin} className="mt-6 space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                    Email address
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-[#6E687B] absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      className="w-full pl-10 pr-4 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/10 text-sm focus:outline-none focus:border-[#7654E8]"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                    Password
                  </label>
                  <div className="relative">
                    <Lock className="w-4 h-4 text-[#6E687B] absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Enter your password"
                      className="w-full pl-10 pr-11 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/10 text-sm focus:outline-none focus:border-[#7654E8]"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((prev) => !prev)}
                      aria-label={showPassword ? "Hide password" : "Show password"}
                      className="absolute right-2 top-1/2 -translate-y-1/2 p-2 text-[#6E687B] hover:text-[#211D2B]"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>

                <div className="flex justify-end">
                  <button
                    type="button"
                    onClick={() => onChangeView("forgot")}
                    className="text-xs font-semibold text-[#7654E8] hover:underline py-1"
                  >
                    Forgot password?
                  </button>
                </div>

                <button
                  type="submit"
                  className="w-full py-3.5 rounded-xl bg-[#7654E8] text-white font-semibold text-sm hover:bg-[#6442D6] transition-colors min-h-[48px]"
                >
                  Sign In
                </button>
              </form>

              <p className="text-center text-xs text-[#6E687B] mt-6">
                Don&apos;t have an account?{" "}
                <button
                  type="button"
                  onClick={() => onChangeView("signup")}
                  className="font-semibold text-[#7654E8] hover:underline"
                >
                  Sign Up
                </button>
              </p>
            </>
          )}

          {view === "signup" && (
            <>
              <h1 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B] tracking-tight">
                Create your account
              </h1>
              <p className="text-sm text-[#6E687B] mt-1.5">
                Start discovering your personal style and fit profile.
              </p>

              <form onSubmit={handleSignUp} className="mt-6 space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                    Full name
                  </label>
                  <div className="relative">
                    <User className="w-4 h-4 text-[#6E687B] absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="Adaeze Okafor"
                      className="w-full pl-10 pr-4 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/10 text-sm focus:outline-none focus:border-[#7654E8]"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                    Email address
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-[#6E687B] absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      className="w-full pl-10 pr-4 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/10 text-sm focus:outline-none focus:border-[#7654E8]"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                    Password
                  </label>
                  <div className="relative">
                    <Lock className="w-4 h-4 text-[#6E687B] absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="At least 6 characters"
                      className="w-full pl-10 pr-11 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/10 text-sm focus:outline-none focus:border-[#7654E8]"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((prev) => !prev)}
                      aria-label={showPassword ? "Hide password" : "Show password"}
                      className="absolute right-2 top-1/2 -translate-y-1/2 p-2 text-[#6E687B] hover:text-[#211D2B]"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>

                <label className="flex items-start gap-2.5 text-xs text-[#6E687B] cursor-pointer pt-1">
                  <input
                    type="checkbox"
                    checked={acceptedTerms}
                    onChange={(e) => setAcceptedTerms(e.target.checked)}
                    className="mt-0.5 rounded accent-[#7654E8] w-4 h-4"
                  />
                  <span>I agree to the TrueFit AI Terms of Service and Privacy Policy.</span>
                </label>

                <button
                  type="submit"
                  className="w-full py-3.5 rounded-xl bg-[#7654E8] text-white font-semibold text-sm hover:bg-[#6442D6] transition-colors min-h-[48px]"
                >
                  Create Account
                </button>
              </form>

              <p className="text-center text-xs text-[#6E687B] mt-6">
                Already have an account?{" "}
                <button
                  type="button"
                  onClick={() => onChangeView("login")}
                  className="font-semibold text-[#7654E8] hover:underline"
                >
                  Sign In
                </button>
              </p>
            </>
          )}

          {view === "forgot" && (
            <>
              <h1 className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B] tracking-tight">
                Forgot password?
              </h1>
              <p className="text-sm text-[#6E687B] mt-1.5">
                Enter your email address and we&apos;ll send password reset instructions.
              </p>

              <form onSubmit={handleForgot} className="mt-6 space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-[#211D2B] mb-1.5">
                    Email address
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-[#6E687B] absolute left-3.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      className="w-full pl-10 pr-4 py-3 rounded-xl bg-[#FAF8FC] border border-[#211D2B]/10 text-sm focus:outline-none focus:border-[#7654E8]"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  className="w-full py-3.5 rounded-xl bg-[#7654E8] text-white font-semibold text-sm hover:bg-[#6442D6] transition-colors min-h-[48px]"
                >
                  Send Reset Link
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
