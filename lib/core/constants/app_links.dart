import 'package:flutter/foundation.dart';

abstract final class AppLinks {
  /// お問い合わせの宛先メールアドレス（要変更）
  static const contactEmail = 'support@example.com';

  /// 利用規約のページURL（要変更）
  static const termsUrl = 'https://example.com/terms';

  /// App Store の数字のID（公開後に入れる。例: '1234567890'）
  static const appStoreId = '';

  /// Android のパッケージ名
  static const playStorePackage = 'com.example.yorunohikari';

  /// ストアのページ。公開前（IDが空）は null
  static Uri? get storeUri {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Uri.parse(
        'https://play.google.com/store/apps/details?id=$playStorePackage',
      );
    }
    return appStoreId.isEmpty
        ? null
        : Uri.parse('https://apps.apple.com/app/id$appStoreId');
  }

  /// レビュー画面を直接開くURL
  static Uri? get reviewUri {
    final store = storeUri;
    if (store == null) return null;
    return defaultTargetPlatform == TargetPlatform.android
        ? store
        : Uri.parse('${store.toString()}?action=write-review');
  }

  static String get shareText {
    final store = storeUri;
    return '夜の育児を、静かにつなぐアプリ「ヨルノヒカリ」${store == null ? '' : '\n$store'}';
  }
}
