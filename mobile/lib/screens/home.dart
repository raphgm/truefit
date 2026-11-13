// Home: editorial hero, AI Measurement Studio strip, lookbook with categories, booking banner.
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../state.dart';
import '../ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OutfitCategory? category; // null = For You

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final shown = category == null ? outfits : outfits.where((o) => o.category == category).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      // Hero
      ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(color: dark, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 230, child: Stack(fit: StackFit.expand, children: [
            Image.asset(heroImage, fit: BoxFit.cover),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, dark]))),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${houseAtelier.name.toUpperCase()} · BESPOKE STUDIO', style: const TextStyle(color: lavender, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Text('Your perfect fit.\nYour own style.', style: display(30, color: Colors.white)),
            const SizedBox(height: 10),
            Text('Explore made-to-measure Ankara, traditional, and contemporary silhouettes, capture your measurements automatically, or upload your own style inspiration.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), height: 1.45, fontSize: 14)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.white, foregroundColor: purple),
                  onPressed: () => s.go(AppTab.studio), child: const Text('Create Fit Profile'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3))), onPressed: () => s.go(AppTab.book), child: const Text('Book a Fitting'))),
            ]),
          ])),
        ])),
      ),
      const SizedBox(height: 16),
      // AI studio strip
      Material(
        color: lavender, borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20), onTap: () => s.go(AppTab.studio),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.auto_awesome, color: purple)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Measurement Studio', style: TextStyle(fontWeight: FontWeight.w800, color: dark)),
              SizedBox(height: 2),
              Text('Two-angle photo scan & named fit profiles for individual or group fittings.', style: TextStyle(color: muted, fontSize: 12.5)),
            ])),
            const Icon(Icons.arrow_forward, color: purple),
          ])),
        ),
      ),
      const SizedBox(height: 26),
      Text('Find your next look', style: display(24)),
      const SizedBox(height: 12),
      SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final c in <OutfitCategory?>[null, ...OutfitCategory.values])
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: Text(c == null ? 'For You' : categoryLabel[c]!), selected: category == c, showCheckmark: false,
            onSelected: (_) => setState(() => category = c),
            selectedColor: purple, labelStyle: TextStyle(fontWeight: FontWeight.w700, color: category == c ? Colors.white : dark),
            backgroundColor: Colors.white, side: const BorderSide(color: line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )),
      ])),
      const SizedBox(height: 16),
      LookbookGrid(items: shown),
      const SizedBox(height: 8),
      // Booking banner
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: peach, borderRadius: BorderRadius.circular(26)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.storefront, color: amber),
          const SizedBox(height: 8),
          Text('Ready for your custom piece?', style: display(22)),
          const SizedBox(height: 6),
          Text('Choose a lookbook piece or upload your own style inspiration, select your fabric and event date, and book directly with ${houseAtelier.name}.',
              style: const TextStyle(color: Color(0xFF5B4636), height: 1.45)),
          const SizedBox(height: 14),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: dark, minimumSize: const Size(0, 50)), onPressed: () => s.go(AppTab.book),
              child: const Text('Book Your Fitting')),
        ]),
      ),
    ]);
  }
}
