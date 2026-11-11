import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_palette.dart';
import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._(SharedPreferences prefs)
    : _prefs = prefs,
      _mode = prefs.getString(_kMode) == 'light'
          ? ThemeMode.light
          : ThemeMode.dark,
      _warmth = prefs.getDouble(_kWarmth) ?? 0.5,
      _depth = prefs.getDouble(_kDepth) ?? 0.5 {
    _light = _buildLight();
    _dark = _buildDark();
  }

  static Future<ThemeController> load() async =>
      ThemeController._(await SharedPreferences.getInstance());

  static const _kMode = 'theme_mode';
  static const _kWarmth = 'theme_light_warmth';
  static const _kDepth = 'theme_dark_depth';

  final SharedPreferences _prefs;
  ThemeMode _mode;
  double _warmth; // ライト: 0 = やわらかい白 〜 1 = クリーム
  double _depth; // ダーク: 0 = 青み 〜 1 = 漆黒

  // 動かした側のテーマだけ作り直す（毎フレーム2つ作らない）
  late ThemeData _light;
  late ThemeData _dark;

  /// スライダーを操作している間は true。切替アニメーションを止めて、指に即座に追従させる
  bool _tuning = false;

  ThemeMode get mode => _mode;
  double get warmth => _warmth;
  double get depth => _depth;
  bool get isTuning => _tuning;
  ThemeData get lightTheme => _light;
  ThemeData get darkTheme => _dark;

  ThemeData _buildLight() =>
      AppTheme.build(AppPalette.light(warmth: _warmth), Brightness.light);
  ThemeData _buildDark() =>
      AppTheme.build(AppPalette.dark(depth: _depth), Brightness.dark);

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _prefs.setString(_kMode, mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  void setWarmth(double v) {
    _warmth = v;
    _light = _buildLight();
    notifyListeners();
  }

  void setDepth(double v) {
    _depth = v;
    _dark = _buildDark();
    notifyListeners();
  }

  /// スライダーに触れた瞬間: アニメーションを0にする
  void beginTuning() {
    _tuning = true;
    notifyListeners();
  }

  /// スライダーを離した瞬間: アニメーションを戻し、値を保存する
  Future<void> endTuning() async {
    _tuning = false;
    notifyListeners();
    await _prefs.setDouble(_kWarmth, _warmth);
    await _prefs.setDouble(_kDepth, _depth);
  }
}

/// 子孫から `ThemeScope.of(context)` で取得。変更時は依存するWidgetが再構築される。
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}
