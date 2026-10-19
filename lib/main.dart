import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'sound_data.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase の初期化処理を追加
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  runApp(const YorunohikariApp());
}

// 認証状態の監視ウィジェット
class AuthWrapper extends StatelessWidget {
  final DarkThemeOption currentOption;
  final Function(DarkThemeOption) onSelectTheme;
  final bool isDark;

  const AuthWrapper({
    super.key,
    required this.currentOption,
    required this.onSelectTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainNavigationScreen(
            currentOption: currentOption,
            onSelectTheme: onSelectTheme,
            isDark: isDark,
          );
        }
        return const LoginScreen();
      },
    );
  }
}

// 全47都道府県の代表座標データ（フォールバック用）
final Map<String, LatLng> prefectureCoordinates = {
  '北海道': const LatLng(43.0642, 141.3469),
  '青森県': const LatLng(40.8244, 140.7400),
  '岩手県': const LatLng(39.7036, 141.1527),
  '宮城県': const LatLng(38.2682, 140.8694),
  '秋田県': const LatLng(39.7186, 140.1024),
  '山形県': const LatLng(38.2404, 140.3633),
  '福島県': const LatLng(37.7500, 140.4678),
  '茨城県': const LatLng(36.3418, 140.4468),
  '栃木県': const LatLng(36.5657, 139.8836),
  '群馬県': const LatLng(36.3907, 139.0604),
  '埼玉県': const LatLng(35.8570, 139.6489),
  '千葉県': const LatLng(35.6047, 140.1233),
  '東京都': const LatLng(35.6895, 139.6917),
  '神奈川県': const LatLng(35.4478, 139.6425),
  '新潟県': const LatLng(37.9022, 139.0236),
  '富山県': const LatLng(36.6953, 137.2113),
  '石川県': const LatLng(36.5947, 136.6256),
  '福井県': const LatLng(36.0652, 136.2216),
  '山梨県': const LatLng(35.6642, 138.5684),
  '長野県': const LatLng(36.6513, 138.1810),
  '岐阜県': const LatLng(35.3912, 136.7223),
  '静岡県': const LatLng(34.9769, 138.3831),
  '愛知県': const LatLng(35.1814, 136.9064),
  '三重県': const LatLng(34.7303, 136.5086),
  '滋賀県': const LatLng(35.0045, 135.8686),
  '京都府': const LatLng(35.0210, 135.7556),
  '大阪府': const LatLng(34.6937, 135.5023),
  '兵庫県': const LatLng(34.6901, 135.1955),
  '奈良県': const LatLng(34.6853, 135.8328),
  '和歌山県': const LatLng(34.2260, 135.1675),
  '鳥取県': const LatLng(35.5011, 134.2351),
  '島根県': const LatLng(35.4723, 133.0505),
  '岡山県': const LatLng(34.6617, 133.9350),
  '広島県': const LatLng(34.3853, 132.4553),
  '山口県': const LatLng(34.1858, 131.4714),
  '徳島県': const LatLng(34.0658, 134.5593),
  '香川県': const LatLng(34.3401, 134.0434),
  '愛媛県': const LatLng(33.8416, 132.7657),
  '高知県': const LatLng(33.5597, 133.5311),
  '福岡県': const LatLng(33.5904, 130.4017),
  '佐賀県': const LatLng(33.2635, 130.3009),
  '長崎県': const LatLng(32.7503, 129.8777),
  '熊本県': const LatLng(32.7898, 130.7417),
  '大分県': const LatLng(33.2382, 131.6126),
  '宮崎県': const LatLng(31.9111, 131.4239),
  '鹿児島県': const LatLng(31.5602, 130.5581),
  '沖縄県': const LatLng(26.2124, 127.6809),
};

enum DarkThemeOption { midnight, oledBlack, light }

class YorunohikariApp extends StatefulWidget {
  const YorunohikariApp({super.key});

  @override
  State createState() => _YorunohikariAppState();
}

class _YorunohikariAppState extends State {
  DarkThemeOption _themeOption = DarkThemeOption.midnight;
  bool _isDark = true;

