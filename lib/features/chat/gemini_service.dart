import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService({String? apiKey})
    : _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '',
        systemInstruction: Content.system(_persona),
      );

  // 元コードの値のまま。有効なモデル名か要確認（要件書では gemini-1.5-flash）
  static const _modelName = 'gemini-3.8-flash';

  static const _persona = '''
夜間の授乳や寝かしつけで悩む保護者の相談に乗ってください。
落ち着いた自然な話し言葉で、短く具体的に答えます。
絵文字や大げさな励ましは使いません。人間であるとは名乗りません。
体調や発育など医療判断が必要な内容は、小児科への相談を勧めてください。''';

  final GenerativeModel _model;

  /// 受信した分を連結したテキストを逐次流す。
  Stream<String> reply(String message) async* {
    var text = '';
    await for (final chunk in _model.generateContentStream([
      Content.text(message),
    ])) {
      final t = chunk.text;
      if (t == null || t.isEmpty) continue;
      text += t;
      yield text;
    }
  }
}
