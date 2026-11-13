// Auto-scan camera: live preview, body outline, warm-up, then a self-timer that captures on its own.
// Pause, Capture now and Cancel like the web version. Falls back to the phone's own camera app.
// Returns the photo bytes, or null if cancelled.
import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../ui.dart';

class CaptureScreen extends StatefulWidget {
  final int seconds;
  final bool side;
  const CaptureScreen({super.key, required this.seconds, this.side = false});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _ctrl;
  List<CameraDescription> _cams = [];
  int _cam = 0;
  String? _error;
  int? _countdown;
  bool _warming = true, _paused = false, _busy = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _error == null && !(_ctrl?.value.isInitialized ?? false)) setState(() => _error = 'The live camera is taking too long to start.');
    });
    try {
      _cams = await availableCameras();
      if (_cams.isEmpty) throw CameraException('none', 'No camera found on this device.');
      // A self-scan: prefer the front (selfie) camera, as the web version does.
      final front = _cams.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cam = front >= 0 ? front : 0;
      await _open();
    } catch (e) {
      if (!mounted) return;
      final denied = e is CameraException && const {'CameraAccessDenied', 'cameraPermission', 'notAllowedError'}.contains(e.code);
      setState(() => _error = denied
          ? 'Camera permission was declined. Allow the camera for this app, or use the phone camera below.'
          : 'The live camera is unavailable${e is CameraException ? ': ${e.description ?? e.code}' : ''}.');
    }
  }

  Future<void> _open() async {
    final old = _ctrl;
    final c = CameraController(_cams[_cam], ResolutionPreset.high, enableAudio: false);
    await c.initialize();
    await old?.dispose();
    if (!mounted) { await c.dispose(); return; }
    setState(() { _ctrl = c; _warming = true; _countdown = widget.seconds; });
    // Let exposure settle for 1.2 s, then count down.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _warming = false);
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _paused || _busy) return;
        if ((_countdown ?? 0) <= 1) { _shoot(); return; }
        setState(() => _countdown = _countdown! - 1);
      });
    });
  }

  Future<void> _shoot() async {
    if (_ctrl == null || _busy) return;
    _tick?.cancel();
    setState(() { _busy = true; _countdown = 0; });
    try {
      final x = await _ctrl!.takePicture();
      final bytes = await x.readAsBytes();
      if (mounted) Navigator.pop<Uint8List>(context, bytes);
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'Could not take the photo ($e).'; });
    }
  }

  Future<void> _phoneCamera() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 88,
        preferredCameraDevice: widget.side ? CameraDevice.rear : CameraDevice.front);
    if (x == null) return;
    final b = await x.readAsBytes();
    if (mounted) Navigator.pop<Uint8List>(context, b);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    final ready = c != null && c.value.isInitialized;
    final status = !ready ? 'Opening camera...' : _warming ? 'Camera adjusting — step back into frame' : _paused ? 'Timer paused — adjust your stance'
        : (_countdown ?? 0) > 0 ? 'Hold steady · Capturing in ${_countdown}s' : 'Capturing frame...';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(widget.side ? 'Side profile scan' : 'AI photo scan'), actions: [
        IconButton(tooltip: "Use the phone's camera app", onPressed: _phoneCamera, icon: const Icon(Icons.add_a_photo_outlined)),
        if (_cams.length > 1) IconButton(tooltip: 'Switch camera', onPressed: () { _cam = (_cam + 1) % _cams.length; _open(); }, icon: const Icon(Icons.cameraswitch)),
      ]),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.no_photography, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: _phoneCamera, icon: const Icon(Icons.photo_camera), label: const Text("Use the phone's camera instead")),
              TextButton(onPressed: () { setState(() => _error = null); _start(); }, child: const Text('Try the live camera again', style: TextStyle(color: Colors.white70))),
              const SizedBox(height: 6),
              const Text('Tip: if you opened this inside WhatsApp or Instagram, open it in Chrome instead.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            ])))
          : !ready
              ? const Center(child: CircularProgressIndicator(color: lavender))
              : Stack(fit: StackFit.expand, children: [
                  Center(child: CameraPreview(c)),
                  const IgnorePointer(child: CustomPaint(painter: SilhouettePainter())),
                  Positioned(top: 12, left: 16, right: 16, child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(widget.side ? 'Turn sideways, arms down, whole body in view' : 'Align shoulders & hips inside the silhouette',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      if (!_warming && _countdown != null) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(value: (_countdown! / widget.seconds).clamp(0, 1), minHeight: 4,
                            backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(lavender)),
                      )),
                    ]),
                  )),
                  if (!_warming && (_countdown ?? 0) > 0)
                    Center(child: Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 110, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 20)]))),
                  Positioned(left: 16, right: 16, bottom: 20, child: Row(children: [
                    Expanded(child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), minimumSize: const Size.fromHeight(50)),
                      onPressed: _warming ? null : () => setState(() => _paused = !_paused), child: Text(_paused ? 'Resume' : 'Pause'))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        onPressed: _busy ? null : _shoot, child: const Text('Capture Now'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), minimumSize: const Size.fromHeight(50)),
                      onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  ])),
                ]),
    );
  }
}

/// The dashed body silhouette from the web scan (viewBox 200 x 260).
class SilhouettePainter extends CustomPainter {
  const SilhouettePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.height * 0.72) / 260;
    final dx = (size.width - 200 * scale) / 2, dy = size.height * 0.14;
    Offset p(double x, double y) => Offset(dx + x * scale, dy + y * scale);
    final path = Path()
      ..addOval(Rect.fromCircle(center: p(100, 42.5), radius: 20.5 * scale))
      ..moveTo(p(64, 78).dx, p(64, 78).dy);
    for (final (x, y) in const [(136.0, 78.0), (156.0, 142.0), (140.0, 148.0), (128.0, 102.0), (126.0, 168.0), (134.0, 242.0), (112.0, 242.0),
        (100.0, 176.0), (88.0, 242.0), (66.0, 242.0), (74.0, 168.0), (72.0, 102.0), (60.0, 148.0), (44.0, 142.0), (64.0, 78.0)]) {
      path.lineTo(p(x, y).dx, p(x, y).dy);
    }
    final paint = Paint()..color = lavender..style = PaintingStyle.stroke..strokeWidth = 2.5;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 11) {
        canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(SilhouettePainter old) => false;
}
