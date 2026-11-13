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
      pageHeader('Fit Studio', 'Save named measurement profiles for yourself, group fittings, or family events.'),
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
      // Scan
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.photo_camera, color: lavender),
            const SizedBox(width: 10),
            Expanded(child: Text('AI Photo Scan (${p.label})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          const SizedBox(height: 4),
          Text('Front photo, plus an optional side photo for depth accuracy', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _darkField(TextField(
              controller: height, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
              decoration: _darkInput('Height anchor (cm)'),
              onChanged: (v) { final n = double.tryParse(v); if (n != null && n >= 140 && n <= 215) { p.heightCm = n; s.changed(); } },
            ))),
            const SizedBox(width: 10),
            Expanded(child: _darkField(DropdownButtonFormField<String>(
              initialValue: garment, dropdownColor: dark, style: const TextStyle(color: Colors.white), isExpanded: true,
              decoration: _darkInput('Garment style'),
              items: [for (final g in const ['Ankara / Couture', 'Modern Agbada', 'Classic Suit', 'Casual Co-ord']) DropdownMenuItem(value: g, child: Text(g))],
              onChanged: (v) => setState(() => garment = v!),
            ))),
          ]),
          const SizedBox(height: 14),
          _label('Preferred drape'),
          _pills(const ['Tailored', 'Relaxed', 'Structured'], p.fitPreference, (v) { p.fitPreference = v; s.changed(); }),
          const SizedBox(height: 12),
          _label('Self-timer (live auto-scan only)'),
          _pills(const ['5 seconds', '8 seconds', '12 seconds'], '$delay seconds', (v) => setState(() => delay = int.parse(v.split(' ').first))),
          const SizedBox(height: 16),
          if (front == null) ...[
            Text('Ask someone to photograph you from head to feet, facing the camera, in fitted clothes and good light.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5, height: 1.4)),
            const SizedBox(height: 12),
            FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: Colors.white, foregroundColor: purple),
                onPressed: _phoneCameraFront, icon: const Icon(Icons.photo_camera), label: const Text('Take front photo')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _darkButton(Icons.photo_library_outlined, 'From gallery', _uploadFront)),
              const SizedBox(width: 8),
              Expanded(child: _darkButton(Icons.add_a_photo_outlined, side != null ? 'Side ready' : 'Side photo', _sideChoice)),
            ]),
            const SizedBox(height: 4),
            Center(child: TextButton.icon(onPressed: _scan, icon: const Icon(Icons.timer_outlined, size: 16, color: Colors.white70),
                label: const Text('Live auto-scan with timer (beta)', style: TextStyle(color: Colors.white70)))),
          ] else ...[
            Row(children: [
              Expanded(child: _thumb(front!, 'Front', analyzing ? null : () => setState(() => front = null))),
              const SizedBox(width: 10),
              Expanded(child: side != null
                  ? _thumb(side!, 'Side', analyzing ? null : () => setState(() => side = null))
                  : AspectRatio(aspectRatio: 3 / 4, child: Material(
                      color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16),
                      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: analyzing ? null : () => _sideChoice(), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo_outlined, color: lavender), SizedBox(height: 6),
                        Text('Add Side Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text('Optional depth scan', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ])),
                    ))),
            ]),
            if (analyzing) const Padding(padding: EdgeInsets.only(top: 14), child: Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: lavender)), SizedBox(width: 10),
              Expanded(child: Text('Extracting body proportions & measurements...', style: TextStyle(color: Colors.white))),
            ])),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _darkButton(Icons.photo_camera, 'Retake front', analyzing ? null : _phoneCameraFront)),
              const SizedBox(width: 8),
              Expanded(child: _darkButton(Icons.photo_library_outlined, 'From gallery', analyzing ? null : _uploadFront)),
            ]),
          ],
          if (a != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.auto_awesome, color: lavender, size: 18), SizedBox(width: 6),
                    Text('Extracted Profile Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]),
                const SizedBox(height: 10),
                for (final (k, v) in [('Body build', a.details.bodyBuild), ('Base size', a.details.recommendedBaseSize), ('Shoulder profile', a.details.shoulderProfile),
                    ('Torso ratio', a.details.torsoProportion), ('Posture', a.details.postureNote), ('Scan quality', a.details.lightingAndFraming)])
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k.toUpperCase(), style: const TextStyle(color: lavender, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    Text(v, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ])),
                const Divider(color: Colors.white24),
                Text(a.silhouetteNote, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                const SizedBox(height: 6),
                Text('Ease: ${a.easeRecommendation}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                for (final n in a.tailorNotes) Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text('• $n', style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
              ]),
            ),
          ],
        ]),
      )),
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

  void _sideChoice() => showModalBottomSheet(context: context, builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Take side photo'), onTap: () { Navigator.pop(c); _addSide(camera: true); }),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose from gallery'), onTap: () { Navigator.pop(c); _addSide(); }),
      ])));

  Widget _slider(AppState s, FitProfile p, String k) {
    final b = measurementBounds[k]!;
    final v = p.measurements[k]!.clamp(b.min, b.max);
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(b.helper, style: const TextStyle(color: muted, fontSize: 11.5)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(10)),
            child: Text(fmt(v), style: const TextStyle(fontWeight: FontWeight.w800, color: purple, fontFeatures: [FontFeature.tabularFigures()]))),
      ]),
      Slider(value: v, min: b.min, max: b.max, divisions: ((b.max - b.min) * 2).round(), label: fmt(v),
          onChanged: (x) => setState(() => p.measurements[k] = x), onChangeEnd: (_) => s.changed()),
    ]));
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Text(t.toUpperCase(), style: const TextStyle(color: lavender, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)));

  Widget _pills(List<String> opts, String sel, void Function(String) on) => Row(children: [
        for (final o in opts) Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: Material(
          color: o == sel ? purple : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
          child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => on(o), child: Padding(padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(o, textAlign: TextAlign.center, style: TextStyle(color: o == sel ? Colors.white : Colors.white70, fontWeight: FontWeight.w700, fontSize: 12.5)))),
        ))),
      ]);

  InputDecoration _darkInput(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60), isDense: true,
      filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lavender)));

  Widget _darkField(Widget w) => Theme(data: Theme.of(context).copyWith(inputDecorationTheme: const InputDecorationTheme()), child: w);

  Widget _darkButton(IconData i, String t, VoidCallback? on) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), minimumSize: const Size.fromHeight(48)),
        onPressed: on, icon: Icon(i, size: 18), label: Text(t));

  Widget _thumb(Uint8List b, String label, VoidCallback? clear) => AspectRatio(aspectRatio: 3 / 4, child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          Image.memory(b, fit: BoxFit.cover),
          Positioned(left: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
          if (clear != null) Positioned(top: 6, right: 6, child: Material(color: Colors.black54, shape: const CircleBorder(),
              child: IconButton(visualDensity: VisualDensity.compact, onPressed: clear, icon: const Icon(Icons.close, color: Colors.white, size: 18)))),
        ]),
      ));
}
