# Issue #23: デプロイ調査まとめ（Render × Neon）

## 概要

早期の本番デプロイに向けて、Render（ホスティング）と Neon（PostgreSQL）の仕様確認・アカウント準備を行う。

---

## 採用構成（全体像）

| 役割 | サービス |
|------|----------|
| アプリ | Rails（Render Web Service） |
| DB | Neon Postgres（DATABASE_URL で接続） |
| ソース管理 | GitHub（Render が自動デプロイ） |
| 環境変数 | Render の Environment 設定で管理 |

---

## 各サービスの無料枠・仕様

### Neon（Free プラン）

| 項目 | 内容 |
|------|------|
| ストレージ | 0.5 GB |
| コンピューティング | 最大 2 CU（autoscaling） |
| ブランチ | 10 branches / プロジェクト |
| スケール | 非アクティブ時にゼロスケール（コールドスタートあり） |
| リージョン | AWS / Azure から選択（Singapore 推奨） |

### Render（Free プラン）

| 項目 | 内容 |
|------|------|
| RAM | 512 MB |
| CPU | 0.1 CPU |
| 料金 | $0 / 月 |
| スピンアップ | 非アクティブ後、初回リクエストで起動（数十秒かかる） |
| 制限 | SSH アクセス・スケーリング・永続ディスク非対応 |

---

## 完了条件

- [x] Render および Neon のアカウントが用意され、管理画面にアクセスできること
- [x] 次のデプロイ設定タスク（環境変数や接続設定）を進めるための情報が揃っていること

---

## 明日やること（作業手順）

### 【STEP 1】Neon 側セットアップ

1. [Neon](https://neon.tech) でアカウント作成 / ログイン
2. 新規プロジェクトを作成
   - Project name: `robocup-supporter`
   - Region: **Singapore（Southeast Asia）**
   - Postgres version: 17
3. ダッシュボードの「Connect」から接続文字列を取得
   - `psql postgresql://USER:PASSWORD@HOST/neondb?sslmode=require` の形式
   - この値が `DATABASE_URL` に設定する値になる

### 【STEP 2】Render 側セットアップ

1. [Render](https://render.com) でアカウント作成 / ログイン
2. ダッシュボードから「New → Web Service」を選択
3. GitHub リポジトリ（`robocup-supporter`）を選択
4. 以下の項目を設定

| 項目 | 設定値 |
|------|--------|
| Name | robocup-supporter（任意） |
| Language | Ruby |
| Branch | main |
| Region | Singapore（Southeast Asia） |
| Build Command | `bundle install; bundle exec rake assets:precompile; bundle exec rake assets:clean; bin/rails db:migrate;` |
| Start Command | `bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}` |
| Instance Type | Free |

5. 環境変数（Environment Variables）を設定

| キー | 値 |
|------|----|
| `RAILS_ENV` | `production` |
| `DATABASE_URL` | Neon の接続文字列（STEP 1 で取得） |
| `RAILS_MASTER_KEY` | `config/master.key` の中身 |

### 【STEP 3】コードの修正

`config/database.yml` の production 設定を `DATABASE_URL` 対応に変更する。

**現在の設定（要変更）**

```yaml
production:
  <<: *default
  database: myapp_production
  username: myapp
  password: <%= ENV["MYAPP_DATABASE_PASSWORD"] %>
```

**修正後（DATABASE_URL を使う形）**

```yaml
production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

### 【STEP 4】デプロイ後の確認（最低限）

- [ ] Render のログで起動完了（エラーなし）
- [ ] TOP ページが表示される（200 レスポンス）
- [ ] DB 書き込みが成功する（CRUD の確認）

---

## よくある詰まりポイント

| 症状 | 原因 | 対処 |
|------|------|------|
| DB 接続エラー | `DATABASE_URL` が誤り | Neon の接続文字列を再確認（USER/PASS/HOST/sslmode） |
| DB 接続エラー | migration 未実行 | Build Command に `bin/rails db:migrate` が含まれているか確認 |
| credentials エラー | `RAILS_MASTER_KEY` が未設定 | Render の環境変数に `config/master.key` の値を追加 |

---

## 運用メモ（デプロイ後）

- **更新**: GitHub へ push → Render が Auto Deploy
- **手動再デプロイ**: Render の「Deploy latest commit」
- **ロールバック**: Render のデプロイ履歴から以前のバージョンを再リリース

---

## 作業ログ

### 2026-07-17 実施内容

- Neon側セットアップ完了
  - プロジェクト作成（Project name: `robocup-supporter` / Postgres version: 17 / Region: AWS Asia Pacific 1 (Singapore)）
  - 接続文字列（`DATABASE_URL` 用）取得済み
- Render側セットアップ（途中）
  - GitHub連携の権限設定（`yuki-tech-dev/robocup-supporter` を Only select repositories で許可）
  - Web Service作成画面で `robocup-supporter` リポジトリを選択
  - **Language は Docker のまま採用することに決定**（Ruby buildpack方式ではなく、リポジトリ既存の本番用 `Dockerfile` を使う方針）
    - 理由: Build/Start Commandの手打ちが不要、`RAILS_ENV`もDockerfile内で設定済み、マイグレーションも`bin/docker-entrypoint`で自動実行される
    - `cssbundling-rails` / `jsbundling-rails` が `assets:precompile` にフックするため、Tailwind CSS/esbuildもDockerfileだけで問題なくビルドされることを確認済み

### 次回（明日）やること

1. `config/database.yml` の production 設定を `DATABASE_URL` 対応に修正
2. Render の Web Service作成を最後まで進める（Region・Instance Type・環境変数設定）
   - 環境変数: `DATABASE_URL`（Neon接続文字列） / `RAILS_MASTER_KEY`（`config/master.key`の中身）
   - ※ Docker方式のため `RAILS_ENV` の設定は不要
3. デプロイ実行・動作確認（TOPページ200 / DB書き込み確認）

### 2026-07-18 実施内容（DB疎通確認・調査）

- Render Deploy成功、TOPページ200 OK確認済みだったが、アクセスログに `ActiveRecord: 0.0ms (0 queries, 0 cached)` とあり、DB疎通が本当に成功しているか未確認の状態だった
- 調査の結果、以下が判明
  - `TopController#index` は空アクションであり、そもそもDBへ問い合わせを行うコードが無い → ログにクエリが出ないのは当然で、DB接続失敗の証拠にはならない
  - Neonダッシュボードの SQL Editor で確認したところ、`public` スキーマのテーブル数は 0 件
  - ただし `db/migrate/` ディレクトリ自体が存在せず、マイグレーションファイルが1つも無い（モデル作成はこれから着手するタスクのため）→ テーブルが0件なのは仕様通りで異常ではない
  - `bin/docker-entrypoint` は `#!/bin/bash -e` のため、`./bin/rails db:prepare` が失敗した場合はその時点でスクリプトが終了し、以降の `exec "${@}"`（Pumaの起動）には到達しない
  - 実際のログでは Puma が正常に起動し、リクエストにも `200 OK` を返し続けていた＝`db:prepare` はエラーなく完了していたことが分かる

**結論**: DATABASE_URL / RAILS_MASTER_KEY を含むDB接続設定自体は正常に機能している。テーブルが0件なのはマイグレーションファイルが存在しないためであり、モデル・マイグレーション作成タスクに着手した際に改めて動作確認を行う。

→ この結論をもって **Issue #23・#24 をクローズ**。
