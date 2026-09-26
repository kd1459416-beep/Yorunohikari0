import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const YorunohikariApp());
}

// main.dart 等で最初に表示するWidget
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required DarkThemeOption currentOption,
    required void Function(DarkThemeOption option) onSelectTheme,
    required bool isDark,
  });
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. 通信確認中（スプラッシュ表示）
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. ログイン済み ➔ メインのマップ画面へ
        if (snapshot.hasData) {
          return const MapScreen();
        }

        // 3. 未ログイン ➔ ログイン/新規登録画面へ
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
  State<YorunohikariApp> createState() => _YorunohikariAppState();
}

class _YorunohikariAppState extends State<YorunohikariApp> {
  DarkThemeOption _themeOption = DarkThemeOption.midnight;
  void _setThemeOption(DarkThemeOption option) {
    setState(() {
      _themeOption = option;
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
        onSelectTheme: _setThemeOption,
        isDark: isDark,
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
  int _currentIndex = 0;
  int _nursingCount = 0;
  int _sleepingCount = 0;
  String _myStatus = 'none';

  Timer? _timer;
  int _secondsElapsed = 0;

  final List<Map<String, dynamic>> _records = [];
  final List<Map<String, dynamic>> _otherUsersLights = [];

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _stopTimerAndOpenModal() {
    _timer?.cancel();

    if (_myStatus == 'nursing') {
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

  void _saveRecord({required String type, required String detail}) {
    if (_secondsElapsed > 0) {
      final now = DateTime.now();
      final timeString =
          "${now.month}/${now.day} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      setState(() {
        _records.insert(0, {
          'type': type,
          'duration': _formatDuration(_secondsElapsed),
          'date': timeString,
          'detail': detail,
        });
      });
    }

    _setStatus('none');
    _secondsElapsed = 0;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _subscribeToLights();
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
                : const Color.fromARGB(255, 91, 231, 166),
            isMe: false,
          ),
        ),
      );
    }

