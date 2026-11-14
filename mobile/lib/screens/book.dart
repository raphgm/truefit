// Book a custom order: lookbook style or your own inspiration photo, fit profile, fabric, date, slot, notes.
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../ai.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});
  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  bool custom = false, analyzing = false;
  String outfitId = outfits.first.id, fabric = studioFabrics.first, slot = fittingSlots.first;
  DateTime? eventDate;
  Uint8List? photo;
  StyleAnalysis? style;
  final notes = TextEditingController();
  final _scroll = ScrollController();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 730)), initialDate: eventDate ?? now.add(const Duration(days: 21)));
    if (d != null) setState(() => eventDate = d);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pre = AppScope.of(context).preselected;
    if (pre != null) { custom = false; outfitId = pre.id; }
  }

  Outfit get outfit => outfitById(outfitId);

  bool get rush {
    if (eventDate == null) return false;
    final today = DateTime.now();
    final days = DateTime(eventDate!.year, eventDate!.month, eventDate!.day).difference(DateTime(today.year, today.month, today.day)).inDays;
    return days >= 0 && days < (custom ? 10 : outfit.minDays);
  }

  Future<void> _upload() async {
    final s = AppScope.of(context);
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    if (x == null) return;
    final b = await x.readAsBytes();
    setState(() { photo = b; style = null; analyzing = true; });
    try {
      final r = await analyzeStyle(photo: b, heightCm: s.activeProfile.heightCm);
      if (mounted) setState(() => style = r);
      s.notify('Custom style analyzed with fabric & yardage estimate.');
    } on AiError catch (e) {
      s.notify('${e.message} The photo is saved; add notes by hand below.');
    } catch (_) {
      s.notify('Uploaded photo saved. Add notes manually below.');
    } finally {
      if (mounted) setState(() => analyzing = false);
    }
  }

  void _submit(AppState s) {
    if (custom && photo == null) return s.notify('Please upload an inspiration photo or switch to Lookbook Style.');
    final d = eventDate;
    s.placeOrder(
      outfitName: custom ? (style?.garmentTitle.isNotEmpty == true ? style!.garmentTitle : 'Custom Inspiration Design') : outfit.name,
      image: custom ? OrderImage(bytes: photo) : OrderImage(asset: outfit.image),
      priceLabel: custom ? 'Custom quote on review' : outfit.priceLabel,
      isCustom: custom, style: custom ? style : null, fabricChoice: fabric,
      fabricNote: notes.text.trim().isEmpty ? 'Standard studio finish' : notes.text.trim(),
      eventDate: d == null ? null : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      isRush: rush, slot: slot, profile: s.activeProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.activeProfile;
    return ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
      // Banner
      pageHeader('Book a Fitting', '${houseAtelier.location} · Turnaround ${houseAtelier.turnaround}',
          image: 'assets/images/outfit_elegant_boubou.jpg', icon: Icons.content_cut, eyebrow: houseAtelier.name, inset: false, tint: const Color(0xFFFFF1D6),
          trailing: houseAtelier.rating > 0 ? bannerChip(Icons.star_rounded, houseAtelier.rating.toStringAsFixed(1)) : null),
      const SizedBox(height: 4),
      Text('Book a Custom Order', style: display(24)),
      const SizedBox(height: 4),
      const Text('Pick a studio look or upload your own style inspiration.', style: TextStyle(color: muted)),
      const SizedBox(height: 12),
      SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('Lookbook Style')), ButtonSegment(value: true, label: Text('Upload Custom Style'))],
        selected: {custom}, showSelectedIcon: false, onSelectionChanged: (v) => setState(() => custom = v.first),
      ),
      const SizedBox(height: 14),
      // Design preview
      if (!custom) ...[
        DropdownButtonFormField<String>(
          initialValue: outfitId, isExpanded: true, decoration: const InputDecoration(labelText: 'Select style from lookbook'),
          items: [for (final o in outfits) DropdownMenuItem(value: o.id, child: Text('${o.name} — ${o.priceLabel} (${o.leadTime})', overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => outfitId = v!),
        ),
        const SizedBox(height: 12),
        card(padding: EdgeInsets.zero, child: Row(children: [
          ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
              child: Container(color: Color(outfit.tint), width: 120, height: 160, child: Image.asset(outfit.image, fit: BoxFit.cover))),
          Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${categoryLabel[outfit.category]!.toUpperCase()} · ${outfit.leadTime}', style: eyebrow),
            const SizedBox(height: 4),
            Text(outfit.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(outfit.priceLabel, style: const TextStyle(color: purple, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('House material: ${outfit.fabric}', style: const TextStyle(color: muted, fontSize: 12)),
          ]))),
        ])),
      ] else ...[
        Material(
          color: lavender.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20),
          child: InkWell(borderRadius: BorderRadius.circular(20), onTap: analyzing ? null : _upload, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            if (analyzing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text('Inspecting garment silhouette & estimating fabric yardage...', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
            ] else ...[
              const Icon(Icons.upload, color: purple, size: 30),
              const SizedBox(height: 6),
              Text(photo == null ? 'Upload Photo or Screenshot of Outfit' : 'Replace Custom Outfit Photo', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Text('AI estimates required yardage and neckline/sleeve details', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
            ],
          ]))),
        ),
        if (photo != null) ...[
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(photo!, height: 260, width: double.infinity, fit: BoxFit.cover)),
        ],
        if (style != null) ...[
          const SizedBox(height: 12),
          card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${style!.categoryGuess.toUpperCase()} · ${style!.estimatedLeadTime}', style: eyebrow),
            const SizedBox(height: 4),
            Text(style!.garmentTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            Text('Suggested fabric: ${style!.suggestedFabric}', style: const TextStyle(fontSize: 13)),
            Text('Estimated yardage: ${style!.estimatedYards}', style: const TextStyle(fontSize: 13)),
            for (final d in style!.constructionDetails) Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $d', style: const TextStyle(color: muted, fontSize: 12.5))),
          ])),
        ],
      ],
      const SizedBox(height: 16),
      // Fit profile
      card(color: lavender.withValues(alpha: 0.35), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            initialValue: p.id, isExpanded: true, decoration: const InputDecoration(labelText: 'Attach fit profile', isDense: true),
            items: [for (final x in s.profiles) DropdownMenuItem(value: x.id, child: Text(x.label))], onChanged: (v) => s.selectProfile(v!),
          )),
          const SizedBox(width: 8),
          TextButton.icon(onPressed: () => s.go(AppTab.studio), icon: const Icon(Icons.straighten, size: 18), label: const Text('Edit')),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final k in measurementKeys) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text('$k: ${p.measurements[k]!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      ])),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(initialValue: fabric, isExpanded: true, decoration: const InputDecoration(labelText: 'Fabric selection'),
          items: [for (final f in studioFabrics) DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))], onChanged: (v) => setState(() => fabric = v!)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), alignment: Alignment.centerLeft, backgroundColor: Colors.white),
        icon: const Icon(Icons.calendar_month),
        label: Text(eventDate == null ? 'Target event / needed by date' : 'Needed by ${shortDate(eventDate!, year: true)}'),
        onPressed: _pickDate,
      ),
      if (rush) Container(
        margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x33B45309))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, color: amber),
          const SizedBox(width: 10),
          Expanded(child: Text('Rush turnaround: this date is sooner than the standard lead time. ${houseAtelier.name} will confirm express slot availability when reviewing your request.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF7C2D12)))),
        ]),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(initialValue: slot, isExpanded: true, decoration: const InputDecoration(labelText: 'Fitting check-in appointment'),
          items: [for (final f in fittingSlots) DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))], onChanged: (v) => setState(() => slot = v!)),
      const SizedBox(height: 12),
      TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Custom notes (colour, neckline, sleeve adjustments)',
          hintText: 'Preferred shade, embroidery placement, or fit preference...', alignLabelWithHint: true)),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        onPressed: analyzing ? null : () => _submit(s), icon: const Icon(Icons.check),
        label: Text('Submit Order (${custom ? 'Custom Quote' : outfit.priceLabel})'),
      ),
      const SizedBox(height: 28),
      _howItWorks(s),
    ]);
  }

  /// "How your order works" as a live timeline: each step shows done / next / to come and takes you there.
  Widget _howItWorks(AppState s) {
    final measured = s.profiles.any((p) => p.analysis != null || !(p.updatedAt == 'Baseline profile' || p.updatedAt == 'New profile'));
    final steps = <(IconData, String, String, bool, VoidCallback)>[
      (Icons.checkroom, 'Choose or upload a look', custom ? (photo != null ? 'Your inspiration photo is ready' : 'Upload your inspiration photo') : 'Selected: ${outfit.name}',
          !custom || photo != null, () => _scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut)),
      (Icons.straighten, 'Scan your fit profile', measured ? '${s.activeProfile.label} is ready' : 'Measure with photos in Fit Studio', measured, () => s.go(AppTab.studio)),
      (Icons.event, 'Select fabric and date', eventDate == null ? 'Pick your event or needed-by date' : '$fabric · ${shortDate(eventDate!, year: true)}', eventDate != null, _pickDate),
      (Icons.local_shipping_outlined, 'Track progress and delivery', s.orders.isEmpty ? 'Fitting photos, stage updates and delivery notices' : '${s.orders.length} ${s.orders.length == 1 ? 'order' : 'orders'} in progress',
          s.orders.isNotEmpty, () => s.go(AppTab.orders)),
    ];
    final next = steps.indexWhere((x) => !x.$4);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('How your order works', style: display(19))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(20)),
              child: Text('${steps.where((x) => x.$4).length} of ${steps.length} done', style: const TextStyle(color: purple, fontWeight: FontWeight.w800, fontSize: 12))),
        ]),
        const SizedBox(height: 14),
        for (var i = 0; i < steps.length; i++) IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: 40, child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: steps[i].$4 ? purple : (i == next ? Colors.white : bg),
                  border: Border.all(color: steps[i].$4 || i == next ? purple : line, width: 2),
                  boxShadow: i == next ? [BoxShadow(color: purple.withValues(alpha: 0.25), blurRadius: 12)] : null),
              child: Icon(steps[i].$4 ? Icons.check_rounded : steps[i].$1, size: 18, color: steps[i].$4 ? Colors.white : (i == next ? purple : muted)),
            ),
            if (i < steps.length - 1) Expanded(child: Container(width: 3, margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: steps[i].$4 ? purple : line, borderRadius: BorderRadius.circular(2)))),
          ])),
          const SizedBox(width: 12),
          Expanded(child: InkWell(
            borderRadius: BorderRadius.circular(14), onTap: steps[i].$5,
            child: Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 16), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Step ${i + 1}${i == next ? ' · next' : ''}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: i == next ? purple : muted, letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(steps[i].$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(steps[i].$3, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12.5)),
              ])),
              const Icon(Icons.chevron_right, color: muted),
            ])),
          )),
        ])),
      ]),
    );
  }
}
