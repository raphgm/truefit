// Calls the TrueFit server (server.ts), which holds the Gemini key. The key never ships in the app.
//
// Server address:
//  - Web build served by server.ts: leave API_BASE empty and the app calls /api/... on the same site.
//  - Android: build with --dart-define=API_BASE=https://your-truefit-server
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

const apiBase = String.fromEnvironment('API_BASE');

class AiError implements Exception {
  final String message;
  AiError(this.message);
  @override
  String toString() => message;
}

Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
  final http.Response res;
  try {
    res = await http.post(Uri.parse('$apiBase$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 90));
  } catch (_) {
    throw AiError(apiBase.isEmpty
        ? 'Could not reach the TrueFit Studio server. Adjust the measurements by hand, or try again when online.'
        : 'Could not reach the TrueFit Studio server at $apiBase. Check your connection and try again.');
  }
  Map<String, dynamic> data;
  try {
    data = jsonDecode(res.body) as Map<String, dynamic>;
  } catch (_) {
    throw AiError('The AI server sent an unexpected reply (HTTP ${res.statusCode}).');
  }
  if (res.statusCode >= 400) throw AiError('${data['error'] ?? 'AI request failed.'}');
  return data;
}

String mimeOf(Uint8List b) => b.length > 3 && b[0] == 0x89 && b[1] == 0x50 ? 'image/png' : 'image/jpeg';

Future<FitAnalysis> analyzeFit({required double heightCm, required String fitPreference, required String garmentStyle,
    required Uint8List front, Uint8List? side}) async {
  final j = await _post('/api/fit-analyze', {
    'heightCm': heightCm, 'fitPreference': fitPreference, 'garmentStyle': garmentStyle,
    'imageBase64': base64Encode(front), 'imageMimeType': mimeOf(front),
    if (side != null) 'sideImageBase64': base64Encode(side), if (side != null) 'sideImageMimeType': mimeOf(side),
  });
  return FitAnalysis.fromJson(j);
}

Future<StyleAnalysis> analyzeStyle({required Uint8List photo, required double heightCm}) async {
  final j = await _post('/api/style-analyze', {'imageBase64': base64Encode(photo), 'imageMimeType': mimeOf(photo), 'heightCm': heightCm});
  return StyleAnalysis.fromJson(j);
}