    if (_myStatus != 'none') {
      markers.add(
        Marker(
          point: _myLocation,
          width: 8,
          height: 8,
          child: _buildGlowDot(
            _myStatus == 'nursing'
                ? const Color.fromARGB(255, 236, 231, 104)
                : const Color.fromARGB(255, 91, 231, 166),
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

  void _setStatus(String status) {
    setState(() {
      if (_myStatus == status) {
        _timer?.cancel();
        _secondsElapsed = 0;
        if (status == 'nursing') _nursingCount--;
        if (status == 'sleeping') _sleepingCount--;
        _myStatus = 'none';
      } else {
        if (_myStatus == 'nursing') _nursingCount--;
        if (_myStatus == 'sleeping') _sleepingCount--;

        _myStatus = status;
        if (status == 'nursing') _nursingCount++;
        if (status == 'sleeping') _sleepingCount++;

        _startTimer();
      }
    });
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

  // ★【更新】右端にゴミ箱アイコンを追加したリスト
  Widget _buildRecordList() {
    if (_records.isEmpty) {
      return const Center(
        child: Text(
          'まだ記録がありません\nマップ画面でボタンを押すと計測できます',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final item = _records[index];
        final isNursing = item['type'] == '授乳';
        return Card(
          color: Theme.of(context).colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isNursing
                  ? const Color(0xFFFDE047)
                  : const Color.fromARGB(255, 131, 247, 183),
              child: Icon(
                isNursing ? Icons.child_care : Icons.bedtime,
                color: Colors.black,
              ),
            ),
            title: Text(
              '${item['type']} - ${item['duration']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['detail'] != null)
                  Text(
                    item['detail'],
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                Text(
                  item['date'],
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            // ★右端にゴミ箱アイコンを追加
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white38),
              onPressed: () => _deleteRecord(index),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // 3. チャット画面（リアルママ部屋 ＆ AIママ相談）
  // ----------------------------------------------------
  Widget _buildChatTab() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0, // ネストしたAppBarの高さを消す
          bottom: const TabBar(
            indicatorColor: Color(0xFFFDE047),
            labelColor: Color(0xFFFDE047),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: "リアルママ広場"),
              Tab(icon: Icon(Icons.smart_toy_outlined), text: "AIママ相談室"),
            ],
          ),
        ),
        body: TabBarView(children: [_buildRealMamaChat(), _buildAiMamaChat()]),
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
                        selected: true,
                        selectedColor: const Color(0xFFFDE047),
                        labelStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("🌙 寝かしつけ失敗…"),
                        selected: false,
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("☕ ひとりごと・雑談"),
                        selected: false,
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // チャットメッセージ一覧
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChatBubble(
                "ママA (東京都)",
                "3ヶ月の子供が全然寝てくれない…抱っこ疲れたよ〜😭",
                "2:15",
                false,
              ),
              _buildChatBubble(
                "ママB (大阪府)",
                "分かります！うちも今おっぱい終わったのに目が冴えてます💦 お互い無理せずいきましょうね…！",
                "2:18",
                false,
              ),
              _buildChatBubble("自分", "同じく格闘中です！トントンして乗り切ります！", "2:20", true),
            ],
          ),
        ),
        // 入力フォーム
        _buildMessageInput("ママたちに呟く..."),
      ],
    );
  }

  // 3-B. AIママ相談室（1on1親身サポート）
  Widget _buildAiMamaChat() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChatBubble(
                "AIママ",
                "こんばんは。夜遅くまで本当によく頑張っていますね。どんな小さな不安でも吐き出してくださいね。どうされましたか？",
                "2:00",
                false,
                isAi: true,
              ),
              _buildChatBubble(
                "自分",
                "1時間おきに起きちゃって、もう精神的に限界かもしれません…",
                "2:02",
                true,
              ),
              _buildChatBubble(
                "AIママ",
                "それは本当につらいですね…眠れない夜が続くと心も体も削られてしまいます。赤ちゃんが寝たら、家事は後回しにして一緒に目を閉じて休んでくださいね。あなたは十分に素晴らしいお母さんですよ。",
                "2:03",
                false,
                isAi: true,
              ),
            ],
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

  // メッセージ入力バーパーツ
  Widget _buildMessageInput(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Expanded(
            child: TextField(
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
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFFFDE047),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send, size: 18, color: Colors.black),
              onPressed: () {},
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 再生中のミニプレイヤー表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "優しいしとしと雨",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "赤ちゃんが落ち着く環境音",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.pause_circle_filled,
                        size: 44,
                        color: Color(0xFFFDE047),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.white60,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "スリープタイマー: 30分後に停止",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      "残り 24:15",
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "音源ライブラリ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // サウンドカテゴリーカード
          _buildSoundCategoryTile(
            "🌧️ 環境音（赤ちゃんが泣き止む）",
            "雨の音、波の音、ホワイトノイズ",
            Icons.cloud,
            true,
          ),
          _buildSoundCategoryTile("🤱 胎内音", "心臓の音、羊水の音", Icons.favorite, false),
          _buildSoundCategoryTile(
            "🎵 オルゴール",
            "きらきら星、ゆりかごの歌",
            Icons.music_note,
            false,
          ),
          _buildSoundCategoryTile(
            "🌲 ヒーリングBGM",
            "静かな夜の森、星空のピアノ",
            Icons.nightlight_round,
            false,
          ),
        ],
      ),
    );
  }

  // BGMカテゴリータイルパーツ
  Widget _buildSoundCategoryTile(
    String title,
    String subtitle,
    IconData icon,
    bool isPlaying,
  ) {
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
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Icon(
          isPlaying ? Icons.volume_up : Icons.play_arrow_rounded,
          color: isPlaying ? const Color(0xFFFDE047) : Colors.white38,
        ),
        onTap: () {},
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
          Row(
            children: [
              Expanded(
                child: _buildCountCard(
                  title: '授乳対応中',
                  count: _nursingCount,
                  color: const Color.fromARGB(255, 236, 231, 104),
                  cardColor: cardColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCountCard(
                  title: '寝かしつけ中',
                  count: _sleepingCount,
                  color: const Color.fromARGB(255, 91, 231, 166),
                  cardColor: cardColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _myStatus == 'nursing'
                      ? const Color.fromARGB(255, 241, 243, 160)
                      : (_myStatus == 'sleeping'
                            ? const Color.fromARGB(255, 91, 231, 166)
                            : Colors.transparent),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  JapanLightMap(
                    markers: _buildMarkers(),
                    isDark: isDark,
                    targetLocation: _myLocation,
                    hasActiveStatus: _myStatus != 'none',
                  ),
                  if (_myStatus != 'none')
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
                                  _myStatus == 'nursing'
                                      ? Icons.child_care
                                      : Icons.bedtime,
                                  color: _myStatus == 'nursing'
                                      ? const Color(0xFFFDE047)
                                      : const Color.fromARGB(
                                          255,
                                          124,
                                          241,
                                          202,
                                        ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${_myStatus == 'nursing' ? '授乳' : '寝かしつけ'}計測中: ${_formatDuration(_secondsElapsed)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: _stopTimerAndOpenModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 35,
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
                    backgroundColor: _myStatus == 'nursing'
                        ? const Color.fromARGB(255, 241, 243, 160)
                        : (isDark
                              ? const Color.fromARGB(233, 193, 194, 196)
                              : Colors.grey[300]),
                    foregroundColor: _myStatus == 'nursing'
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
                    backgroundColor: _myStatus == 'sleeping'
                        ? const Color.fromARGB(255, 91, 231, 166)
                        : (isDark
                              ? const Color.fromARGB(233, 193, 194, 196)
                              : Colors.grey[300]),
                    foregroundColor: _myStatus == 'sleeping'
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
      _buildChatTab(), // 仮のTextから実際のWidgetクラスへ置き換え
      _buildHealingTab(), // 仮のTextから実際のWidgetクラスへ置き換え
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ヨルノヒカリ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '地域設定',
            onPressed: _showProfileSettings,
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: '背景色を変更',
            onPressed: _showThemeDialog,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardColor,
        selectedItemColor: isDark
            ? const Color(0xFFFDE047)
            : const Color(0xFF0F172A),
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: '灯火',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: '記録',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'チャット',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_outlined),
            label: 'BGM',
          ),
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

// 仮のマップ画面（後で実際のコードに置き換え）
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('マップ画面')));
  }
}

// 仮のログイン画面（後で実際のコードに置き換え）
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ログイン画面')));
  }
}
