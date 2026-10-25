# Yorunohikari（夜のひかり）

夜中の育児や不安な気持ちに寄り添う、温かい AI パートナー（AIママ）アプリです。

---

## 概要 (Overview)
「夜中に一人で育児に悩み、不安になるお母さんたちの心によりそう」ことを目指して開発した Flutter アプリです。  
AIママとの対話を通じて、少しでも気持ちが軽くなるようなリアルタイムストリーミングチャット機能を提供しています。

---

## 主な機能 (Features)
- 🤖 **AIママ チャット機能**
  - Gemini API (`gemini-3.8-flash`) を活用したストリーミング対話
  - 優しい口調で寄り添うプロンプト設計
- 🎵 **BGM / ヒーリング機能**
  - 心を落ち着かせる音声再生機能
- 📅 **記録・履歴管理 (Firebase)**
  - 過去のやりとりや記録を Firestore で安全に管理

---

## 技術スタック (Tech Stack)

| カテゴリ | 技術・ライブラリ |
| :--- | :--- |
| **フロントエンド** | Flutter (Dart) |
| **AI / LLM** | Google Generative AI SDK (`gemini-3.8-flash`) |
| **バックエンド / DB** | Firebase (Authentication, Firestore) |
| **環境変数管理** | `flutter_dotenv`, `--dart-define` |
| **デプロイ / インフラ** | Vercel |

---

## 開発上の工夫・こだわった点 (Engineering Highlights)

1. **UXを高めるストリーミング応答の実装**
   - 生成 AI の応答を待たせることなく、テキストが流れるように表示されるストリーミング処理（`generateContentStream`）を実装しました。

2. **環境変数と API キーの安全な管理**
   - API キーをソースコード上に直接埋め込まず、`.env` および `--dart-define`（ビルド時注入）を用いて安全に分離・管理する構造に設計しています。

3. **柔軟なモデル切り替え**
   - 初期検証（Groq等）から本番用（Gemini API）への移行において、柔軟に構造をリファクタリングできるよう意識しました。

---

## セットアップ手順 (Getting Started)

### 必須要件
- Flutter SDK
- Firebase プロジェクトの設定 (`firebase_options.dart`)
- Gemini API Key (`GEMINI_API_KEY`)

### ローカル実行手順

1. リポジトリをクローン
```bash
git clone [https://github.com/kd1459416-beep/Yorunohikari0.git](https://github.com/kd1459416-beep/Yorunohikari0.git)
cd Yorunohikari0