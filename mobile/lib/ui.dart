// Shared colours and widgets: lookbook grid, outfit detail sheet, cut-sheet, order image.
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'state.dart';

const purple = Color(0xFF7654E8);
const purpleDark = Color(0xFF6442D6);
const dark = Color(0xFF211D2B);
const bg = Color(0xFFFAF8FC);
const muted = Color(0xFF6E687B);
const lavender = Color(0xFFEAE3FF);
const peach = Color(0xFFFFE9D9);
const rose = Color(0xFFE11D48);
const amber = Color(0xFFB45309);
const line = Color(0x14211D2B);

/// True while a dark full-screen view is showing, so the browser phone frame draws a light status bar.
final darkStatusBar = ValueNotifier<bool>(false);

TextStyle display(double size, {Color color = dark}) => TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5, height: 1.1);
const eyebrow = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: purple);

Widget card({required Widget child, EdgeInsets padding = const EdgeInsets.all(18), Color color = Colors.white}) => Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
      child: child,
    );

Widget pageHeader(String title, String subtitle, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: display(28)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: muted, height: 1.4)),
        ])),
        ?trailing,
      ]),
    );

Widget orderImage(OrderImage img, {BoxFit fit = BoxFit.cover}) => img.bytes != null
    ? Image.memory(img.bytes!, fit: fit)
    : Image.asset(img.asset ?? heroImage, fit: fit, errorBuilder: (_, _, _) => const ColoredBox(color: lavender, child: Center(child: Icon(Icons.checkroom, color: purple))));

/// Two staggered columns of outfit cards, like the web lookbook.
class LookbookGrid extends StatelessWidget {
  final List<Outfit> items;
  const LookbookGrid({super.key, required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(padding: const EdgeInsets.all(32), child: Column(children: [
        const Icon(Icons.checkroom, size: 40, color: purple),
        const SizedBox(height: 10),
        Text('No looks match this category', style: display(17)),
        const SizedBox(height: 4),
        const Text('Select "For You" to browse the full TrueFit AI lookbook.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
      ]));
    }
    final left = [for (var i = 0; i < items.length; i += 2) items[i]];
    final right = [for (var i = 1; i < items.length; i += 2) items[i]];
    Widget col(List<Outfit> l) => Expanded(child: Column(children: [for (final o in l) Padding(padding: const EdgeInsets.only(bottom: 16), child: OutfitCard(outfit: o))]));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [col(left), const SizedBox(width: 12), col(right)]);
  }
}

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  const OutfitCard({super.key, required this.outfit});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final saved = s.favorites.contains(outfit.id);
    return GestureDetector(
      onTap: () => showOutfit(context, outfit),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: outfit.aspect, child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: Color(outfit.tint)),
            Hero(tag: 'outfit-${outfit.id}', child: Image.asset(outfit.image, fit: BoxFit.cover)),
            Positioned(top: 8, right: 8, child: Material(
              color: Colors.white.withValues(alpha: 0.92), shape: const CircleBorder(),
              child: IconButton(visualDensity: VisualDensity.compact, onPressed: () => s.toggleFavorite(outfit.id),
                  icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? rose : dark, size: 20)),
            )),
          ]),
        )),
        const SizedBox(height: 8),
        Text('${categoryLabel[outfit.category]} · ${outfit.leadTime}', style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(outfit.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: dark)),
        Text(outfit.priceLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: purple, fontSize: 13)),
      ]),
    );
  }
}

