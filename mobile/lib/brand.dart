// One codebase, several tailors. Everything that makes a client's app theirs lives here.
// Pick the brand at build time:
//   flutter build web --dart-define=BRAND=stitchperfect
//   flutter build apk --flavor stitchperfect --dart-define=BRAND=stitchperfect
// (TrueFit Studio is the default: BRAND=truefit, --flavor truefit.)
import 'dart:ui' show Color;

const brandId = String.fromEnvironment('BRAND', defaultValue: 'truefit');
const isStitch = brandId == 'stitchperfect';

/// Prefix for everything saved on the device, so two apps never share or overwrite data.
const storagePrefix = isStitch ? 'stitchperfect' : 'truefit';

// ---- Names and wording ----
const appName = isStitch ? 'StitchPerfect' : 'TrueFit Studio';
const welcomeEyebrow = isStitch ? 'MADE FOR YOU, STITCH BY STITCH' : 'BESPOKE FASHION & SMART TAILORING';
const welcomeHeadline = isStitch ? 'Measured by AI.\nStitched by hand.' : 'Your style.\nYour perfect fit.';
const welcomeBadge = isStitch ? 'Photo measuring · Lagos tailoring' : 'AI Fit Studio · Smart measurements';
const homeHeadline = isStitch ? 'Dress for the moment.\nPerfectly stitched.' : 'Your perfect fit.\nYour own style.';
const homeBlurb = isStitch
    ? 'Ankara, aso-ebi and celebration wear from Kemi Stitches, cut to the measurements you scan at home.'
    : 'Made-to-measure Ankara, traditional and contemporary pieces, cut to your AI-scanned measurements.';

// ---- Colours ----
const brandPrimary = isStitch ? Color(0xFFC2410C) : Color(0xFF7654E8); // terracotta | purple
const brandPrimaryDark = isStitch ? Color(0xFF9A3412) : Color(0xFF4B2FB8);
const brandInk = isStitch ? Color(0xFF1F1A17) : Color(0xFF211D2B);
const brandBg = isStitch ? Color(0xFFFFFAF5) : Color(0xFFFAF8FC);
const brandMuted = isStitch ? Color(0xFF75685F) : Color(0xFF6E687B);
const brandSoft = isStitch ? Color(0xFFFDE6D8) : Color(0xFFEAE3FF); // light tint of the primary
const brandFrameTop = isStitch ? Color(0xFF3A2218) : Color(0xFF2E2840); // background behind the phone (browser)
const brandFrameBottom = isStitch ? Color(0xFF110B08) : Color(0xFF0C0B11);
