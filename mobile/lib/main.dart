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
        navigationBarTheme: NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: lavender,
            labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ),
      home: const Root(),
      // In a computer browser, show the app inside a phone-sized frame.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        if (mq.size.width < 600) return child!;
        final h = (mq.size.height - 48).clamp(560.0, 900.0);
        return ColoredBox(color: const Color(0xFF16131D), child: Center(child: Container(
          width: 412, height: h,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(44), color: Colors.black, border: Border.all(color: Colors.black, width: 10),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 60, offset: Offset(0, 24))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(34), child: MediaQuery(data: mq.copyWith(size: Size(392, h - 20)), child: child!)),
        )));
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
