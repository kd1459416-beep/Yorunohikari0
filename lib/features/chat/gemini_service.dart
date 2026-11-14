import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// 会話の1ターン（履歴として Gemini に渡す）
class AiTurn {
  const AiTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// 失敗の種類。画面には [GeminiFailure.userMessage] をそのまま出せる。
enum GeminiFailureKind {
  missingKey,
  invalidKey,
  overloaded,
  timeout,
  quota,
  blocked,
  network,
  unknown,
}

class GeminiFailure implements Exception {
  const GeminiFailure(this.kind);

  final GeminiFailureKind kind;

  String get userMessage => switch (kind) {
    GeminiFailureKind.missingKey =>
      'APIキーが設定されていません。.env の GEMINI_API_KEY を確認してください。',
    GeminiFailureKind.invalidKey => 'APIキーが正しくないか、利用が許可されていません。',
    GeminiFailureKind.overloaded => 'いま混み合っていて、回答できませんでした。少し待って、もう一度送ってください。',
    GeminiFailureKind.timeout => '回答に時間がかかっています。少し待って、もう一度送ってください。',
    GeminiFailureKind.quota => '利用回数の上限に達しました。しばらくしてからお試しください。',
    GeminiFailureKind.blocked => '内容の都合で回答を作れませんでした。言い方を変えて送ってみてください。',
    GeminiFailureKind.network => '通信できませんでした。接続を確認して、もう一度送ってください。',
    GeminiFailureKind.unknown => '回答を取得できませんでした。もう一度お試しください。',
  };

  /// 少し待ってから、同じモデルでもう一度試す価値があるか
  bool get canRetry =>
      kind == GeminiFailureKind.overloaded || kind == GeminiFailureKind.network;

  /// 別のモデルでも同じ結果になるので、すぐ打ち切るか
  bool get isFatal =>
      kind == GeminiFailureKind.missingKey ||
      kind == GeminiFailureKind.invalidKey ||
      kind == GeminiFailureKind.blocked;
}

/// Gemini API との通信だけを担当する。画面や保存の処理は知らない。
class GeminiService {
  /// 先頭から順に試す。速くて混みにくい lite を先に使い、だめなら 3.8 に切り替える
  static const _models = ['gemini-3.5-flash-lite', 'gemini-3.8-flash'];

  /// 同じモデルでの再試行は、混雑のときだけ1回
  static const _maxRetries = 1;
  static const _retryDelay = Duration(seconds: 1);

  /// 次の文字が届くまでの待ち時間の上限。超えたら、待たずに次のモデルへ切り替える
  static const _idleTimeout = Duration(seconds: 15);

  static const _persona = '''
夜間の授乳や寝かしつけで悩む保護者の相談に乗ってください。
落ち着いた自然な話し言葉で、短く具体的に答えます。
絵文字や大げさな励ましは使いません。人間であるとは名乗りません。
体調や発育など医療判断が必要な内容は、小児科への相談を勧めてください。''';

  /// 回答を、届いた分までつなげたテキストとして、少しずつ流す。
  /// 失敗したときは [GeminiFailure] を投げる。
  Stream<String> reply(
    String message, {
    List<AiTurn> history = const [],
  }) async* {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw const GeminiFailure(GeminiFailureKind.missingKey);

    GeminiFailure? lastFailure;
    for (final modelName in _models) {
      for (var attempt = 0; attempt <= _maxRetries; attempt++) {
        var emittedAnything = false;
        try {
          await for (final text in _streamFrom(
            modelName,
            apiKey,
            message,
            history,
          )) {
            emittedAnything = true;
            yield text;
          }
          return; // 成功
        } catch (error) {
          final failure = _classify(error);
          lastFailure = failure;
          debugPrint('Gemini失敗 [$modelName / ${attempt + 1}回目]: $error');

          // 途中まで出ているもの・どのモデルでも同じ失敗は、やり直さない
          if (emittedAnything || failure.isFatal) throw failure;

          if (failure.canRetry && attempt < _maxRetries) {
            await Future<void>.delayed(_retryDelay);
            continue; // 同じモデルで、もう一度
          }
          break; // 次のモデルへ（時間切れも、ここから次のモデルへ）
        }
      }
    }
    throw lastFailure ?? const GeminiFailure(GeminiFailureKind.unknown);
  }

  Stream<String> _streamFrom(
    String modelName,
    String apiKey,
    String message,
    List<AiTurn> history,
  ) async* {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(_persona),
    );
    final chat = model.startChat(history: _toContents(history));

    // 次の文字が _idleTimeout 以内に届かなければ、TimeoutException になる
    final responses = chat
        .sendMessageStream(Content.text(message))
        .timeout(_idleTimeout);

    var text = '';
    await for (final chunk in responses) {
      final piece = chunk.text;
      if (piece == null || piece.isEmpty) continue;
      text += piece;
      yield text;
    }
    // 何も返ってこなかった（安全フィルターなど）
    if (text.isEmpty) throw const GeminiFailure(GeminiFailureKind.blocked);
  }

  /// 履歴を Gemini が受け付ける形に整える。
  /// 先頭は user、user と model が交互に並ぶこと、最後は model で終わること。
  List<Content> _toContents(List<AiTurn> turns) {
    final result = <Content>[];
    for (final turn in turns) {
      final role = turn.isUser ? 'user' : 'model';
      // 同じ役割が続いたら、新しい方だけ残す
      if (result.isNotEmpty && result.last.role == role) result.removeLast();
      if (result.isEmpty && role == 'model') continue; // 先頭は必ず user
      result.add(Content(role, [TextPart(turn.text)]));
    }
    // 最後が user のままだと、次の質問と user が連続してしまうので外す
    if (result.isNotEmpty && result.last.role == 'user') result.removeLast();
    return result;
  }

  /// 例外の文面から、失敗の種類を見分ける
  static GeminiFailure _classify(Object error) {
    if (error is GeminiFailure) return error;
    if (error is TimeoutException) {
      return const GeminiFailure(GeminiFailureKind.timeout);
    }
    if (error is InvalidApiKey) {
      return const GeminiFailure(GeminiFailureKind.invalidKey);
    }

    final text = error.toString().toLowerCase();
    bool has(List<String> words) => words.any(text.contains);

    if (has(['high demand', 'overloaded', 'unavailable', '503'])) {
      return const GeminiFailure(GeminiFailureKind.overloaded);
    }
    if (has(['quota', 'resource_exhausted', '429', 'rate limit'])) {
      return const GeminiFailure(GeminiFailureKind.quota);
    }
    if (has(['api key not valid', 'api_key_invalid', 'permission_denied'])) {
      return const GeminiFailure(GeminiFailureKind.invalidKey);
    }
    if (has([
      'socketexception',
      'failed host lookup',
      'clientexception',
      'timed out',
    ])) {
      return const GeminiFailure(GeminiFailureKind.network);
    }
    if (has(['blocked', 'safety'])) {
      return const GeminiFailure(GeminiFailureKind.blocked);
    }
    return const GeminiFailure(GeminiFailureKind.unknown);
  }
}
