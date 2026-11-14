import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../core/utils/time_format.dart';
import '../records/record_models.dart';
import '../records/record_store.dart';

// ============================================================
//  1. 設定と、その保存
// ============================================================

/// 授乳のお知らせの設定
class NursingReminderSettings {
  const NursingReminderSettings({
    this.enabled = false,
    this.interval = const Duration(hours: 3),
  });

  /// 選べる最小の間隔
  static const minInterval = Duration(minutes: 5);

  final bool enabled;

  /// 前回の授乳から、何時間何分後にお知らせするか
  final Duration interval;
}

/// 設定を端末に保存・読み込みする
class ReminderSettingsStore {
  static const _kEnabled = 'nursing_reminder_enabled';
  static const _kMinutes = 'nursing_reminder_minutes';

  Future<NursingReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_kMinutes);
    return NursingReminderSettings(
      enabled: prefs.getBool(_kEnabled) ?? false,
      interval: minutes == null
          ? const Duration(hours: 3)
          : Duration(minutes: minutes),
    );
  }

  Future<void> save(NursingReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, settings.enabled);
    await prefs.setInt(_kMinutes, settings.interval.inMinutes);
  }
}

// ============================================================
//  2. 通知の送り出し（プラグインを包むだけの層）
// ============================================================

/// ローカル通知の、初期化・許可・予約・取り消しだけを担当する。
/// 「いつ予約するか」は、ここでは決めない（NursingReminderController の仕事）。
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const _nursingReminderId = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// アプリの起動時に1度だけ呼ぶ。許可のダイアログは、ここでは出さない
  Future<void> init() async {
    if (_isInitialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _isInitialized = true;
  }

  /// 通知の許可を求める（お知らせをオンにしたときに呼ぶ）。許可されたら true
  Future<bool> requestPermission() async {
    await init();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null)
      return await android.requestNotificationsPermission() ?? false;
    return true;
  }

  /// [at] に授乳のお知らせを予約する。古い予約は、先に取り消す（予約は常に1つだけ）
  Future<void> scheduleNursingReminder(
    DateTime at, {
    required String body,
  }) async {
    await init();
    await _plugin.cancelAll();
    await _plugin.zonedSchedule(
      id: _nursingReminderId,
      title: '授乳のタイミング',
      body: body,
      // 時刻そのものを渡すので、地域の設定に左右されない
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        android: AndroidNotificationDetails(
          'nursing_reminder',
          '授乳のお知らせ',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelNursingReminder() async {
    await init();
    await _plugin.cancelAll();
  }
}

// ============================================================
//  3. 予約のルール
// ============================================================

/// 授乳のお知らせを管理する。
///  - ログインしている間、授乳の記録を見張る
///  - 最新の授乳の時刻 + 設定の間隔 に、通知を1つだけ予約する
///  - 新しい授乳が記録される・設定が変わるたびに、予約し直す
/// 保存側（地図の「終了」・押し忘れの追加・ミルク）は、何も変えなくてよい。
class NursingReminderController extends ChangeNotifier {
  NursingReminderController({
    NotificationService? notifications,
    ReminderSettingsStore? store,
    DateTime Function()? clock,
  }) : _notifications = notifications ?? NotificationService.instance,
       _store = store ?? ReminderSettingsStore(),
       _clock = clock ?? DateTime.now;

  final NotificationService _notifications;
  final ReminderSettingsStore _store;
  final DateTime Function() _clock;

  NursingReminderSettings _settings = const NursingReminderSettings();
  DateTime? _latestNursingAt; // 記録されている、いちばん新しい授乳の時刻
  DateTime? _scheduledAt; // いま予約している通知の時刻

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<CareRecord>>? _recordsSubscription;

  NursingReminderSettings get settings => _settings;

  /// 予約済みの通知の時刻（なければ null）
  DateTime? get nextReminderAt => _scheduledAt;

  /// アプリの起動時に1度だけ呼ぶ
  Future<void> start() async {
    _settings = await _store.load();
    notifyListeners();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );
  }

  /// ログイン中だけ記録を見張り、ログアウトしたら予約を消す
  void _onAuthChanged(User? user) {
    _recordsSubscription?.cancel();
    _recordsSubscription = null;
    _latestNursingAt = null;

    if (user == null) {
      _cancel();
      return;
    }
    _recordsSubscription = RecordRepository().watchRecent().listen((records) {
      // 新しい順に並んでいるので、最初に見つかる授乳が最新
      _latestNursingAt = records
          .where((r) => r.type == RecordType.nursing)
          .firstOrNull
          ?.endedAt;
      _syncSchedule();
    }, onError: (Object e) => debugPrint('授乳のお知らせ: 記録の取得エラー: $e'));
  }

  /// 設定を変える。オンにするときは、通知の許可を求める。
  /// 許可されなかったときは false を返し、設定は変えない。
  Future<bool> update({
    required bool enabled,
    required Duration interval,
  }) async {
    if (enabled && !_settings.enabled) {
      final granted = await _notifications.requestPermission();
      if (!granted) return false;
    }
    _settings = NursingReminderSettings(
      enabled: enabled,
      interval: interval < NursingReminderSettings.minInterval
          ? NursingReminderSettings.minInterval
          : interval,
    );
    await _store.save(_settings);
    notifyListeners();
    await _syncSchedule();
    return true;
  }

  /// 「設定」と「最新の授乳」から、あるべき予約を決めて、合わせる
  Future<void> _syncSchedule() async {
    final base = _latestNursingAt;
    if (!_settings.enabled || base == null) return _cancel();

    final at = base.add(_settings.interval);
    // すでに過ぎている（または、ほぼ今）なら、予約しない
    if (!at.isAfter(_clock().add(const Duration(seconds: 30))))
      return _cancel();
    // すでに同じ時刻で予約済みなら、何もしない
    if (_scheduledAt == at) return;

    try {
      await _notifications.scheduleNursingReminder(
        at,
        body: '前回の授乳から${formatSpan(_settings.interval)}です。',
      );
      _scheduledAt = at;
      notifyListeners();
    } catch (e) {
      debugPrint('授乳のお知らせの予約エラー: $e');
    }
  }

  Future<void> _cancel() async {
    if (_scheduledAt == null) return;
    _scheduledAt = null;
    notifyListeners();
    try {
      await _notifications.cancelNursingReminder();
    } catch (e) {
      debugPrint('授乳のお知らせの取り消しエラー: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _recordsSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
//  4. どの画面からも使えるようにする
// ============================================================

/// 子孫から `NursingReminderScope.of(context)` で取得する（ThemeScope と同じ形）。
/// 記録ページなどは Navigator の上に積まれるので、アプリの一番上に置く。
class NursingReminderScope
    extends InheritedNotifier<NursingReminderController> {
  const NursingReminderScope({
    super.key,
    required NursingReminderController controller,
    required super.child,
  }) : super(notifier: controller);

  static NursingReminderController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NursingReminderScope>()!
      .notifier!;
}
