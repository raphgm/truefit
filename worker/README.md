# TrueFit AI API (Cloudflare Worker)

Free hosting for the two AI endpoints (`/api/fit-analyze`, `/api/style-analyze`). The Cloudflare free plan needs no card, so it cannot bill you; if you ever pass 100,000 requests in a day, extra requests are refused, not charged.

## Get a Gemini key (free)
Go to https://aistudio.google.com/apikey, sign in, and create an API key. Don't turn on billing if you want it to stay free.

## Option A: in the browser (no installs)
1. Sign up at https://dash.cloudflare.com (free, no card).
2. Compute > Workers & Pages > Create > Start with Hello World > name it `truefit-ai` > Deploy.
3. Edit code: replace everything with the contents of `src/index.js` > Deploy.
4. Settings > Variables and Secrets > Add: type **Secret**, name `GEMINI_API_KEY`, paste your key > Deploy.
5. Open `https://truefit-ai.<your-subdomain>.workers.dev/api/health`. It should say `"geminiKeySet":true`.

## Option B: command line
```
cd worker
npx wrangler login
npx wrangler secret put GEMINI_API_KEY
npx wrangler deploy
```

## Point the Android app at it
```
cd mobile
flutter build apk --dart-define=API_BASE=https://truefit-ai.<your-subdomain>.workers.dev
```