void showOutfit(BuildContext context, Outfit o) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.white, useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) {
      final s = AppScope.of(c);
      final saved = s.favorites.contains(o.id);
      return DraggableScrollableSheet(
        expand: false, initialChildSize: 0.92, maxChildSize: 0.95,
        builder: (c, scroll) => ListView(controller: scroll, padding: EdgeInsets.zero, children: [
          Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Container(color: Color(o.tint), height: 380, width: double.infinity,
                    child: Hero(tag: 'outfit-${o.id}', child: Image.asset(o.image, fit: BoxFit.cover, alignment: Alignment.topCenter)))),
            Positioned(top: 12, right: 12, child: Material(color: Colors.white, shape: const CircleBorder(),
                child: IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)))),
          ]),
          Padding(padding: const EdgeInsets.fromLTRB(22, 20, 22, 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${categoryLabel[o.category]!.toUpperCase()} · ${o.leadTime}', style: eyebrow),
            const SizedBox(height: 6),
            Text(o.name, style: display(28)),
            const SizedBox(height: 6),
            Text(o.priceLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: purple)),
            const SizedBox(height: 12),
            Text(o.description, style: const TextStyle(color: muted, height: 1.5, fontSize: 15)),
            const SizedBox(height: 16),
            _kv('Fabric', o.fabric),
            _kv('Crafted by', '${houseAtelier.name} · ${houseAtelier.location}'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: saved ? const Color(0xFF9F1239) : dark,
                    backgroundColor: saved ? const Color(0xFFFFE4EF) : null),
                onPressed: () { s.toggleFavorite(o.id); Navigator.pop(c); },
                icon: Icon(saved ? Icons.favorite : Icons.favorite_border), label: Text(saved ? 'Saved' : 'Save Look'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () { Navigator.pop(c); s.bookOutfit(o); },
                icon: const Icon(Icons.content_cut), label: const Text('Book Fitting'))),
            ]),
          ])),
        ]),
      );
    },
  );
}

Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 92, child: Text(k, style: const TextStyle(color: muted, fontSize: 13))),
      Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: dark))),
    ]));

/// The tailor's pattern cut-sheet for an order.
void showCutSheet(BuildContext context, TailoringOrder o) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => DraggableScrollableSheet(expand: false, initialChildSize: 0.9, builder: (c, scroll) => ListView(
      controller: scroll, padding: const EdgeInsets.all(22), children: [
        Row(children: [
          Expanded(child: Text('BESPOKE PATTERN CUT-SHEET · ${o.id}', style: eyebrow)),
          IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close)),
        ]),
        Text(o.outfitName, style: display(24)),
        const SizedBox(height: 4),
        Text('${o.atelierName} · Profile: ${o.fitProfileLabel} · Ordered ${o.createdAt}', style: const TextStyle(color: muted)),
        const SizedBox(height: 16),
        ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 200, width: double.infinity, child: orderImage(o.image))),
        const SizedBox(height: 18),
        const Text('Garment Measurements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder(horizontalInside: BorderSide(color: dark.withValues(alpha: 0.08))),
          columnWidths: const {0: FlexColumnWidth(1.3)},
          children: [
            const TableRow(children: [_Th('Dimension'), _Th('Metric (cm)'), _Th('Imperial (in)')]),
            for (final k in measurementKeys) TableRow(children: [
              _Td(k, bold: true), _Td('${o.measurements[k]!.toStringAsFixed(1)} cm'), _Td('${(o.measurements[k]! / 2.54).toStringAsFixed(1)} in'),
            ]),
          ],
        ),
        const SizedBox(height: 18),
        _kv('Fabric', o.fabricChoice),
        _kv('Event date', '${o.eventDate ?? 'Standard turnaround'}${o.isRushOrder ? ' (Rush)' : ''}'),
        _kv('Fitting slot', o.appointmentSlot ?? 'Measurements attached'),
        _kv('Payment', o.paymentStatus),
        _kv('Client notes', o.fabricNote),
        if (o.tailorGuidance != null) _kv('AI notes', o.tailorGuidance!),
      ],
    )),
  );
}

class _Th extends StatelessWidget {
  final String t;
  const _Th(this.t);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(t, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)));
}

class _Td extends StatelessWidget {
  final String t;
  final bool bold;
  const _Td(this.t, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(t, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: dark)));
}
