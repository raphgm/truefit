// TrueFit Studio data types and studio catalog (ported from src/types.ts and src/data/catalog.ts).
import 'dart:convert';
import 'dart:typed_data';

enum OutfitCategory { ankara, traditional, casual, formal }

const categoryLabel = {
  OutfitCategory.ankara: 'Ankara',
  OutfitCategory.traditional: 'Traditional',
  OutfitCategory.casual: 'Casual',
  OutfitCategory.formal: 'Formal',
};

class Outfit {
  final String id, name, priceLabel, image, fabric, leadTime, description;
  final OutfitCategory category;
  final int priceNaira, minDays, tint;
  final double aspect; // width / height
  const Outfit({required this.id, required this.name, required this.category, required this.priceNaira, required this.priceLabel,
      required this.image, required this.tint, required this.aspect, required this.fabric, required this.leadTime, required this.minDays,
      required this.description});
}

class Atelier {
  final String id, name, location, specialty, turnaround, bio, startingPrice;
  final double rating;
  final int completedCount, tint;
  const Atelier({required this.id, required this.name, required this.location, required this.specialty, required this.rating,
      required this.completedCount, required this.turnaround, required this.tint, required this.bio, required this.startingPrice});
}

const measurementKeys = ['Chest', 'Waist', 'Hip', 'Shoulder', 'Sleeve', 'Inseam'];
typedef Measurements = Map<String, double>;

class Bound {
  final double min, max;
  final String helper;
  const Bound(this.min, this.max, this.helper);
}

const measurementBounds = {
  'Chest': Bound(70, 140, 'Fullest part of chest / bust'),
  'Waist': Bound(55, 130, 'Natural waistline above navel'),
  'Hip': Bound(75, 145, 'Widest point across seat'),
  'Shoulder': Bound(34, 60, 'Acromion bone to bone'),
  'Sleeve': Bound(48, 75, 'Shoulder seam to wrist bone'),
  'Inseam': Bound(62, 96, 'Inner thigh to ankle'),
};

Measurements defaultMeasurements() => {'Chest': 96, 'Waist': 82, 'Hip': 100, 'Shoulder': 42, 'Sleeve': 60, 'Inseam': 78};

Measurements _measures(dynamic j) => {for (final k in measurementKeys) k: ((j?[k] ?? defaultMeasurements()[k]) as num).toDouble()};

class ExtractedDetails {
  final String bodyBuild, shoulderProfile, torsoProportion, postureNote, recommendedBaseSize, lightingAndFraming;
  ExtractedDetails(this.bodyBuild, this.shoulderProfile, this.torsoProportion, this.postureNote, this.recommendedBaseSize, this.lightingAndFraming);
  factory ExtractedDetails.fromJson(Map j) => ExtractedDetails('${j['bodyBuild'] ?? ''}', '${j['shoulderProfile'] ?? ''}',
      '${j['torsoProportion'] ?? ''}', '${j['postureNote'] ?? ''}', '${j['recommendedBaseSize'] ?? ''}', '${j['lightingAndFraming'] ?? ''}');
  Map<String, dynamic> toJson() => {'bodyBuild': bodyBuild, 'shoulderProfile': shoulderProfile, 'torsoProportion': torsoProportion,
        'postureNote': postureNote, 'recommendedBaseSize': recommendedBaseSize, 'lightingAndFraming': lightingAndFraming};
}

class FitAnalysis {
  final Measurements measurements;
  final ExtractedDetails details;
  final String silhouetteNote, easeRecommendation;
  final List<String> tailorNotes;
  FitAnalysis(this.measurements, this.details, this.silhouetteNote, this.easeRecommendation, this.tailorNotes);
  factory FitAnalysis.fromJson(Map j) => FitAnalysis(_measures(j['measurements']), ExtractedDetails.fromJson(j['extractedDetails'] ?? {}),
      '${j['silhouetteNote'] ?? ''}', '${j['easeRecommendation'] ?? ''}', [for (final n in (j['tailorNotes'] as List? ?? [])) '$n']);
  Map<String, dynamic> toJson() => {'measurements': measurements, 'extractedDetails': details.toJson(), 'silhouetteNote': silhouetteNote,
        'easeRecommendation': easeRecommendation, 'tailorNotes': tailorNotes};
}