  void _updateTheme(DarkThemeOption option) {
    setState(() {
      _themeOption = option;
      _isDark = (option != DarkThemeOption.light);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color cardColor;
    bool isDark = true;

    switch (_themeOption) {
      case DarkThemeOption.midnight:
        backgroundColor = const Color(0xFF0F172A);
        cardColor = const Color(0xFF1E293B);
        isDark = true;
        break;
      case DarkThemeOption.oledBlack:
        backgroundColor = Colors.black;
        cardColor = const Color(0xFF121212);
        isDark = true;
        break;
      case DarkThemeOption.light:
        backgroundColor = const Color(0xFFF8FAFC);
        cardColor = Colors.white;
        isDark = false;
        break;
    }

    return MaterialApp(
      title: 'ヨルノヒカリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: cardColor,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
        ),
        colorScheme: ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFFFDE047),
          onPrimary: Colors.black,
          secondary: const Color(0xFFFB923C),
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: cardColor,
          onSurface: isDark ? Colors.white : Colors.black87,
        ),
      ),
      home: AuthWrapper(
        currentOption: _themeOption,
        onSelectTheme: _updateTheme,
        isDark: _isDark,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final DarkThemeOption currentOption;
  final Function(DarkThemeOption) onSelectTheme;
  final bool isDark;

  const MainNavigationScreen({
    super.key,
    required this.currentOption,
    required this.onSelectTheme,
    required this.isDark,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  DateTime _selectedDate = DateTime.now();
  String _activeChartType = 'nursing'; // 'nursing' (授乳) または 'sleep' (睡眠)
  int _currentIndex = 0;
  int _nursingCount = 0;
  int _sleepingCount = 0;
  final ValueNotifier<String> _myStatus = ValueNotifier<String>('none');
  final TextEditingController _chatController = TextEditingController();
  bool _isAiTabSelected = false; // false: リアルママ広場, true: AIママ相談室

  List<Map<String, dynamic>> _records = [];

  String _selectedRoom = 'nursing';

  Timer? _timer;
  final ValueNotifier<int> _secondsElapsed = ValueNotifier<int>(0);
  // --- BGM再生用の設定 ---
  final AudioPlayer _audioPlayer = AudioPlayer(); // 2. プレイヤーインスタンス
  String _currentSoundId = 'tainai';
  bool _isBgmPlaying = false; // BGMの再生状態
  late Future<List<SoundItem>> _soundsFuture = loadSounds();

  // 最新の授乳記録を取得（Dart側で最新ソート）
  Stream<QuerySnapshot> get _latestNursingStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('records')
        .where('type', isEqualTo: '授乳')
        .snapshots();
  }

  // 最新の睡眠記録を取得（Dart側で最新ソート）
  Stream<QuerySnapshot> get _latestSleepStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('records')
        .where('type', isEqualTo: '寝かしつけ')
        .snapshots();
  }

  late final Stream<QuerySnapshot> _realMamaStream = FirebaseFirestore.instance
      .collection('chats')
      .where('roomId', isEqualTo: _selectedRoom)
      .orderBy('timestamp', descending: true)
      .snapshots();

  late final Stream<QuerySnapshot> _aiMamaStream = FirebaseFirestore.instance
      .collection('ai_chats')
      .orderBy('timestamp', descending: true)
      .snapshots();

  Timer? _sleepTimer; // スリープタイマー用のタイマー
  int _selectedTimerMinutes = 30; // 初期選択値（分）
  final ValueNotifier<int> _remainingSeconds = ValueNotifier<int>(0);
  bool _isTimerActive = false; // タイマーが稼働中か

  // --- スリープタイマー終了・音楽停止関数 ---
  void _stopSleepTimerAndAudio() {
    _sleepTimer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _isBgmPlaying = false;
      _isTimerActive = false;
      _remainingSeconds.value = 0;
    });
  }

  // --- スリープタイマー開始関数 ---
  void _startSleepTimer(int minutes) {
    _sleepTimer?.cancel();

    if (minutes == 0) {
      setState(() {
        _selectedTimerMinutes = 0;
        _isTimerActive = false;
      });
      _remainingSeconds.value = 0;
      return;
    }

    setState(() {
      _selectedTimerMinutes = minutes;
      _isTimerActive = true;
    });
    _remainingSeconds.value = minutes * 60;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isBgmPlaying) {
        if (_remainingSeconds.value > 0) {
          // setStateを使わずに値だけ減らす
          _remainingSeconds.value--;
        } else {
          _stopSleepTimerAndAudio();
        }
      }
    });
  }

  // --- 残り時間からカウントダウンを再開する関数 ---
  void _resumeSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isBgmPlaying) {
        if (_remainingSeconds.value > 0) {
          // setStateを使わずに値だけ減らす
          _remainingSeconds.value--;
        } else {
          _stopSleepTimerAndAudio();
        }
      }
    });
  }

  // --- 残り時間を "24:15" 形式にフォーマットする関数 ---
  String _formatRemainingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  // --- タイマー選択ダイアログを表示する関数 ---
  void _showTimerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = [5, 15, 30, 60, 120, 240, 0];
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "スリープタイマー設定",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((mins) {
                final label = mins == 0 ? "オフ(ループ再生)" : "$mins 分";
                return ListTile(
                  title: Text(
                    label,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _selectedTimerMinutes == mins && _isTimerActive
                      ? const Icon(Icons.check, color: Color(0xFFFDE047))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _startSleepTimer(mins);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- 計測データをFirestoreに保存する関数 ---
  Future<void> _saveRecordToFirestore(int durationSeconds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("ログインしていないため保存できません");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('records')
          .add({
            'duration': durationSeconds, // 計測時間（秒）
            'timestamp': FieldValue.serverTimestamp(), // 日時
          });

      print("Firestoreへの保存完了！");

      // 保存完了後、画面上の履歴一覧を最新状態に更新
      await _fetchRecordsFromFirestore();
    } catch (e) {
      print("Firestoreへの保存エラー: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _subscribeToLights();
    _fetchRecordsFromFirestore();
    _initBgm(); // 3. BGMの初期設定を呼び出し
  }

  /// BGMの初期化（ループ設定＆音量調整）
  Future<void> _initBgm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.2); // ママが落ち着く控えめな音量 (0.0〜1.0)
  }

  Future<void> _toggleSound(SoundItem item) async {
    print("=== タップされた音源情報 ===");
    print("ID: ${item.id}");
    print("Title: ${item.title}");
    print("AssetPath: ${item.assetPath}");
    if (_isBgmPlaying && _currentSoundId == item.id) {
      // 【一時停止】
      await _audioPlayer.pause();
      _sleepTimer?.cancel(); // タイマーのカウントだけ停止（残り秒数は保持）
      setState(() {
        _isBgmPlaying = false;
      });
    } else {
      // 【再生開始・再開】
      await _audioPlayer.stop();
      try {
        await _audioPlayer.play(AssetSource(item.assetPath));
        setState(() {
          _currentSoundId = item.id;
          _isBgmPlaying = true;
        });

        // スリープタイマーが有効（残りの時間がある）で停止していた場合は再開
        if (_isTimerActive && _remainingSeconds.value > 0) {
          _resumeSleepTimer();
        }
      } catch (e) {
        print("BGM再生エラー: $e");
      }
    }
  }

  // 3. データの取得・同期関数
  Future<void> _fetchRecordsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('records')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _records = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint('Firestoreからのデータ取得エラー: $e');
    }
  }

  /// --- Gemini APIから回答をストリーミング取得する関数 ---
  Future<void> _fetchAiResponseStream({
    required String userPrompt,
    required Function(String chunk) onChunk,
    int retryCount = 0,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:streamGenerateContent?alt=sse',
    );

    String accumulatedText = '';

    try {
      final request = http.Request('POST', url)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        })
        ..body = jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'あなたは優しく温かいベテランママ「AIママ」です。夜中の育児で疲れているママに寄り添い、短く優しく回答してください。\nユーザー: $userPrompt',
                },
              ],
            },
          ],
        });

      final client = http.Client();
      final response = await client.send(request);

      debugPrint('【Gemini Stream API Response Code】: ${response.statusCode}');

      if (response.statusCode == 200) {
        await response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
              final trimmedLine = line.trim();
              if (trimmedLine.startsWith('data: ')) {
                final jsonString = trimmedLine.substring(6).trim();
                if (jsonString.isEmpty || jsonString == '[DONE]') return;

                try {
                  final data = jsonDecode(jsonString);

                  // candidates 内のパーツをすべて探索して漏れなく抽出
                  final candidates = data['candidates'] as List?;
                  if (candidates != null && candidates.isNotEmpty) {
                    final parts = candidates[0]?['content']?['parts'] as List?;
                    if (parts != null) {
                      for (var part in parts) {
                        final text = part['text'] as String?;
                        if (text != null && text.isNotEmpty) {
                          accumulatedText += text;
                        }
                      }
                      // テキストが抽出できたら画面更新コールバックを呼ぶ
                      onChunk(accumulatedText);
                    }
                  }
                } catch (e) {
                  debugPrint('Chunk parse error: $e');
                }
              }
            })
            .asFuture();
      } else if (response.statusCode == 503 && retryCount < 2) {
        debugPrint('503エラーが発生したためリトライします... (${retryCount + 1}回目)');
        await Future.delayed(const Duration(seconds: 1));
        await _fetchAiResponseStream(
          userPrompt: userPrompt,
          onChunk: onChunk,
          retryCount: retryCount + 1,
        );
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint('【API Error Body】: $errorBody');
        if (accumulatedText.isEmpty) {
          onChunk('少し電波が悪いみたい。時間を置いてもう一度試してね。');
        }
      }
    } catch (e) {
      debugPrint('AI Stream Exception: $e');
      onChunk('通信エラーが発生しました。');
    }
  }

  // --- チャット送信関数 ---
  Future<void> _sendMessage(String text) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('【送信失敗】ログインしていません');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('送信失敗: ログインしていません')));
      }
      return;
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // 入力欄をクリア
    _chatController.clear();

    try {
      if (_isAiTabSelected) {
        // ==========================================
        // 🤖 AIママ相談室の場合
        // ==========================================

        // 1. ユーザーのメッセージを Firestore に保存
        await FirebaseFirestore.instance.collection('ai_chats').add({
          'text': trimmedText,
          'isUser': true,
          'senderId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. AIの空返信用ドキュメントを作成し、Doc IDを取得
        final aiDocRef = await FirebaseFirestore.instance
            .collection('ai_chats')
            .add({
              'text': '...',
              'isUser': false,
              'senderId': 'ai_mama',
              'timestamp': FieldValue.serverTimestamp(),
            });

        // 3. ストリーミングで届いた文字をリアルタイムで Firestore に更新
        String fullAiReply = '';
        await _fetchAiResponseStream(
          userPrompt: trimmedText,
          onChunk: (fullText) {
            fullAiReply = fullText;
            // ドキュメントを逐次更新（画面の StreamBuilder が感知して自動描画される）
            aiDocRef.update({'text': fullAiReply});
          },
        );
      } else {
        // ==========================================
        // 👥 リアルママ広場の場合
        // ==========================================
        await FirebaseFirestore.instance.collection('chats').add({
          'text': trimmedText,
          'isUser': true,
          'senderId': user.uid,
          'roomId': _selectedRoom,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('【送信成功！】');
    } catch (e) {
      debugPrint('【送信エラー】: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('送信エラー: $e')));
      }
    }
  }

  final List<Map<String, dynamic>> _otherUsersLights = [];

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed.value = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed.value++;
      });
    });
  }

  void _stopTimerAndOpenModal() {
    _timer?.cancel();

    if (_myStatus.value == 'nursing') {
      _showFinishedModal();
    } else {
      _saveRecord(type: '寝かしつけ', detail: '完了');
    }
  }

  void _showFinishedModal() {
    String feedType = '母乳';
    String side = '両方';
    String milkAmount = '80';
    String memoTag = '完飲';

    final milkController = TextEditingController(text: milkAmount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      '深夜の授乳、本当にお疲れ様でした',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 授乳タイプ選択
                  const Text(
                    '種類',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ['母乳', 'ミルク', '混合'].map((type) {
                      final isSelected = feedType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(child: Text(type)),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFDE047),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setModalState(() => feedType = type),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // 母乳の場合の左右選択
                  if (feedType == '母乳' || feedType == '混合') ...[
                    const Text(
                      'おっぱい',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['両方', '左のみ', '右のみ'].map((s) {
                        final isSelected = side == s;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Center(child: Text(s)),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFB923C),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) => setModalState(() => side = s),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ミルクの場合の量選択 (チップ選択式)
                  if (feedType == 'ミルク' || feedType == '混合') ...[
                    const Text(
                      'ミルク量 (ml)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [40, 60, 80, 100, 120, 140, 160].map((amount) {
                        final isSelected =
                            milkController.text == amount.toString();
                        return ChoiceChip(
                          label: Text('${amount}ml'),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFB923C),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              milkController.text = amount.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 様子・メモ（タグ）
                  const Text(
                    '様子・メモ',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['寝落ち', '完飲', 'よく飲んだ', '吐き戻しなし'].map((tag) {
                      final isSelected = memoTag == tag;
                      return ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: Colors.indigoAccent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        onSelected: (_) => setModalState(() => memoTag = tag),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDE047),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        String detailStr = feedType;
                        if (feedType == '母乳') detailStr += ' ($side)';
                        if (feedType == 'ミルク')
                          detailStr += ' (${milkController.text}ml)';
                        if (feedType == '混合')
                          detailStr += ' ($side / ${milkController.text}ml)';
                        detailStr += ' • $memoTag';

                        Navigator.pop(context);
                        _saveRecord(type: '授乳', detail: detailStr);
                      },
                      child: const Text(
                        '保存 (お疲れ様でした)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isSaving = false; // 二重保存を防ぐフラグ

  Future _saveRecord({required String type, required String detail}) async {
    if (_isSaving) return; // 保存中なら何もしない
    _isSaving = true;

    if (_secondsElapsed.value > 0) {
      final now = DateTime.now();
      final timeString =
          "${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final durationStr = _formatDuration(_secondsElapsed.value);

      // 保存するデータのマップ構造
      final newRecord = {
        'type': type,
        'duration': durationStr,
        'date': timeString,
        'detail': detail,
        'timestamp': FieldValue.serverTimestamp(), // 並び替え用のタイムスタンプ
      };

      // 1. ローカルの画面表示（_recordsリスト）に即時反映
      setState(() {
        _records.insert(0, newRecord);
      });

      // 2. Cloud Firestore データベースへ非同期保存
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('records')
              .add(newRecord);

          await _fetchRecordsFromFirestore();
        } catch (e) {
          debugPrint('Firestore保存エラー: $e');
        }
      }
    }

    _setStatus('none');
    _secondsElapsed.value = 0;
    _isSaving = false;
  }

  // ★【追加】指定したインデックスの記録を削除する処理
  void _deleteRecord(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('記録の削除'),
          content: const Text('この授乳記録を削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _records.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text(
                '削除',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$remainingSeconds";
  }

  void _subscribeToLights() {}

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    for (var user in _otherUsersLights) {
      markers.add(
        Marker(
          point: user['position'],
          width: 8,
          height: 8,
          child: _buildGlowDot(
            user['status'] == 'nursing'
                ? const Color.fromARGB(255, 236, 231, 104)
                : const Color.fromARGB(255, 126, 87, 194),

            isMe: false,
          ),
        ),
      );
    }

    if (_myStatus.value != 'none') {
      markers.add(
        Marker(
          point: _myLocation,
          width: 8,
          height: 8,
          child: _buildGlowDot(
            _myStatus.value == 'nursing'
                ? const Color.fromARGB(255, 236, 231, 104)
                : const Color(0xFF6366F1),
            isMe: true,
          ),
        ),
      );
    }

    return markers;
  }

  String _selectedPref = '東京都';
  String _city = '';
  LatLng _myLocation = const LatLng(35.6895, 139.6917);

  LatLng _getBlurredLocation(LatLng baseLocation) {
    final random = Random();
    double latOffset = (random.nextDouble() - 0.5) * 0.05;
    double lonOffset = (random.nextDouble() - 0.5) * 0.05;
    return LatLng(
      baseLocation.latitude + latOffset,
      baseLocation.longitude + lonOffset,
    );
  }

  void _setStatus(String status) async {
    if (_myStatus.value == status) {
      _timer?.cancel();
      _secondsElapsed.value = 0; // setStateの外でリセット
      setState(() {
        if (status == 'nursing') _nursingCount--;
        if (status == 'sleeping') _sleepingCount--;
        _myStatus.value = 'none';
      });
    } else {
      setState(() {
        if (_myStatus.value == 'nursing') _nursingCount--;
        if (_myStatus.value == 'sleeping') _sleepingCount--;

        _myStatus.value = status;
        if (status == 'nursing') _nursingCount++;
        if (status == 'sleeping') _sleepingCount++;
      });

      _startTimer(); // setStateの外でタイマー開始
    }

    // ★ Firebase Firestore にステータス情報を保存（他端末へ共有）
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'status': _myStatus.value,
        'latitude': _myLocation.latitude, // 位置情報を追加
        'longitude': _myLocation.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('背景の「黒さ」を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<DarkThemeOption>(
                title: const Text('ミッドナイト（目に優しいネイビー）'),
                value: DarkThemeOption.midnight,
                groupValue: widget.currentOption,
                onChanged: (val) {
                  if (val != null) widget.onSelectTheme(val);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<DarkThemeOption>(
                title: const Text('漆黒（完全な黒 / 省エネ）'),
                value: DarkThemeOption.oledBlack,
                groupValue: widget.currentOption,
                onChanged: (val) {
                  if (val != null) widget.onSelectTheme(val);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<DarkThemeOption>(
                title: const Text('ライトモード（昼間用）'),
                value: DarkThemeOption.light,
                groupValue: widget.currentOption,
                onChanged: (val) {
                  if (val != null) widget.onSelectTheme(val);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileSettings() {
    String tempPref = _selectedPref;
    TextEditingController cityController = TextEditingController(text: _city);
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '地域・プロフィール設定',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '都道府県（必須）',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: tempPref,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: prefectureCoordinates.keys.map((String pref) {
                      return DropdownMenuItem<String>(
                        value: pref,
                        child: Text(pref),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) tempPref = val;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '市・区・町（任意）',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '例：渋谷区、大阪市など',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isSearching
                          ? null
                          : () async {
                              setModalState(() => isSearching = true);
                              // 都道府県と市町村（テキスト結合）を結合する。$に都道県と市町村が入る。
                              String searchQuery =
                                  '$tempPref ${cityController.text}'.trim();
                              LatLng resolvedPos;
                              // locationFromAddress()で住所から座標を取得する。失敗した場合は都道府県の代表座標を使用する。

                              try {
                                List<Location> locations =
                                    await locationFromAddress(searchQuery);

                                if (locations.isNotEmpty) {
                                  resolvedPos = LatLng(
                                    locations.first.latitude,
                                    locations.first.longitude,
                                  );
                                } else {
                                  resolvedPos =
                                      prefectureCoordinates[tempPref] ??
                                      const LatLng(35.6895, 139.6917);
                                }
                              } catch (e) {
                                resolvedPos =
                                    prefectureCoordinates[tempPref] ??
                                    const LatLng(35.6895, 139.6917);
                              }

                              setState(() {
                                _selectedPref = tempPref;
                                _city = cityController.text;
                                _myLocation = _getBlurredLocation(resolvedPos);
                              });

                              // Firestore へプロフィールの地域情報を保存
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .set({
                                      'prefecture': tempPref,
                                      'city': cityController.text,
                                      'latitude': resolvedPos.latitude,
                                      'longitude': resolvedPos.longitude,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '位置を取得して保存',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlowDot(Color color, {bool isMe = false}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: isMe ? 6 : 8,
            spreadRadius: isMe ? 10 : 2,
          ),
        ],
        border: isMe ? Border.all(color: Colors.white, width: 2) : null,
      ),
    );
  }

  // =============================================================================
  // 記録タブメイン（ピヨログ風ヘッダー ＋ 上部サマリー ＋ 下部タイムライン/グラフ）
  // =============================================================================
  Widget _buildRecordList() {
    return SafeArea(
      child: Column(
        children: [
          // ---------------------------------------------------------------------
          // 0. ピヨログ風 日付選択ヘッダー
          // ---------------------------------------------------------------------
          InkWell(
            onTap: () => _showCalendarDatePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: const Color.fromARGB(255, 236, 231, 104),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),

          // 1. 上部（1/3）: 直近サマリーカード（前回の授乳・睡眠）
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // 🍼 前回の授乳カード
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _latestNursingStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildRecentSummaryCard(
                            title: '前回の授乳',
                            icon: Icons.baby_changing_station,
                            accentColor: const Color.fromARGB(
                              255,
                              236,
                              231,
                              104,
                            ),
                            primaryValue: '記録なし',
                            detailValue: '本日合計: 0 ml',
                            timeAgo: '-',
                          );
                        }

                        final docs = List.from(snapshot.data!.docs);
                        docs.sort((a, b) {
                          final aTime =
                              (a.data() as Map<String, dynamic>)['timestamp']
                                  as Timestamp?;
                          final bTime =
                              (b.data() as Map<String, dynamic>)['timestamp']
                                  as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return aTime.compareTo(bTime);
                        });

                        final data = docs.last.data() as Map<String, dynamic>;
                        final DateTime? end = (data['timestamp'] as Timestamp?)
                            ?.toDate();
                        final String durationStr = data['duration'] ?? '00:00';
                        final int amount = data['amount'] ?? 0;

                        // 開始時間〜終了時間の文字列を作成（例: 10/15 10:15~10:20）
                        String timeRangeStr = '--:--';
                        if (end != null) {
                          final parts = durationStr.split(':');
                          int addedMinutes = 0;
                          int addedSeconds = 0;

                          if (parts.length == 2) {
                            addedMinutes = (int.tryParse(parts[0])) ?? 0;
                            addedSeconds = (int.tryParse(parts[1])) ?? 0;
                          }

                          final start = end.subtract(
                            Duration(
                              minutes: addedMinutes,
                              seconds: addedSeconds,
                            ),
                          );

                          final startFormat =
                              '${start.month}/${start.day} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                          final endFormat =
                              '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

                          timeRangeStr = (addedMinutes > 0 || addedSeconds > 0)
                              ? '$startFormat~$endFormat'
                              : startFormat;
                        }

                        // 本日のミルク合計（ml）を計算
                        int totalAmount = 0;
                        for (var doc in docs) {
                          final d = doc.data() as Map<String, dynamic>;
                          final t = (d['timestamp'] as Timestamp?)?.toDate();
                          if (t != null &&
                              t.year == _selectedDate.year &&
                              t.month == _selectedDate.month &&
                              t.day == _selectedDate.day) {
                            totalAmount += (d['amount'] as num?)?.toInt() ?? 0;
                          }
                        }

                        final String timeAgoStr = end != null
                            ? _calculateTimeAgo(end)
                            : '-';

                        return _buildRecentSummaryCard(
                          title: '前回の授乳',
                          icon: Icons.baby_changing_station,
                          accentColor: const Color.fromARGB(255, 236, 231, 104),
                          primaryValue:
                              timeRangeStr, // ★ "10/15 10:15~10:20" 形式で表示
                          detailValue: '本日合計: $totalAmount ml',
                          timeAgo: timeAgoStr,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 🌙 前回の睡眠カード
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _latestSleepStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildRecentSummaryCard(
                            title: '前回の睡眠',
                            icon: Icons.nightlight_round,
                            accentColor: const Color(0xFF7E57C2),
                            primaryValue: '記録なし',
                            detailValue: '本日合計: 0分',
                            timeAgo: '-',
                          );
                        }

                        final docs = List.from(snapshot.data!.docs);
                        docs.sort((a, b) {
                          final aTime =
                              (a.data() as Map<String, dynamic>)['timestamp']
                                  as Timestamp?;
                          final bTime =
                              (b.data() as Map<String, dynamic>)['timestamp']
                                  as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return aTime.compareTo(bTime);
                        });

                        final data = docs.last.data() as Map<String, dynamic>;
                        final DateTime? end = (data['timestamp'] as Timestamp?)
                            ?.toDate();
                        final String durationStr = data['duration'] ?? '00:00';

                        // 開始時間〜終了時間の文字列を作成（例: 10/15 10:15~10:20）
                        String timeRangeStr = '--:--';
                        if (end != null) {
                          final parts = durationStr.split(':');
                          int addedMinutes = 0;
                          int addedSeconds = 0;

                          if (parts.length == 2) {
                            addedMinutes = (int.tryParse(parts[0])) ?? 0;
                            addedSeconds = (int.tryParse(parts[1])) ?? 0;
                          }
                          final start = end.subtract(
                            Duration(
                              minutes: addedMinutes,
                              seconds: addedSeconds,
                            ),
                          );

                          final startFormat =
                              '${start.month}/${start.day} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                          final endFormat =
                              '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

                          timeRangeStr = (addedMinutes > 0 || addedSeconds > 0)
                              ? '$startFormat~$endFormat'
                              : startFormat;
                        }

                        // ★ ここを追加：本日の合計睡眠時間（分）を計算
                        int totalMinutes = 0;
                        for (var doc in docs) {
                          final d = doc.data() as Map<String, dynamic>;
                          final t = (d['timestamp'] as Timestamp?)?.toDate();
                          if (t != null &&
                              t.year == _selectedDate.year &&
                              t.month == _selectedDate.month &&
                              t.day == _selectedDate.day) {
                            final dur = d['duration'] ?? '00:00';
                            final parts = dur.split(':');
                            if (parts.length == 2) {
                              totalMinutes += (int.tryParse(parts[0]) ?? 0);
                            }
                          }
                        }

                        final int hours = totalMinutes ~/ 60;
                        final int mins = totalMinutes % 60;
                        final String totalSleepStr = hours > 0
                            ? '$hours時間$mins分'
                            : '$mins分';

                        final String timeAgoStr = end != null
                            ? _calculateTimeAgo(end)
                            : '-';

                        return _buildRecentSummaryCard(
                          title: '前回の睡眠',
                          icon: Icons.nightlight_round,
                          accentColor: const Color(0xFF7E57C2),
                          primaryValue:
                              timeRangeStr, // ★ "10/15 10:15~10:20" 形式で表示
                          detailValue:
                              '本日合計: $totalSleepStr', // '睡眠時間: $durationStr' から変更
                          timeAgo: timeAgoStr,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. 下部（2/3）: タブを廃止し、授乳・睡眠グラフのみをダイレクト表示
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: _buildChartTabContent(), // グラフ描画関数をそのまま呼び出し
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 日付タップ時にピヨログ風ポップアップカレンダーを出す関数
  // -----------------------------------------------------------------------------
  void _showCalendarDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _selectedDate,
                    currentDay: _selectedDate,
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                      });
                      Navigator.pop(context); // 日付を選んだら閉じる
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -----------------------------------------------------------------------------
  // 授乳・睡眠 切り替え型グラフ表示エリア
  // -----------------------------------------------------------------------------
  Widget _buildChartTabContent() {
    final isNursing = _activeChartType == 'nursing';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 切替トグルボタン（授乳 / 睡眠）
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('🍼 授乳量(ml)'),
                selected: isNursing,
                selectedColor: const Color.fromARGB(255, 236, 231, 104),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _activeChartType = 'nursing');
                  }
                },
              ),
              const SizedBox(width: 15),
              ChoiceChip(
                label: const Text('🌙 睡眠時間(分)'),
                selected: !isNursing,
                selectedColor: const Color.fromARGB(255, 126, 87, 194),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _activeChartType = 'sleep');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 2. 補足テキスト
          Text(
            isNursing ? '📊 時間帯別の授乳量 (合計)' : '📊 時間帯別の正味睡眠時間 (寝かしつけ除外)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // 3. グラフ本体
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: isNursing ? 160 : 120, // 授乳はMax 160ml、睡眠はMax 120分
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        );
                        switch (value.toInt()) {
                          case 0:
                            return const Text('00:00', style: style);
                          case 1:
                            return const Text('06:00', style: style);
                          case 2:
                            return const Text('12:00', style: style);
                          case 3:
                            return const Text('18:00', style: style);
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}${isNursing ? "ml" : "分"}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                // 切り替え状態に応じたサンプルデータ
                barGroups: isNursing
                    ? [
                        _makeSingleBarGroup(
                          0,
                          80,
                          const Color.fromARGB(255, 236, 231, 104),
                        ),
                        _makeSingleBarGroup(
                          1,
                          120,
                          const Color.fromARGB(255, 236, 231, 104),
                        ),
                        _makeSingleBarGroup(
                          2,
                          60,
                          const Color.fromARGB(255, 236, 231, 104),
                        ),
                        _makeSingleBarGroup(
                          3,
                          100,
                          const Color.fromARGB(255, 236, 231, 104),
                        ),
                      ]
                    : [
                        _makeSingleBarGroup(
                          0,
                          45,
                          const Color.fromARGB(255, 126, 87, 194),
                        ),
                        _makeSingleBarGroup(
                          1,
                          90,
                          const Color.fromARGB(255, 126, 87, 194),
                        ),
                        _makeSingleBarGroup(
                          2,
                          30,
                          const Color.fromARGB(255, 126, 87, 194),
                        ),
                        _makeSingleBarGroup(
                          3,
                          60,
                          const Color.fromARGB(255, 126, 87, 194),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 単一バー用のヘルパー関数
  BarChartGroupData _makeSingleBarGroup(int x, double yValue, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: yValue,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  // 凡例用ウィジェット
  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentSummaryCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required String primaryValue,
    required String detailValue,
    required String timeAgo,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ヘッダー（アイコン ＋ タイトル ＋ 右上に「〇分前」バッジ）
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // ★ 右上に「〇分前」バッジを配置
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // メイン数値/時刻（例: 10/15 11:03~11:05）
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              primaryValue,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 詳細情報（例: 本日合計: 80 ml）を単独で配置
          Text(
            detailValue,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 3. チャット画面（リアルママ部屋 ＆ AIママ相談）
  // ----------------------------------------------------
  Widget _buildChatTab() {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          // タブ切り替えを検知して _isAiTabSelected フラグを自動更新
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              setState(() {
                _isAiTabSelected = tabController.index == 1;
              });
            }
          });

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 0, // ネストしたAppBarの高さを消す
              bottom: TabBar(
                // 選択中のタブに応じて下線の色を切り替え
                indicatorColor: _isAiTabSelected
                    ? const Color(0xFF7E57C2) // AIママ相談室の時の色（パープル）
                    : const Color.fromARGB(
                        255,
                        236,
                        231,
                        104,
                      ), // リアルママ広場の時の色（オレンジ）
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: !_isAiTabSelected
                              ? const Color.fromARGB(
                                  255,
                                  236,
                                  231,
                                  104,
                                ) // リアルママ選択時のアイコン色
                              : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'リアルママ広場',
                          style: TextStyle(
                            color: !_isAiTabSelected
                                ? const Color.fromARGB(
                                    255,
                                    236,
                                    231,
                                    104,
                                  ) // リアルママ選択時の文字色
                                : Colors.white60,
                            fontWeight: !_isAiTabSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy_outlined,
                          color: _isAiTabSelected
                              ? const Color(0xFF7E57C2) // AIママ選択時のアイコン色
                              : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AIママ相談室',
                          style: TextStyle(
                            color: _isAiTabSelected
                                ? const Color(0xFF7E57C2) // AIママ選択時の文字色
                                : Colors.white60,
                            fontWeight: _isAiTabSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [_buildRealMamaChat(), _buildAiMamaChat()],
            ),
          );
        },
      ),
    );
  }

  // 3-A. リアルママ広場（ルーム選択＋メッセージ）
  Widget _buildRealMamaChat() {
    return Column(
      children: [
        // ルーム切替チップ
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              const Text(
                "部屋: ",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text("🍼 授乳中ルーム"),
                        selected: _selectedRoom == 'nursing',
                        selectedColor: const Color.fromARGB(255, 236, 231, 104),
                        labelStyle: TextStyle(
                          color: _selectedRoom == 'nursing'
                              ? Colors.black
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedRoom = 'nursing');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("🌙 寝かしつけルーム"),
                        selected: _selectedRoom == 'sleeping',
                        selectedColor: const Color.fromARGB(255, 126, 87, 194),
                        labelStyle: TextStyle(
                          color: _selectedRoom == 'sleeping'
                              ? Colors.black
                              : Colors.white70,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedRoom = 'sleeping');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("☕ 雑談ルーム"),
                        selected: _selectedRoom == 'chatting',
                        selectedColor: const Color.fromARGB(255, 88, 151, 70),
                        labelStyle: TextStyle(
                          color: _selectedRoom == 'chatting'
                              ? Colors.black
                              : Colors.white70,
                          fontWeight: _selectedRoom == 'chatting'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedRoom = 'chatting');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // チャットメッセージ一覧（リアルタイム取得）
        Expanded(
          child: StreamBuilder(
            stream: _realMamaStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'エラー: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'まだメッセージがありません。\n今夜の呟きを投稿してみましょう！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map;
                  final text = data['text'] ?? '';
                  final senderId = data['senderId'] ?? '';
                  final myUid = FirebaseAuth.instance.currentUser?.uid;
                  final isMe = senderId == myUid;

                  final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                  final DateTime dateTime =
                      timestamp?.toDate() ?? DateTime.now();
                  final timeStr =
                      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

                  final name = isMe
                      ? "自分"
                      : "ママ (${senderId.length >= 4 ? senderId.substring(0, 4) : '匿名'})";

                  return _buildChatBubble(name, text, timeStr, isMe);
                },
              );
            },
          ),
        ),

        _buildMessageInput("ママたちに呟く..."),
      ],
    );
  }

  // 3-B. AIママ相談室（1on1親身サポート・リアルタイム取得版）
  Widget _buildAiMamaChat() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: _aiMamaStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'エラー: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildChatBubble(
                      "AIママ",
                      "こんばんは。夜遅くまで本当によく頑張っていますね。どんな小さな不安でも吐き出してくださいね。どうされましたか？",
                      "",
                      false,
                      isAi: true,
                    ),
                  ],
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map;
                  final text = data['text'] ?? '';
                  final isUser = data['isUser'] ?? false;

                  final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                  final DateTime dateTime =
                      timestamp?.toDate() ?? DateTime.now();
                  final timeStr =
                      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

                  return _buildChatBubble(
                    isUser ? "自分" : "AIママ",
                    text,
                    timeStr,
                    isUser,
                    isAi: !isUser,
                  );
                },
              );
            },
          ),
        ),

        _buildMessageInput("AIママに悩みを相談する..."),
      ],
    );
  }

  // チャット吹き出し用共通パーツ
  Widget _buildChatBubble(
    String name,
    String text,
    String time,
    bool isMe, {
    bool isAi = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAi)
                const Icon(Icons.smart_toy, size: 14, color: Color(0xFF818CF8)),
              if (isAi) const SizedBox(width: 4),
              Text(
                name,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF6366F1)
                  : (isAi ? const Color(0xFF312E81) : const Color(0xFF1E293B)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // メッセージ入力バーパーツ（_sendMessage に統一）
  Widget _buildMessageInput(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _sendMessage(value),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFFFDE047),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send, size: 18, color: Colors.black),
              onPressed: () =>
                  _sendMessage(_chatController.text), // ← 統合版の送信関数を実行！
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 4. ヒーリングBGM画面（安らぎ音源 ＆ タイマー停止）
  // ----------------------------------------------------
  Widget _buildHealingTab() {
    return FutureBuilder<List<SoundItem>>(
      future: _soundsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '音源データの読み込みエラー: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final soundList = snapshot.data ?? [];

        // 現在選択されている曲の情報を取得（見つからなければ最初の曲）
        final currentSound = soundList.firstWhere(
          (s) => s.id == _currentSoundId,
          orElse: () => soundList.isNotEmpty
              ? soundList.first
              : SoundItem(
                  id: 'tainai',
                  title: '胎内音',
                  category: '胎内音',
                  assetPath: 'bgm/tainaion.mp3',
                ),
        );

        return SingleChildScrollView(
          key: const PageStorageKey<String>('bgm_tab_scroll'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 再生中のミニプレイヤー表示
              // 右上にタイマーボタンを配置した音源ライブラリヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ヒーリングBGM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _showTimerBottomSheet();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isTimerActive
                            ? const Color(0xFFFDE047).withOpacity(0.2)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isTimerActive
                              ? const Color(0xFFFDE047)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: _isTimerActive
                                ? const Color(0xFFFDE047)
                                : Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          ValueListenableBuilder<int>(
                            valueListenable: _remainingSeconds,
                            builder: (context, remainingSecs, child) {
                              return Text(
                                _isTimerActive
                                    ? _formatRemainingTime(remainingSecs)
                                    : "オフ",
                                style: TextStyle(
                                  color: _isTimerActive
                                      ? const Color(0xFFFDE047)
                                      : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 24),

              // JSONから読み込んだリストを動的にタイル表示
              ...soundList.map((sound) {
                final isPlaying = _isBgmPlaying && _currentSoundId == sound.id;
                return _buildSoundCategoryTile(sound, isPlaying);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // BGMカテゴリータイルパーツ（SoundItemを受け取ってタップで切り替え）
  Widget _buildSoundCategoryTile(SoundItem item, bool isPlaying) {
    // カテゴリに応じたアイコンの選択
    IconData icon = Icons.music_note;
    if (item.category == 'オルゴール1') icon = Icons.star;
    if (item.category == 'オルゴール2') icon = Icons.medical_services;
    if (item.category == 'オルゴール3') icon = Icons.spa;
    if (item.category == '自然') icon = Icons.hotel;
    if (item.category == '心臓音') icon = Icons.favorite;
    if (item.category == '鳥のさえずり') icon = Icons.flutter_dash;

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: isPlaying
              ? const Color(0xFFFDE047)
              : const Color(0xFF0F172A),
          child: Icon(icon, color: isPlaying ? Colors.black : Colors.white60),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          item.category,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Icon(
          isPlaying ? Icons.volume_up : Icons.play_arrow_rounded,
          color: isPlaying ? const Color(0xFFFDE047) : Colors.white38,
        ),
        onTap: () => _toggleSound(item), // タップした曲を再生・停止
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardColor = Theme.of(context).colorScheme.surface;

    final Widget mapScreen = Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              int nursingCount = 0;
              int sleepingCount = 0;

              if (snapshot.hasData && snapshot.data != null) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? 'none';
                  if (status == 'nursing') nursingCount++;
                  if (status == 'sleeping') sleepingCount++;
                }
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildCountCard(
                      title: '授乳対応中',
                      count: nursingCount,
                      color: const Color.fromARGB(255, 236, 231, 104),
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCountCard(
                      title: '寝かしつけ中',
                      count: sleepingCount,
                      color: const Color.fromARGB(255, 126, 87, 194),
                      cardColor: cardColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _myStatus.value == 'nursing'
                      ? const Color.fromARGB(255, 241, 243, 160)
                      : (_myStatus.value == 'sleeping'
                            ? const Color.fromARGB(255, 126, 87, 194)
                            : Colors.transparent),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      List<Marker> allMarkers = [];

                      if (snapshot.hasData && snapshot.data != null) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] as String? ?? 'none';
                          final lat = (data['latitude'] as num?)?.toDouble();
                          final lng = (data['longitude'] as num?)?.toDouble();

                          // 位置情報があり、アクティブなステータス（nursing または sleeping）の場合に光（マーカー）を作成
                          if (lat != null && lng != null && status != 'none') {
                            // ※既存のマーカー作成ロジックに合わせて色やアイコンを設定
                            allMarkers.add(
                              Marker(
                                point: LatLng(lat, lng),
                                width: 8,
                                height: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: status == 'nursing'
                                        ? const Color.fromARGB(
                                            255,
                                            241,
                                            243,
                                            160,
                                          )
                                        : const Color.fromARGB(
                                            255,
                                            126,
                                            87,
                                            194,
                                          ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (status == 'nursing'
                                                    ? const Color.fromARGB(
                                                        255,
                                                        241,
                                                        243,
                                                        160,
                                                      )
                                                    : const Color.fromARGB(
                                                        255,
                                                        126,
                                                        87,
                                                        194,
                                                      ))
                                                .withOpacity(0.8),
                                        blurRadius: 8,
                                        spreadRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      }

                      return JapanLightMap(
                        markers: allMarkers,
                        isDark: isDark,
                        targetLocation: _myLocation,
                        hasActiveStatus: _myStatus.value != 'none',
                      );
                    },
                  ),
                  if (_myStatus.value != 'none')
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _myStatus.value == 'nursing'
                                      ? Icons.child_care
                                      : Icons.bedtime,
                                  color: _myStatus.value == 'nursing'
                                      ? const Color(0xFFFDE047)
                                      : const Color.fromARGB(255, 126, 87, 194),
                                ),
                                const SizedBox(width: 5),
                                ValueListenableBuilder<int>(
                                  valueListenable: _secondsElapsed,
                                  builder: (context, seconds, child) {
                                    return Text(
                                      '${_myStatus.value == 'nursing' ? '授乳' : '寝かしつけ'}計測中: ${_formatDuration(seconds)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: _stopTimerAndOpenModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                '終了',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _setStatus('nursing'),
                  icon: const Icon(Icons.child_care),
                  label: const Text('授乳対応中'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _myStatus.value == 'nursing'
                        ? const Color.fromARGB(255, 241, 243, 160)
                        : (isDark
                              ? const Color.fromARGB(233, 193, 194, 196)
                              : Colors.grey[300]),
                    foregroundColor: _myStatus.value == 'nursing'
                        ? Colors.black
                        : (isDark
                              ? const Color.fromARGB(255, 17, 15, 15)
                              : Colors.black87),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _setStatus('sleeping'),
                  icon: const Icon(Icons.bedtime),
                  label: const Text('寝かしつけ中'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _myStatus.value == 'sleeping'
                        ? const Color.fromARGB(255, 126, 87, 194)
                        : (isDark
                              ? const Color.fromARGB(233, 193, 194, 196)
                              : Colors.grey[300]),
                    foregroundColor: _myStatus.value == 'sleeping'
                        ? Colors.black
                        : (isDark
                              ? const Color.fromARGB(255, 29, 24, 24)
                              : Colors.black87),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final List screens = [
      mapScreen,
      _buildRecordList(),
      _buildChatTab(),
      _buildHealingTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'ヨルノヒカリ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // ★ハンバーガーメニュー（Drawer）の追加
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- 1. プロフィールヘッダー ---
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1F2937)),
              accountName: Text(
                '〇〇ママ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text('お子様: 双子ちゃん (0歳6ヶ月)'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 36),
              ),
            ),

            // --- 2. 設定・管理項目 ---
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('プロフィール編集'),
              subtitle: const Text('お名前、双子・三子設定、月齢など'),
              onTap: () {
                Navigator.pop(context); // メニューを閉じる
                _showProfileSettings(); // プロフィール設定を開く
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('地域設定'),
              onTap: () {
                Navigator.pop(context);
                _showProfileSettings(); // 地域設定ダイアログまたは画面を開く
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_medium),
              title: const Text('画面の明るさ'),
              onTap: () {
                Navigator.pop(context);
                _showThemeDialog(); // テーマ選択を開く
              },
            ),
            ListTile(
              leading: const Icon(Icons.copyright, color: Colors.white70),
              title: const Text(
                'クレジット表記',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // ドロワーを閉じる
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E2C),
                    title: const Text(
                      '使用音源・素材クレジット',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '本アプリで使用しているBGM・効果音は、以下のサイト様よりお借りしています。',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 16),
                          const Text(
                            '【音源・効果音】\n'
                            '・OtoLogic 様\n'
                            '・VSQ plus+ 様\n'
                            '・効果音ラボ 様\n'
                            '・FREE BGM 様\n\n'
                            '【地図データ】\n'
                            '・© OpenStreetMap contributors\n'
                            '・Tiles © Esri — Source: Esri, DeLorme, NAVTEQ\n\n'
                            '【AI機能】\n'
                            '・Powered by Gemini API',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ), // Text
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          '閉じる',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(), // 区切り線
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'ログアウト',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ], // ← children の終わり
        ), // ← ListView の終わり
      ), // ← Drawer の終わり

      body: IndexedStack(
        index: _currentIndex,
        children: [
          mapScreen,
          _buildRecordList(),
          _buildChatTab(),
          _buildHealingTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'マップ'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '記録'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'チャット',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'BGM'),
        ],
      ),
    );
  }

  Widget _buildCountCard({
    required String title,
    required int count,
    required Color color,
    required Color cardColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count 人',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// 地図ウィジェット
class JapanLightMap extends StatefulWidget {
  final List<Marker> markers;
  final bool isDark;
  final LatLng targetLocation;
  final bool hasActiveStatus;

  const JapanLightMap({
    super.key,
    required this.markers,
    required this.isDark,
    required this.targetLocation,
    required this.hasActiveStatus,
  });

  @override
  State<JapanLightMap> createState() => _JapanLightMapState();
}

class _JapanLightMapState extends State<JapanLightMap> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant JapanLightMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasActiveStatus &&
        (widget.targetLocation != oldWidget.targetLocation ||
            !oldWidget.hasActiveStatus)) {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(widget.targetLocation, currentZoom);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 0.1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final String tileUrl = widget.isDark
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            key: const ValueKey('japan_light_map'), // ★この1行を追加！
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(36.2048, 138.2529),
              initialZoom: 5.2,
              minZoom: 3.5,
              maxZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.example.yorunohikari',
              ),
              MarkerLayer(markers: widget.markers),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 110,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: _zoomIn,
                  backgroundColor: widget.isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: widget.isDark
                      ? Colors.white
                      : Colors.black87,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: _zoomOut,
                  backgroundColor: widget.isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  foregroundColor: widget.isDark
                      ? Colors.white
                      : Colors.black87,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 仮のログイン画面（後で実際のコードに置き換え）
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false; // ログインと新規登録の切り替えフラグ
  bool _isLoading = false;

  // メールアドレスでのログイン / 新規登録処理
  Future _submitEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('メールアドレスとパスワードを入力してください')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // 新規アカウント作成
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // 既存アカウントでログイン
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // 成功すると AuthWrapper が自動検知して MainNavigationScreen へ遷移します
    } on FirebaseAuthException catch (e) {
      String message = 'エラーが発生しました';
      if (e.code == 'user-not-found') message = 'ユーザーが見つかりません';
      if (e.code == 'wrong-password') message = 'パスワードが違います';
      if (e.code == 'email-already-in-use') message = 'すでに使用されているメールアドレスです';
      if (e.code == 'weak-password') message = 'パスワードは6文字以上で入力してください';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 匿名ログイン（お試し利用）処理
  Future _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('お試しログインに失敗しました')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // ミッドナイトブルー
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アプリロゴ・アイコン表示エリア
                const Icon(
                  Icons.nightlight_round,
                  size: 64,
                  color: Color(0xFFFDE047),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ヨルノヒカリ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '夜間育児の孤独を和らげる、ママたちのためのコミュニティアプリ',
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 36),

                // メールアドレス入力
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.white60,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // パスワード入力
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white60,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ログイン / 新規登録 ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitEmailAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE047),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            _isSignUp ? '新規アカウント登録' : 'ログイン',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // ログイン ⇔ 新規登録 の切り替え
                TextButton(
                  onPressed: () {
                    setState(() => _isSignUp = !_isSignUp);
                  },
                  child: Text(
                    _isSignUp
                        ? 'すでにアカウントをお持ちの方はこちら（ログイン）'
                        : 'アカウントをお持ちでない方はこちら（新規登録）',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'または',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 16),

                // Google連携ボタン（UI枠組み）
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // ※Googleサインイン連携用のパッケージ設定後に処理を記述
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('GoogleサインインはFirebase側の設定後に有効化されます'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 28,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Googleアカウントでログイン',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 登録なしで試す（匿名ログイン）
                TextButton(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  child: const Text(
                    '登録せずにすぐ試す（お試し利用）',
                    style: TextStyle(color: Color(0xFF818CF8), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 経過時間計算ヘルパー
String _calculateTimeAgo(DateTime targetTime) {
  final diff = DateTime.now().difference(targetTime);
  if (diff.inMinutes < 1) {
    return 'たった今';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}分前';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}時間前';
  } else {
    return '${diff.inDays}日前';
  }
}
