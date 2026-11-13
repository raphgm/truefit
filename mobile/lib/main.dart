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


/// On a computer screen, shows the app inside an iPhone-style phone: titanium edge, thin black
/// bezel, Dynamic Island, iOS status bar, home indicator, Action button and Camera Control.
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
    final h = (mq.size.height - 56).clamp(560.0, 900.0);
    // iPhone 17 Pro Max body: 6.4 x 3.1 in (about 2.06 : 1).
    final w = (h / 2.06).clamp(390.0, 440.0);
    const edge = 4.0, bezel = 7.0, statusH = 54.0, homeH = 30.0;
    final screen = Size(w - (edge + bezel) * 2, h - (edge + bezel) * 2);
    const titanium = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF8E8A93), Color(0xFF4A4750), Color(0xFF9C98A2), Color(0xFF3E3C44)], stops: [0, 0.35, 0.65, 1]);
    Widget button(double top, double height, {bool left = true, double width = 4}) => Positioned(
          top: top, left: left ? -width + 1 : null, right: left ? null : -width + 1,
          child: Container(width: width, height: height,
              decoration: BoxDecoration(gradient: titanium, borderRadius: BorderRadius.circular(2))),
        );
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.2), radius: 1.1,
          colors: [Color(0xFF2E2840), Color(0xFF0C0B11)])),
      child: Center(child: SizedBox(width: w, height: h, child: Stack(clipBehavior: Clip.none, children: [
        button(h * 0.15, 30),               // Action button
        button(h * 0.235, 58),              // Volume up
        button(h * 0.32, 58),               // Volume down
        button(h * 0.25, 96, left: false),  // Side button
        button(h * 0.56, 46, left: false, width: 3), // Camera Control
        // Titanium edge
        Container(
          decoration: BoxDecoration(gradient: titanium, borderRadius: BorderRadius.circular(62),
              boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 80, offset: Offset(0, 34))]),
          padding: const EdgeInsets.all(edge),
          child: Container(
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(58)),
            padding: const EdgeInsets.all(bezel),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(51),
              child: Stack(children: [
                MediaQuery(
                  data: mq.copyWith(size: screen, padding: const EdgeInsets.only(top: statusH, bottom: homeH),
                      viewPadding: const EdgeInsets.only(top: statusH, bottom: homeH)),
                  child: widget.child,
                ),
                // iOS status bar
                Positioned(top: 0, left: 0, right: 0, height: statusH, child: IgnorePointer(child: Material(type: MaterialType.transparency,
                  child: ValueListenableBuilder<bool>(valueListenable: darkStatusBar, builder: (_, darkBg, _) => StreamBuilder<DateTime>(
                    stream: _clock,
                    builder: (_, snap) {
                      final t = snap.data ?? DateTime.now();
                      final time = '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')}';
                      final c = darkBg ? Colors.white : Colors.black;
                      return Row(children: [
                        Expanded(child: Center(child: Text(time,
                            style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)))),
                        const SizedBox(width: 126), // Dynamic Island
                        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _SignalBars(color: c), const SizedBox(width: 5),
                          Icon(Icons.wifi_rounded, size: 17, color: c), const SizedBox(width: 5),
                          _Battery(color: c),
                        ])),
                      ]);
                    },
                  )),
                ))),
                // Dynamic Island
                Positioned(top: 11, left: 0, right: 0, child: IgnorePointer(child: Center(child: Container(
                  width: 124, height: 36,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                  alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 12),
                  child: Container(width: 11, height: 11, decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [const Color(0xFF26304A), Colors.black.withValues(alpha: 0.9)]))),
                )))),
                // Home indicator
                Positioned(bottom: 8, left: 0, right: 0, child: IgnorePointer(child: ValueListenableBuilder<bool>(
                  valueListenable: darkStatusBar,
                  builder: (_, darkBg, _) => Center(child: Container(width: 136, height: 5,
                      decoration: BoxDecoration(color: darkBg ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(3)))),
                ))),
              ]),
            ),
          ),
        ),
      ]))),
    );
  }
}

/// iOS-style four signal bars.
class _SignalBars extends StatelessWidget {
  final Color color;
  const _SignalBars({required this.color});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 4; i++) Container(
          width: 3, height: 4.0 + i * 2.6, margin: const EdgeInsets.only(right: 1.5),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
        ),
      ]);
}

/// iOS-style battery: rounded outline, fill and a small cap.
class _Battery extends StatelessWidget {
  final Color color;
  const _Battery({required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 25, height: 12, padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.4))),
          child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.8,
              child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))),
        ),
        Container(width: 1.6, height: 4, margin: const EdgeInsets.only(left: 1),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(1))),
      ]);
}