class FitProfile {
  final String id;
  String label, fitPreference, updatedAt;
  double heightCm;
  Measurements measurements;
  FitAnalysis? analysis;
  FitProfile({required this.id, required this.label, this.heightCm = 170, this.fitPreference = 'Tailored', Measurements? measurements,
      this.analysis, this.updatedAt = 'New profile'})
      : measurements = measurements ?? defaultMeasurements();
  factory FitProfile.fromJson(Map j) => FitProfile(id: j['id'], label: j['label'], heightCm: (j['heightCm'] as num).toDouble(),
      fitPreference: j['fitPreference'], measurements: _measures(j['measurements']),
      analysis: j['analysis'] == null ? null : FitAnalysis.fromJson(j['analysis']), updatedAt: j['updatedAt'] ?? '');
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'heightCm': heightCm, 'fitPreference': fitPreference,
        'measurements': measurements, 'analysis': analysis?.toJson(), 'updatedAt': updatedAt};
}

class StyleAnalysis {
  final String garmentTitle, categoryGuess, suggestedFabric, estimatedYards, estimatedLeadTime;
  final List<String> constructionDetails;
  StyleAnalysis(this.garmentTitle, this.categoryGuess, this.suggestedFabric, this.estimatedYards, this.constructionDetails, this.estimatedLeadTime);
  factory StyleAnalysis.fromJson(Map j) => StyleAnalysis('${j['garmentTitle'] ?? ''}', '${j['categoryGuess'] ?? ''}', '${j['suggestedFabric'] ?? ''}',
      '${j['estimatedYards'] ?? ''}', [for (final d in (j['constructionDetails'] as List? ?? [])) '$d'], '${j['estimatedLeadTime'] ?? ''}');
  Map<String, dynamic> toJson() => {'garmentTitle': garmentTitle, 'categoryGuess': categoryGuess, 'suggestedFabric': suggestedFabric,
        'estimatedYards': estimatedYards, 'constructionDetails': constructionDetails, 'estimatedLeadTime': estimatedLeadTime};
}

const orderStages = ['Design selected', 'Tailor confirmed', 'In production', 'Ready for delivery'];
const orderStageInfo = {
  'Design selected': 'Your style and measurements are received.',
  'Tailor confirmed': 'The studio confirms fabric availability and cut schedule.',
  'In production': 'Your garment is being cut and sewn.',
  'Ready for delivery': 'Your custom outfit is finished and ready for pickup or dispatch.',
};
const paymentOptions = ['Deposit pending', '50% deposit paid', 'Paid in full'];

class OrderMessage {
  final String id, sender, text, timestamp; // sender: Client | Tailor
  final Uint8List? image;
  OrderMessage(this.id, this.sender, this.text, this.timestamp, [this.image]);
  factory OrderMessage.fromJson(Map j) =>
      OrderMessage(j['id'], j['sender'], j['text'], j['timestamp'], j['image'] == null ? null : base64Decode(j['image']));
  Map<String, dynamic> toJson() => {'id': id, 'sender': sender, 'text': text, 'timestamp': timestamp, 'image': image == null ? null : base64Encode(image!)};
}

/// An order's picture: a lookbook asset, or a photo the client uploaded.
class OrderImage {
  final String? asset;
  final Uint8List? bytes;
  const OrderImage({this.asset, this.bytes});
  Map<String, dynamic> toJson() => {'asset': asset, 'bytes': bytes == null ? null : base64Encode(bytes!)};
  factory OrderImage.fromJson(Map j) => OrderImage(asset: j['asset'], bytes: j['bytes'] == null ? null : base64Decode(j['bytes']));
}

