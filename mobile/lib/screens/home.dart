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
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(height: 400, child: Stack(fit: StackFit.expand, children: [
          Image.asset(heroImage, fit: BoxFit.cover),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x00211D2B), Color(0x66211D2B), Color(0xF2211D2B)], stops: [0.15, 0.45, 0.85]))),
          Positioned(top: 14, left: 14, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
            child: Text(houseAtelier.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: dark)),
          )),
          Positioned(left: 20, right: 20, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your perfect fit.\nYour own style.', style: display(30, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Made-to-measure Ankara, traditional and contemporary pieces, cut to your AI-scanned measurements.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.82), height: 1.4, fontSize: 13.5)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: Colors.white, foregroundColor: purple, padding: const EdgeInsets.symmetric(horizontal: 10)),
                onPressed: () => s.go(AppTab.studio), icon: const Icon(Icons.straighten, size: 18), label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Get measured', maxLines: 1)))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: purple, padding: const EdgeInsets.symmetric(horizontal: 10)),
                onPressed: () => s.go(AppTab.book), icon: const Icon(Icons.content_cut, size: 18), label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Book fitting', maxLines: 1)))),
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
