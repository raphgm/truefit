// App-wide state, saved on the device (the web version used localStorage with the same keys).
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand.dart';
import 'models.dart';

enum AppTab { home, studio, book, saved, orders, profile, tailorDesk }

class AppState extends ChangeNotifier {
  late SharedPreferences _p;
  UserAccount? user;
  List<String> favorites = [];
  List<FitProfile> profiles = [];
  String activeProfileId = 'profile-primary';
  List<TailoringOrder> orders = [];
  bool notifications = true, measurementPrivacy = true;

  AppTab tab = AppTab.home;
  Outfit? preselected;

  /// Short messages shown as a toast (the main shell listens and shows a SnackBar).
  final toasts = ValueNotifier<String?>(null);
  void notify(String msg) => toasts.value = msg;

  static const _k = (
    user: '${storagePrefix}_user_v1', favorites: '${storagePrefix}_favorites_v1', profiles: '${storagePrefix}_fit_profiles_v1',
    active: '${storagePrefix}_active_profile_v1', orders: '${storagePrefix}_orders_v2', settings: '${storagePrefix}_settings_v1',
  );

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    T? read<T>(String key, T Function(dynamic) f) {
      final s = _p.getString(key);
      if (s == null) return null;
      try { return f(jsonDecode(s)); } catch (_) { return null; }
    }
    user = read(_k.user, (j) => UserAccount.fromJson(j));
    favorites = read(_k.favorites, (j) => [for (final x in j) '$x']) ?? [];
    profiles = read(_k.profiles, (j) => [for (final x in j) FitProfile.fromJson(x)]) ?? [];
    if (profiles.isEmpty) profiles = [FitProfile(id: 'profile-primary', label: 'My Fit Profile', heightCm: 174, updatedAt: 'Baseline profile')];
    activeProfileId = read(_k.active, (j) => '$j') ?? profiles.first.id;
    orders = read(_k.orders, (j) => [for (final x in j) TailoringOrder.fromJson(x)]) ?? [];
    final s = read(_k.settings, (j) => j as Map);
    if (s != null) { notifications = s['notifications'] ?? true; measurementPrivacy = s['measurementPrivacy'] ?? true; }
  }

  void _save() {
    final u = user;
    u == null ? _p.remove(_k.user) : _p.setString(_k.user, jsonEncode(u.toJson()));
    _p.setString(_k.favorites, jsonEncode(favorites));
    _p.setString(_k.profiles, jsonEncode([for (final x in profiles) x.toJson()]));
    _p.setString(_k.active, jsonEncode(activeProfileId));
    _p.setString(_k.orders, jsonEncode([for (final x in orders) x.toJson()]));
    _p.setString(_k.settings, jsonEncode({'notifications': notifications, 'measurementPrivacy': measurementPrivacy}));
  }

  void changed() { _save(); notifyListeners(); }

  FitProfile get activeProfile => profiles.firstWhere((p) => p.id == activeProfileId, orElse: () => profiles.first);

  void go(AppTab t) { tab = t; notifyListeners(); }

  void signIn(UserAccount u) { user = u; tab = AppTab.home; changed(); }
  void signOut() { user = null; changed(); notify('Signed out.'); }

  void toggleFavorite(String id) {
    final had = favorites.remove(id);
    if (!had) favorites.add(id);
    notify(had ? 'Removed from Saved Looks.' : 'Added to Saved Looks.');
    changed();
  }

  void selectProfile(String id) { activeProfileId = id; changed(); }

  void createProfile(String label) {
    final p = FitProfile(id: 'profile-${DateTime.now().millisecondsSinceEpoch}', label: label);
    profiles.add(p);
    activeProfileId = p.id;
    notify('Created profile "$label".');
    changed();
  }

  void deleteActiveProfile() {
    if (profiles.length <= 1) return;
    profiles.removeWhere((p) => p.id == activeProfileId);
    activeProfileId = profiles.first.id;
    notify('Fit profile removed.');
    changed();
  }

  void saveProfile() { notify('"${activeProfile.label}" saved.'); changed(); }

  void bookOutfit(Outfit o) { preselected = o; tab = AppTab.book; notifyListeners(); }

  void placeOrder({required String outfitName, required OrderImage image, required String priceLabel, required bool isCustom,
      StyleAnalysis? style, required String fabricChoice, required String fabricNote, String? eventDate, required bool isRush,
      required String slot, required FitProfile profile}) {
    final guidance = [
      if (profile.analysis?.easeRecommendation.isNotEmpty ?? false) 'Ease: ${profile.analysis!.easeRecommendation}',
      if (profile.analysis?.details.postureNote.isNotEmpty ?? false) 'Posture: ${profile.analysis!.details.postureNote}',
      if (style != null) 'Yardage: ${style.estimatedYards} (${style.suggestedFabric})',
    ].join(' · ');
    final o = TailoringOrder(
      id: 'TF-${1000 + Random().nextInt(9000)}', outfitName: outfitName, image: image, isCustomInspiration: isCustom, styleAnalysis: style,
      atelierName: houseAtelier.name, atelierLocation: houseAtelier.location, priceLabel: priceLabel, stage: orderStages.first,
      paymentStatus: paymentOptions.first, createdAt: shortDate(DateTime.now(), year: true), eventDate: eventDate, isRushOrder: isRush,
      appointmentSlot: slot, fabricChoice: fabricChoice, fabricNote: fabricNote, fitProfileLabel: profile.label,
      measurements: Map.of(profile.measurements), tailorGuidance: guidance.isEmpty ? null : guidance,
    );
    orders.insert(0, o);
    preselected = null;
    tab = AppTab.orders;
    notify('Order ${o.id} submitted to ${houseAtelier.name}.');
    changed();
  }

  void setStage(TailoringOrder o, String s) { o.stage = s; notify('Order ${o.id} moved to "$s".'); changed(); }
  void setPayment(TailoringOrder o, String s) { o.paymentStatus = s; notify('Payment status updated to "$s".'); changed(); }

  void postMessage(TailoringOrder o, String sender, String text, [Uint8List? image]) {
    final t = TimeOfDay.now();
    final ts = '${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
    o.messages.add(OrderMessage('msg-${DateTime.now().millisecondsSinceEpoch}', sender, text, ts, image));
    notify(sender == 'Tailor' ? 'Fitting update sent to client.' : 'Message sent to the studio.');
    changed();
  }

  void setSettings({bool? notif, bool? privacy}) {
    notifications = notif ?? notifications;
    measurementPrivacy = privacy ?? measurementPrivacy;
    notify('Preferences updated.');
    changed();
  }
}

String shortDate(DateTime d, {bool year = false}) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${m[d.month - 1]} ${d.day}${year ? ', ${d.year}' : ''}';
}

/// Lets any screen reach the app state.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
