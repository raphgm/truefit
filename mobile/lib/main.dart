import 'package:material_ui/material_ui.dart';

import 'screens/auth.dart';
import 'screens/book.dart';
import 'screens/home.dart';
import 'screens/orders.dart';
import 'screens/studio.dart';
import 'screens/tailor_desk.dart';
import 'state.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(AppScope(state: state, child: const TrueFitApp()));
}

class TrueFitApp extends StatelessWidget {
  const TrueFitApp({super.key});
  @override
  Widget build(BuildContext context) {
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return MaterialApp(
      title: 'TrueFit AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: purple, primary: purple, surface: Colors.white),
        scaffoldBackgroundColor: bg,
        appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: dark, elevation: 0, scrolledUnderElevation: 0),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: rounded, textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: rounded, foregroundColor: dark,
            side: const BorderSide(color: Color(0x26211D2B)), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x1F211D2B))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: purple, width: 2)),
        ),
        snackBarTheme: SnackBarThemeData(backgroundColor: dark, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        navigationBarTheme: NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: lavender, height: 66, elevation: 0,
            labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ),
      home: const Root(),
      // In a computer browser, show the app inside a phone-sized frame.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        if (mq.size.width < 600) return child!;
        return PhoneFrame(child: child!);
      },
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  AppState? _s;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (s != _s) {
      _s?.toasts.removeListener(_toast);
      _s = s..toasts.addListener(_toast);
    }
  }

  void _toast() {
    final m = _s!.toasts.value;
    if (m == null || !mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(m), duration: const Duration(milliseconds: 3200)));
    _s!.toasts.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.user == null) return const AuthScreen();
    const tabs = [AppTab.home, AppTab.studio, AppTab.book, AppTab.profile];
    final navIndex = switch (s.tab) {
      AppTab.home => 0, AppTab.studio => 1, AppTab.book => 2, _ => 3,
    };
    final body = switch (s.tab) {
      AppTab.home => const HomeScreen(),
      AppTab.studio => const StudioScreen(),
      AppTab.book => const BookScreen(),
      AppTab.saved => const SavedScreen(),
      AppTab.orders => const OrdersScreen(),
      AppTab.profile => const ProfileScreen(),
      AppTab.tailorDesk => const TailorDeskScreen(),
    };
    return PopScope(
      canPop: s.tab == AppTab.home,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) s.go(const {AppTab.saved, AppTab.orders, AppTab.tailorDesk}.contains(s.tab) ? AppTab.profile : AppTab.home);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          leading: const {AppTab.saved, AppTab.orders, AppTab.tailorDesk}.contains(s.tab) ? BackButton(onPressed: () => s.go(AppTab.profile)) : null,
          title: GestureDetector(onTap: () => s.go(AppTab.home), child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.checkroom, color: purple), SizedBox(width: 8),
            Text('TrueFit AI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3)),
          ])),
          actions: [
            IconButton(tooltip: 'Saved looks', onPressed: () => s.go(AppTab.saved),
                icon: Badge(isLabelVisible: s.favorites.isNotEmpty, label: Text('${s.favorites.length}'), child: const Icon(Icons.favorite_border))),
            IconButton(tooltip: 'My orders', onPressed: () => s.go(AppTab.orders),
                icon: Badge(isLabelVisible: s.orders.isNotEmpty, label: Text('${s.orders.length}'), child: const Icon(Icons.shopping_bag_outlined))),
          ],
        ),
        body: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: KeyedSubtree(key: ValueKey(s.tab), child: body)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navIndex,
          onDestinationSelected: (i) => s.go(tabs[i]),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: purple), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.straighten_outlined), selectedIcon: Icon(Icons.straighten, color: purple), label: 'Fit Studio'),
            NavigationDestination(icon: Icon(Icons.content_cut_outlined), selectedIcon: Icon(Icons.content_cut, color: purple), label: 'Book'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: purple), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}


/// On a computer screen, shows the app inside a modern phone: 19.5:9 shape, thin bezel,
/// Dynamic-Island-style notch, live status bar, home indicator and side buttons.
class PhoneFrame extends StatefulWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});
  @override
  State<PhoneFrame> createState() => _PhoneFrameState();
}

class _PhoneFrameState extends State<PhoneFrame> {
  late final Stream<DateTime> _clock = Stream.periodic(const Duration(seconds: 20), (_) => DateTime.now());

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = (mq.size.height - 56).clamp(520.0, 880.0);
    final w = (h * 9 / 19.5).clamp(372.0, 420.0);
    const bezel = 11.0, statusH = 50.0, homeH = 26.0;
    final screen = Size(w - bezel * 2, h - bezel * 2);
    Widget sideButton(double top, double height, {bool left = true}) => Positioned(
          top: top, left: left ? -3 : null, right: left ? null : -3,
          child: Container(width: 4, height: height, decoration: BoxDecoration(color: const Color(0xFF2A2730), borderRadius: BorderRadius.circular(2))),
        );
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.3), radius: 1.2,
          colors: [Color(0xFF2B2246), Color(0xFF0E0C14)])),
      child: Center(child: SizedBox(width: w, height: h, child: Stack(clipBehavior: Clip.none, children: [
        sideButton(h * 0.17, 28), sideButton(h * 0.24, 54), sideButton(h * 0.33, 54), sideButton(h * 0.26, 86, left: false),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C), borderRadius: BorderRadius.circular(56),
            border: Border.all(color: const Color(0xFF3A3640), width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 70, offset: Offset(0, 30))],
          ),
          padding: const EdgeInsets.all(bezel),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(46),
            child: Stack(children: [
              MediaQuery(
                data: mq.copyWith(size: screen, padding: const EdgeInsets.only(top: statusH, bottom: homeH),
                    viewPadding: const EdgeInsets.only(top: statusH, bottom: homeH)),
                child: widget.child,
              ),
              // Status bar
              Positioned(top: 0, left: 0, right: 0, height: statusH, child: IgnorePointer(child: Material(type: MaterialType.transparency, child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 14, 26, 0),
                child: ValueListenableBuilder<bool>(valueListenable: darkStatusBar, builder: (_, darkBg, _) => StreamBuilder<DateTime>(stream: _clock, builder: (_, snap) {
                  final t = snap.data ?? DateTime.now();
                  final c = darkBg ? Colors.white : dark;
                  final time = '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')}';
                  return Row(children: [
                    Text(time, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c, letterSpacing: -0.2)),
                    const Spacer(),
                    Icon(Icons.signal_cellular_alt, size: 16, color: c), const SizedBox(width: 4),
                    Icon(Icons.wifi, size: 16, color: c), const SizedBox(width: 4),
                    Icon(Icons.battery_full, size: 18, color: c),
                  ]);
                })),
              )))),
              // Notch
              Positioned(top: 11, left: 0, right: 0, child: IgnorePointer(child: Center(child: Container(
                width: 118, height: 34, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
              )))),
              // Home indicator
              Positioned(bottom: 8, left: 0, right: 0, child: IgnorePointer(child: Center(child: Container(
                width: 130, height: 5, decoration: BoxDecoration(color: const Color(0xFF8E8A96), borderRadius: BorderRadius.circular(3)),
              )))),
            ]),
          ),
        ),
      ]))),
    );
  }
}
