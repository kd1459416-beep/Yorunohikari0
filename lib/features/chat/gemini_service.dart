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
夜間の授乳や寝かしつけ、育児の孤独感で悩む保護者の相談に乗ってください。
以下の対話プロセスを大切にして応答します：

1. 【感情の承認（Emotional Validation）】
   解決策や具体的なアドバイスを急ぐ前に、まずは「夜中に一人で本当にお疲れ様です」
  「眠れない中、十分頑張っていますよ」と、保護者の辛さや感情を無条件に受け止め、肯定してください。
2. 【同調性と低負荷な応答（Attunement）】
   深夜で疲労している保護者のペースに寄り添い、落ち着いた自然な話し言葉で、
   3〜4行程度の短く優しい文章で答えます。絵文字や大げさな励ましは使いません。
3. 【安全の確保と専門家への誘導】
   人間であるとは名乗りません。体調や発育など医療判断が必要な内容は小児科や#8000への相談を勧め、
   もし強い希死念慮や赤ちゃんを傷つけそうな衝動が語られた場合は、
   否定せず寄り添った上で地域の保健センターや相談窓口への連絡を優しく促してください。''';

  final GenerativeModel _model;

  /// 過去の会話履歴とユーザー情報（任意）を踏まえて応答を逐次流す
  Stream<String> reply(
    String message, {
    List<Content> history = const [],
    String? babyContext, // 例: "生後3ヶ月の赤ちゃんを育児中"
  }) async* {
    // 1. 過去の会話履歴をセットしてチャットセッションを開始（文脈の記憶）
    final chat = _model.startChat(history: history);

    // 2. ユーザーの状況（月齢など）があれば、文脈としてメッセージに添える
    final prompt = (babyContext != null && babyContext.isNotEmpty)
        ? '【相談者の状況: $babyContext】\n$message'
        : message;

    // 3. ストリーミングで返信を受信
    var text = '';
    await for (final chunk in chat.sendMessageStream(Content.text(prompt))) {
      final t = chunk.text;
      if (t == null || t.isEmpty) continue;
      text += t;
      yield text;
    }
  }
}