class TailoringOrder {
  final String id, outfitName, atelierName, atelierLocation, priceLabel, createdAt, fabricChoice, fabricNote, fitProfileLabel;
  final OrderImage image;
  final bool isCustomInspiration, isRushOrder;
  final StyleAnalysis? styleAnalysis;
  final String? eventDate, appointmentSlot, tailorGuidance;
  final Measurements measurements;
  String stage, paymentStatus;
  final List<OrderMessage> messages;
  TailoringOrder({required this.id, required this.outfitName, required this.image, required this.isCustomInspiration, this.styleAnalysis,
      required this.atelierName, required this.atelierLocation, required this.priceLabel, required this.stage, required this.paymentStatus,
      required this.createdAt, this.eventDate, required this.isRushOrder, this.appointmentSlot, required this.fabricChoice,
      required this.fabricNote, required this.fitProfileLabel, required this.measurements, this.tailorGuidance, List<OrderMessage>? messages})
      : messages = messages ?? [];
  factory TailoringOrder.fromJson(Map j) => TailoringOrder(
        id: j['id'], outfitName: j['outfitName'], image: OrderImage.fromJson(j['image']), isCustomInspiration: j['isCustomInspiration'] ?? false,
        styleAnalysis: j['styleAnalysis'] == null ? null : StyleAnalysis.fromJson(j['styleAnalysis']), atelierName: j['atelierName'],
        atelierLocation: j['atelierLocation'], priceLabel: j['priceLabel'], stage: j['stage'], paymentStatus: j['paymentStatus'],
        createdAt: j['createdAt'], eventDate: j['eventDate'], isRushOrder: j['isRushOrder'] ?? false, appointmentSlot: j['appointmentSlot'],
        fabricChoice: j['fabricChoice'], fabricNote: j['fabricNote'], fitProfileLabel: j['fitProfileLabel'], measurements: _measures(j['measurements']),
        tailorGuidance: j['tailorGuidance'], messages: [for (final m in (j['messages'] as List? ?? [])) OrderMessage.fromJson(m)],
      );
  Map<String, dynamic> toJson() => {
        'id': id, 'outfitName': outfitName, 'image': image.toJson(), 'isCustomInspiration': isCustomInspiration,
        'styleAnalysis': styleAnalysis?.toJson(), 'atelierName': atelierName, 'atelierLocation': atelierLocation, 'priceLabel': priceLabel,
        'stage': stage, 'paymentStatus': paymentStatus, 'createdAt': createdAt, 'eventDate': eventDate, 'isRushOrder': isRushOrder,
        'appointmentSlot': appointmentSlot, 'fabricChoice': fabricChoice, 'fabricNote': fabricNote, 'fitProfileLabel': fitProfileLabel,
        'measurements': measurements, 'tailorGuidance': tailorGuidance, 'messages': [for (final m in messages) m.toJson()],
      };
}

class UserAccount {
  final String name, email;
  final bool isGuest;
  const UserAccount(this.name, this.email, {this.isGuest = false});
  factory UserAccount.fromJson(Map j) => UserAccount(j['name'], j['email'], isGuest: j['isGuest'] ?? false);
  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'isGuest': isGuest};
}

// ---- Catalog ----

const heroImage = 'assets/images/hero_atelier_studio.jpg';

const houseAtelier = Atelier(
  id: 'aisha-couture', name: 'Aisha Couture', location: 'Abuja, Nigeria',
  specialty: 'Bespoke Ankara, Traditional & Contemporary Tailoring', rating: 4.9, completedCount: 340, turnaround: '7–14 days',
  tint: 0xFFFFE9D9, startingPrice: 'From ₦18,000',
  bio: 'Private bespoke tailoring studio specializing in precision-cut Ankara silhouettes, contemporary Agbada ensembles, fluid silk boubous, and made-to-measure suiting.',
);

const studioFabrics = [
  'Use lookbook house fabric', '100% Dutch Wax Cotton (Ankara)', 'Cashmere-Blend Guinea Brocade', 'Breathable Belgian Linen',
  'Silk Crepe with Hand-Beading', 'Super 120s Charcoal Merino Wool', 'Client supplying own fabric',
];

