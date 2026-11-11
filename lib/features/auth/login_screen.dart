import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/labeled_segmented.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// 成功すると AuthGate が状態変化を検知して自動で画面が切り替わる
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'メールアドレスとパスワードを入力してください');
      return Future.value();
    }
    final auth = FirebaseAuth.instance;
    return _run(
      () => _mode == _AuthMode.signUp
          ? auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            )
          : auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<void> _signInAnonymously() =>
      _run(() => FirebaseAuth.instance.signInAnonymously());

  String _messageFor(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'メールアドレスの形式が正しくありません',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'メールアドレスまたはパスワードが違います',
    'email-already-in-use' => 'このメールアドレスはすでに使われています',
    'weak-password' => 'パスワードは6文字以上で入力してください',
    'network-request-failed' => '通信できませんでした。接続を確認してください',
    _ => '処理できませんでした（${e.code}）',
  };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.moon_stars_fill,
                    size: 52,
                    color: p.accent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ヨルノヒカリ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '夜の育児中の人と、静かにつながるアプリ',
                    style: TextStyle(fontSize: 13, color: p.textSecondary),
                  ),
                  const SizedBox(height: 36),
                  LabeledSegmented<_AuthMode>(
                    value: _mode,
                    options: const {
                      _AuthMode.signIn: 'ログイン',
                      _AuthMode.signUp: '新規登録',
                    },
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 20),
                  _Field(
                    controller: _email,
                    placeholder: 'メールアドレス',
                    icon: CupertinoIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    hints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _password,
                    placeholder: 'パスワード',
                    icon: CupertinoIcons.lock,
                    obscure: true,
                    hints: const [AutofillHints.password],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CupertinoActivityIndicator()
                          : Text(
                              _mode == _AuthMode.signUp ? '登録する' : 'ログイン',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: _loading ? null : _signInAnonymously,
                    child: const Text(
                      '登録せずに試す',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 背景色だけで入力欄を示す（枠線なし）
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.hints,
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? hints;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: hints,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Icon(icon, size: 18, color: p.textSecondary),
      ),
      style: TextStyle(color: p.textPrimary, fontSize: 16),
      placeholderStyle: TextStyle(color: p.textSecondary, fontSize: 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
