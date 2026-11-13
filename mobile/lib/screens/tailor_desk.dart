// Tailor Studio Desk: incoming orders, cutting measurements, stage and payment, WIP photo updates.
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../state.dart';
import '../ui.dart';
import 'orders.dart';

class TailorDeskScreen extends StatefulWidget {
  const TailorDeskScreen({super.key});
  @override
  State<TailorDeskScreen> createState() => _TailorDeskScreenState();
}

class _TailorDeskScreenState extends State<TailorDeskScreen> {
  final replies = <String, TextEditingController>{};
  final wip = <String, Uint8List>{};

  @override
  void dispose() {
    for (final c in replies.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final active = s.orders.where((o) => o.stage != orderStages.last).length;
    final rush = s.orders.where((o) => o.isRushOrder).length;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      pageHeader('Tailor Studio Desk', 'Measurements, cut-sheets, stages and fitting photos.',
          image: 'assets/images/hero_atelier_studio.jpg', icon: Icons.work_outline, eyebrow: 'Studio management', inset: false, tint: const Color(0xFFE5ECF6),
          child: Row(children: [_stat(Icons.receipt_long, '${s.orders.length}', 'Orders', lavender), _stat(Icons.hourglass_bottom, '$active', 'In queue', const Color(0xFFFDE68A)), _stat(Icons.bolt, '$rush', 'Rush', const Color(0xFFFBCFE8), last: true)])),
      if (s.orders.isEmpty)
        card(padding: const EdgeInsets.all(26), child: const Column(children: [
          Icon(Icons.shopping_bag_outlined, color: purple, size: 34), SizedBox(height: 10),
          Text('No incoming client orders yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 6),
          Text('When a client submits an order from Book Fitting, their design, Fit Profile, and fabric notes appear here ready for cutting.',
              textAlign: TextAlign.center, style: TextStyle(color: muted)),
        ]))
      else
        for (final o in s.orders) Padding(padding: const EdgeInsets.only(bottom: 14), child: _order(s, o)),
    ]);
  }

  Widget _stat(IconData icon, String v, String k, Color tint, {bool last = false}) => Expanded(child: Container(
        height: 64, margin: EdgeInsets.only(right: last ? 0 : 8), padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 22, height: 22, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, size: 13, color: dark)),
            const SizedBox(width: 7),
            Text(v, style: const TextStyle(color: dark, fontSize: 17, fontWeight: FontWeight.w900, height: 1)),
          ]),
          Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      ));

  Widget _order(AppState s, TailoringOrder o) {
    final reply = replies.putIfAbsent(o.id, TextEditingController.new);
    final m = o.measurements;
    return card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 72, height: 92, child: orderImage(o.image))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${o.id} · ${o.createdAt}${o.isRushOrder ? ' · Rush deadline' : ''}', style: TextStyle(color: o.isRushOrder ? amber : muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
          Text(o.outfitName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('Profile: ${o.fitProfileLabel} · Fabric: ${o.fabricChoice}', style: const TextStyle(color: muted, fontSize: 12)),
          Text('${o.eventDate != null ? 'Event: ${o.eventDate} · ' : ''}${o.appointmentSlot ?? 'Measurements attached'}', style: const TextStyle(color: muted, fontSize: 12)),
          Text('Note: ${o.fabricNote}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ])),
      ]),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => showCutSheet(context, o), icon: const Icon(Icons.description_outlined, size: 18), label: const Text('Cut-Sheet'))),
      Container(
        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.content_cut, size: 16, color: purple), SizedBox(width: 6), Text('Cutting measurements (cm)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))]),
          const SizedBox(height: 6),
          Wrap(spacing: 12, runSpacing: 4, children: [for (final k in measurementKeys) Text('$k ${m[k]!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))]),
          if (o.tailorGuidance != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(o.tailorGuidance!, style: const TextStyle(color: muted, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(initialValue: o.stage, isExpanded: true, decoration: const InputDecoration(labelText: 'Production stage', isDense: true),
            items: [for (final x in orderStages) DropdownMenuItem(value: x, child: Text(x, overflow: TextOverflow.ellipsis))], onChanged: (v) => s.setStage(o, v!))),
        const SizedBox(width: 8),
        Expanded(child: DropdownButtonFormField<String>(initialValue: o.paymentStatus, isExpanded: true, decoration: const InputDecoration(labelText: 'Payment', isDense: true),
            items: [for (final x in paymentOptions) DropdownMenuItem(value: x, child: Text(x, overflow: TextOverflow.ellipsis))], onChanged: (v) => s.setPayment(o, v!))),
      ]),
      const SizedBox(height: 14),
      const Text('Send work-in-progress photo or fitting update', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 8),
      if (o.messages.isNotEmpty) for (final msg in o.messages) messageBubble(o, msg),
      if (wip[o.id] != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(wip[o.id]!, width: 64, height: 64, fit: BoxFit.cover)),
        TextButton(onPressed: () => setState(() => wip.remove(o.id)), child: const Text('Remove photo')),
      ])),
      TextField(controller: reply, decoration: const InputDecoration(isDense: true, hintText: 'e.g. Bodice basted for first fitting — how does the neckline look?')),
      const SizedBox(height: 8),
      Row(children: [
        OutlinedButton.icon(onPressed: () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 85);
          if (x != null) { final b = await x.readAsBytes(); setState(() => wip[o.id] = b); }
        }, icon: const Icon(Icons.photo_camera_outlined, size: 18), label: const Text('WIP Photo')),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: () {
          final t = reply.text.trim(), img = wip[o.id];
          if (t.isEmpty && img == null) return;
          s.postMessage(o, 'Tailor', t.isEmpty ? 'Work-in-progress fitting photo uploaded.' : t, img);
          reply.clear();
          setState(() => wip.remove(o.id));
        }, icon: const Icon(Icons.send, size: 18), label: const Text('Send Update'))),
      ]),
    ]));
  }
}