const fittingSlots = [
  'No appointment needed (measurements already scanned)', 'Studio Fitting · Tomorrow 11:00 AM', 'Studio Fitting · Tomorrow 3:00 PM',
  'Studio Fitting · This Friday 11:00 AM', 'Virtual Video Check-In · Saturday 1:00 PM',
];

const outfits = [
  Outfit(id: 'ankara-elegance', name: 'Ankara Elegance', category: OutfitCategory.ankara, priceNaira: 25000, priceLabel: 'From ₦25,000',
      image: 'assets/images/outfit_ankara_elegance.jpg', tint: 0xFFFFE4EF, aspect: 3 / 4, fabric: '100% Dutch Wax Cotton', leadTime: '7–10 days', minDays: 7,
      description: 'Structured square-neckline midi dress with sculpted volume sleeves and tailored waist darting cut to your exact bodice proportions.'),
  Outfit(id: 'modern-agbada', name: 'Modern Agbada', category: OutfitCategory.traditional, priceNaira: 45000, priceLabel: 'From ₦45,000',
      image: 'assets/images/outfit_modern_agbada.jpg', tint: 0xFFEAE3FF, aspect: 4 / 5, fabric: 'Midweight Cashmere-Blend Guinea Brocade', leadTime: '10–14 days', minDays: 10,
      description: 'Architectural three-piece Agbada with tonal geometric neckline embroidery and crisp shoulder drape balanced to your frame height.'),
  Outfit(id: 'minimalist-chic', name: 'Minimalist Chic', category: OutfitCategory.casual, priceNaira: 18000, priceLabel: 'From ₦18,000',
      image: 'assets/images/outfit_minimalist_chic.jpg', tint: 0xFFFFE9D9, aspect: 4 / 5, fabric: 'Breathable Belgian Linen', leadTime: '5–7 days', minDays: 5,
      description: 'Relaxed single-breasted linen blazer and high-waisted wide-leg trousers engineered for effortless daylight tailoring.'),
  Outfit(id: 'classic-suit', name: 'Classic Suit', category: OutfitCategory.formal, priceNaira: 55000, priceLabel: 'From ₦55,000',
      image: 'assets/images/outfit_classic_suit.jpg', tint: 0xFFE5ECF6, aspect: 3 / 4, fabric: 'Super 120s Charcoal Merino Wool', leadTime: '14–18 days', minDays: 14,
      description: 'Full-canvas two-piece suit with clean peak lapels, natural roped shoulders, and trousers hemmed to your exact inseam.'),
  Outfit(id: 'elegant-boubou', name: 'Elegant Boubou', category: OutfitCategory.traditional, priceNaira: 35000, priceLabel: 'From ₦35,000',
      image: 'assets/images/outfit_elegant_boubou.jpg', tint: 0xFFFFF1D6, aspect: 3 / 4, fabric: 'Silk Crepe with Hand-Beaded Trim', leadTime: '8–12 days', minDays: 8,
      description: 'Fluid full-length Boubou kaftan featuring artisanal beadwork along the keyhole collar and proportioned sleeve drop.'),
  Outfit(id: 'weekend-fit', name: 'Weekend Fit', category: OutfitCategory.casual, priceNaira: 20000, priceLabel: 'From ₦20,000',
      image: 'assets/images/outfit_weekend_fit.jpg', tint: 0xFFFFE4EF, aspect: 4 / 5, fabric: 'Slub Textured Cotton & Twill', leadTime: '5–8 days', minDays: 5,
      description: 'Open camp-collar textured shirt paired with double-pleated tapered trousers designed for clean everyday movement.'),
];

Outfit outfitById(String id) => outfits.firstWhere((o) => o.id == id, orElse: () => outfits.first);

const howItWorks = [
  ('01', 'Choose or upload a look', 'Pick from the studio lookbook or upload your own inspiration photo.'),
  ('02', 'Scan your fit profile', 'Capture front & optional side measurements in Fit Studio.'),
  ('03', 'Select fabric & date', 'Choose fabric, schedule a fitting slot, and attach a fit profile.'),
  ('04', 'Track WIP & delivery', 'Receive fitting photos, stage updates, and delivery notices.'),
];
