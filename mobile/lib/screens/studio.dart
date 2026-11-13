// Fit Studio: named fit profiles, two-angle AI photo scan, extracted details and measurement sliders.
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../ai.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';
import 'capture.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  bool inches = false, analyzing = false, adding = false;
  String garment = 'Ankara / Couture';
  int delay = 8;
  Uint8List? front, side;
  final newName = TextEditingController();
  late final TextEditingController height;
  String? _pid;

  @override
  void initState() {
    super.initState();
    height = TextEditingController();
  }

  String fmt(double cm) => '${(inches ? cm / 2.54 : cm).toStringAsFixed(1)} ${inches ? 'in' : 'cm'}';

  Future<Uint8List?> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    return x?.readAsBytes();
  }

  Future<void> _scan() async {
    final b = await Navigator.push<Uint8List>(context, MaterialPageRoute(builder: (_) => CaptureScreen(seconds: delay)));
    if (b == null) return;
    setState(() => front = b);
    _extract();
  }

  /// The phone's own camera (works on every phone and browser). Falls back to the gallery on a computer.
  Future<Uint8List?> _devicePhoto() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, maxWidth: 1600, imageQuality: 88);
      return x == null ? null : await x.readAsBytes();
    } catch (_) {
      if (mounted) AppScope.of(context).notify('The camera could not open, so choose a photo instead.');
      return _pick();
    }
  }

  Future<void> _phoneCameraFront() async {
    final b = await _devicePhoto();
    if (b == null || !mounted) return;
    setState(() => front = b);
    _extract();
  }

  Future<void> _uploadFront() async {
    final b = await _pick();
    if (b == null) return;
    setState(() => front = b);
    _extract();
  }

  Future<void> _addSide({bool camera = false}) async {
    final b = camera ? await _devicePhoto() : await _pick();
    if (b == null || !mounted) return;
    setState(() => side = b);
    if (front != null) {
      _extract();
    } else {
      AppScope.of(context).notify('Side profile attached. Capture or upload a front photo to run two-angle scan.');
    }
  }

  Future<void> _extract() async {
    final s = AppScope.of(context);
    final p = s.activeProfile;
    setState(() => analyzing = true);
    try {
      final r = await analyzeFit(heightCm: p.heightCm, fitPreference: p.fitPreference, garmentStyle: garment, front: front!, side: side);
      for (final k in measurementKeys) {
        final v = r.measurements[k];
        if (v == null || v.isNaN) continue;
        final b = measurementBounds[k]!;
        p.measurements[k] = (v.clamp(b.min, b.max) * 10).round() / 10;
      }
      p.analysis = r;
      p.updatedAt = shortDate(DateTime.now());
      s.notify(side != null ? 'Front & side scans analyzed. Measurements updated.' : 'Photo captured and fit details extracted.');
      s.changed();
    } on AiError catch (e) {
      s.notify(e.message);
    } catch (e) {
      s.notify('Could not extract fit details from photo.');
    } finally {
      if (mounted) setState(() => analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.activeProfile;
    if (_pid != p.id) { _pid = p.id; height.text = p.heightCm.round().toString(); front = null; side = null; }
    final a = p.analysis;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      pageHeader('Fit Studio', 'Measurement profiles for you, your family or a group.',
          image: 'assets/images/outfit_modern_agbada.jpg', icon: Icons.straighten, eyebrow: 'AI measurements', tint: const Color(0xFFEAE3FF),
          trailing: bannerChip(Icons.person_outline, '${s.profiles.length} ${s.profiles.length == 1 ? 'profile' : 'profiles'}')),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SegmentedButton<bool>(
        segments: const [ButtonSegment(value: false, label: Text('Centimeters (cm)')), ButtonSegment(value: true, label: Text('Inches (in)'))],
        selected: {inches}, showSelectedIcon: false, onSelectionChanged: (v) => setState(() => inches = v.first),
      )),
      const SizedBox(height: 14),
      // Profiles
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Fit Profiles (${s.profiles.length})', style: const TextStyle(fontWeight: FontWeight.w800))),
          if (s.profiles.length > 1) IconButton(tooltip: 'Delete selected', onPressed: s.deleteActiveProfile, icon: const Icon(Icons.delete_outline, color: rose)),
          TextButton.icon(onPressed: () => setState(() => adding = !adding), icon: const Icon(Icons.add), label: const Text('New')),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in s.profiles) ChoiceChip(
            label: Text(x.label), selected: x.id == p.id, showCheckmark: false, onSelected: (_) => s.selectProfile(x.id),
            selectedColor: purple, labelStyle: TextStyle(fontWeight: FontWeight.w700, color: x.id == p.id ? Colors.white : dark),
          ),
        ]),
        if (adding) Padding(padding: const EdgeInsets.only(top: 12), child: Row(children: [
          Expanded(child: TextField(controller: newName, autofocus: true, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(isDense: true, hintText: 'e.g. Partner, Bridesmaid, Mum'))),
          const SizedBox(width: 8),
          FilledButton(onPressed: () {
            final n = newName.text.trim();
            if (n.isEmpty) return s.notify('Enter a name for the new fit profile.');
            s.createProfile(n);
            newName.clear();
            setState(() { adding = false; front = null; side = null; });
          }, child: const Text('Create')),
        ])),
      ]))),
      const SizedBox(height: 14),
      // AI photo scan
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.auto_awesome, color: purple, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI photo scan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text('for ${p.label}', style: const TextStyle(color: muted, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 16),
        // 1. Your details
        _stepLabel('1', 'Your details'),
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(width: 110, child: TextField(
            controller: height, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height', suffixText: 'cm', isDense: true),
            onChanged: (v) { final n = double.tryParse(v); if (n != null && n >= 140 && n <= 215) { p.heightCm = n; s.changed(); } },
          )),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(
            initialValue: garment, isExpanded: true, decoration: const InputDecoration(labelText: 'Outfit style', isDense: true),
            items: [for (final g in const ['Ankara / Couture', 'Modern Agbada', 'Classic Suit', 'Casual Co-ord']) DropdownMenuItem(value: g, child: Text(g, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => garment = v!),
          )),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final d in const ['Tailored', 'Relaxed', 'Structured']) ChoiceChip(
            label: Text(d), selected: p.fitPreference == d, showCheckmark: false,
            onSelected: (_) { p.fitPreference = d; s.changed(); },
            selectedColor: purple, backgroundColor: bg, side: BorderSide(color: p.fitPreference == d ? purple : line),
            labelStyle: TextStyle(fontWeight: FontWeight.w700, color: p.fitPreference == d ? Colors.white : dark),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ]),
        const SizedBox(height: 18),
        // 2. Photos
        _stepLabel('2', 'Your photos'),
        const SizedBox(height: 4),
        const Text('Head to feet, facing the camera, fitted clothes, good light. Ask someone to take them.', style: TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _photoSlot('Front', 'Required', front, () => _photoChoice(true), () => setState(() => front = null))),
          const SizedBox(width: 10),
          Expanded(child: _photoSlot('Side', 'Optional, more accurate', side, () => _photoChoice(false), () => setState(() => side = null))),
        ]),
        if (analyzing) ...[
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(minHeight: 6, backgroundColor: lavender, color: purple)),
          const SizedBox(height: 6),
          const Text('Reading your proportions… this takes a few seconds.', style: TextStyle(color: muted, fontSize: 12)),
        ] else if (front != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: _extract, icon: const Icon(Icons.refresh, size: 18), label: const Text('Scan again')),
        ],
      ]))),
      if (a != null) ...[
        const SizedBox(height: 14),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _summary(a)),
      ],
      const SizedBox(height: 14),
      // Sliders
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a != null ? 'Extracted Measurements · ${p.label}' : 'Manual Fit Profile · ${p.label}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 2),
            const Text('Review AI estimates or fine-tune any dimension before saving.', style: TextStyle(color: muted, fontSize: 12.5)),
          ])),
          TextButton.icon(onPressed: () { p.measurements = defaultMeasurements(); p.analysis = null; s.notify('Reset measurements to baseline values.'); s.changed(); },
              icon: const Icon(Icons.restart_alt, size: 18), label: const Text('Reset')),
        ]),
        const SizedBox(height: 8),
        for (final k in measurementKeys) _slider(s, p, k),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: lavender.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Save "${p.label}"', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Text('Choose this profile when booking a custom fitting.', style: TextStyle(color: muted, fontSize: 12)),
            ])),
            FilledButton.icon(onPressed: s.saveProfile, icon: const Icon(Icons.check), label: const Text('Save')),
          ]),
        ),
      ]))),
    ]);
  }

  Widget _stepLabel(String n, String t) => Row(children: [
        Container(width: 22, height: 22, alignment: Alignment.center, decoration: const BoxDecoration(color: purple, shape: BoxShape.circle),
            child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w900))),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]);

  Widget _photoSlot(String title, String hint, Uint8List? img, VoidCallback add, VoidCallback clear) => AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: img != null
            ? Stack(fit: StackFit.expand, children: [
                Image.memory(img, fit: BoxFit.cover),
                Positioned(left: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
                if (!analyzing) Positioned(top: 6, right: 6, child: Material(color: Colors.black54, shape: const CircleBorder(),
                    child: IconButton(visualDensity: VisualDensity.compact, onPressed: clear, icon: const Icon(Icons.close, color: Colors.white, size: 18)))),
              ])
            : Material(color: bg, child: InkWell(onTap: analyzing ? null : add, child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: lavender, width: 2)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 46, height: 46, decoration: const BoxDecoration(color: lavender, shape: BoxShape.circle),
                      child: const Icon(Icons.add_a_photo_outlined, color: purple)),
                  const SizedBox(height: 8),
                  Text('$title photo', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
                ]),
              )))),
      );

  void _photoChoice(bool isFront) => showModalBottomSheet(context: context, showDragHandle: true,
      builder: (c) => StatefulBuilder(builder: (c, set) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera, color: purple), title: Text('Take ${isFront ? 'front' : 'side'} photo'), subtitle: const Text("Opens your phone's camera"),
            onTap: () { Navigator.pop(c); isFront ? _phoneCameraFront() : _addSide(camera: true); }),
        ListTile(leading: const Icon(Icons.photo_library_outlined, color: purple), title: const Text('Choose from gallery'),
            onTap: () { Navigator.pop(c); isFront ? _uploadFront() : _addSide(); }),
        if (isFront) ListTile(leading: const Icon(Icons.timer_outlined, color: purple), title: const Text('Live auto-scan (beta)'),
            subtitle: Row(children: [const Text('Timer: '), for (final t in const [5, 8, 12]) Padding(padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(visualDensity: VisualDensity.compact, label: Text('${t}s'), selected: delay == t, showCheckmark: false,
                    onSelected: (_) { setState(() => delay = t); set(() {}); }))]),
            onTap: () { Navigator.pop(c); _scan(); }),
      ])))));

  /// Calm, scannable summary of what the AI found; the long notes fold away.
  Widget _summary(FitAnalysis a) {
    final d = a.details;
    Widget fact(IconData i, String k, String v) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 18, color: purple), const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(v, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.35)),
            ])),
          ]),
        );
    return card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.auto_awesome, color: purple, size: 18), SizedBox(width: 6),
        Text('What the AI found', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [purple, Color(0xFF4B2FB8)]), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suggested base size', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(d.recommendedBaseSize, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1.25)),
        ]),
      ),
      const SizedBox(height: 10),
      fact(Icons.accessibility_new, 'Body build', d.bodyBuild),
      const SizedBox(height: 8),
      fact(Icons.open_in_full, 'Shoulders', d.shoulderProfile),
      const SizedBox(height: 8),
      fact(Icons.straighten, 'Ease', a.easeRecommendation),
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text('More notes for your tailor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: purple)),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (k, v) in [('Torso', d.torsoProportion), ('Posture', d.postureNote), ('Silhouette', a.silhouetteNote), ('Photo quality', d.lightingAndFraming)])
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text.rich(TextSpan(children: [
                TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: v, style: const TextStyle(color: muted)),
              ]), style: const TextStyle(fontSize: 12.5, height: 1.4))),
            for (final n in a.tailorNotes) Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $n', style: const TextStyle(color: muted, fontSize: 12.5, height: 1.4))),
          ],
        ),
      ),
    ]));
  }

  Widget _slider(AppState s, FitProfile p, String k) {
    final b = measurementBounds[k]!;
    final v = p.measurements[k]!.clamp(b.min, b.max);
    void nudge(double d) { setState(() => p.measurements[k] = (v + d).clamp(b.min, b.max)); s.changed(); }
    Widget step(IconData i, double d) => SizedBox(width: 34, height: 34, child: IconButton.filledTonal(
        padding: EdgeInsets.zero, iconSize: 18, onPressed: () => nudge(d), icon: Icon(i),
        style: IconButton.styleFrom(backgroundColor: lavender, foregroundColor: purple)));
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.fromLTRB(14, 12, 10, 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(b.helper, style: const TextStyle(color: muted, fontSize: 11.5)),
          ])),
          step(Icons.remove, inches ? -0.635 : -0.5),
          Container(width: 82, alignment: Alignment.center,
              child: Text(fmt(v), style: const TextStyle(fontWeight: FontWeight.w900, color: purple, fontSize: 15, fontFeatures: [FontFeature.tabularFigures()]))),
          step(Icons.add, inches ? 0.635 : 0.5),
        ]),
        Slider(value: v, min: b.min, max: b.max, divisions: ((b.max - b.min) * 2).round(), label: fmt(v),
            onChanged: (x) => setState(() => p.measurements[k] = x), onChangeEnd: (_) => s.changed()),
      ]),
    );
  }

}
