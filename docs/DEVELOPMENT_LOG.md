# 環境構築の手順や進捗状況を記録しておくためのファイル

## 進捗状況

### 2026-07-09 実施内容

#### 完了項目

- Dockerfile.dev を作成（Ruby 3.4.8、Node 20、Yarn対応）
- compose.yml を作成（PostgreSQL、Railsコンテナ設定）
- 設定ファイルを Git コミット

#### 発見した問題

- `docker compose build` 実行時に apt-key エラーが発生
  - 原因：Debian 13（trixie）では `apt-key` が廃止されている
  - カリキュラムのコードは古い方式を使用

#### 対応予定（明日以降）

1. Dockerfile.dev を修正（apt-key → gpg --dearmor 方式に変更）
2. `docker compose build` で再ビルド
3. Rails 7.2 をインストール
4. `docker compose run --rm web rails new . -d postgresql -j esbuild --css=tailwind`
5. database.yml を編集
6. `docker compose up` で起動確認
7. localhost:3000 でページ表示確認

## 使用技術

- Ruby 3.4.8
- Rails 7.2
- PostgreSQL
- Node.js 20
- esbuild（JS バンドラー）
- Tailwind CSS

### 2026-07-10 実施内容

#### 修正内容

- `Dockerfile.dev`:
  - Node.js の GPG 鍵登録を `gpg --dearmor` 方式で `/etc/apt/keyrings/nodesource.gpg` に保存するように変更しました。
  - `/etc/apt/keyrings` を作成する処理を追加し、NodeSource のソースリストを `/etc/apt/sources.list.d/nodesource.list` に出力するようにしました。
  - `nodejs` を apt からインストールし、`corepack` を利用して `yarn` を有効化・準備するように変更しました（`corepack enable` / `corepack prepare yarn@1.22.22 --activate`）。
- `compose.yml`:
  - `web` サービスの `command` を `bundle exec rails db:prepare && rm -f tmp/pids/server.pid && ./bin/dev` に変更し、ビルド時に毎回 `bundle install` を実行しない構成にしました。
  - `db` に `healthcheck` を追加し、ボリューム・ポートマッピングを明示しました。

#### 備考（推奨対応）

- `Dockerfile.dev` では Yarn を `corepack` 経由で準備しています。別の Yarn 管理方法（apt の公開鍵を dearmor 化して登録する等）を希望する場合は調整してください。
- 現在 `Gemfile` は未作成（空）のままです。Rails アプリ生成コマンドを実行して `Gemfile` とアプリ本体を作成してください（下記参照）。

#### 次のステップ

1. （私）`docs/DEVELOPMENT_LOG.md` に修正内容を追記しました。
2. （ユーザー）以下を実行してアプリを初期化／起動してください（コマンドはユーザー実行）:

```bash
# ビルド（ユーザー実行）
docker compose build

# Rails アプリ生成（例）
docker compose run --rm web rails new . -d postgresql -j esbuild --css=tailwind --force --skip-bundle

# 起動（ユーザー実行）
docker compose up
```

3.　 `Gemfile` 作成後、必要があればドキュメントを追記・修正します。

### 2026-07-11 実施内容

#### 確認結果

- `docker compose build` を実行し、Docker イメージ `robocup-supporter-web` のビルドが正常終了しました。
- ビルドログでは `bundle install` まで完了しており、イメージ生成に問題がないことを確認しました。
- これにより、Docker 環境のベース構築は完了しており、次は Rails アプリ生成へ進める状態です。

#### 補足

- 今回の `docker compose build` 成功は、`Dockerfile.dev` と `compose.yml` の構成が整っていることを示しています。
- ただし、Rails アプリ本体の生成はまだ実施していないため、`rails new` 実行後に `Gemfile` や Rails の初期構成が追加されます。
- 今回のリポジトリには既存の `Gemfile` / `Gemfile.lock` / `README.md` があるため、`rails new .` では `--force --skip-bundle` を付けた形で実行するのが安全です。
- その後、`docker compose up` によりアプリ起動を確認し、`localhost:3000` での表示確認を行います。

#### 実施手順（2026-07-11 完了）

以下の順番で実施し、すべて完了しました。

##### 1. Rails のインストール確認

```bash
docker compose run --rm web gem install rails -v '~> 7.2'
docker compose run --rm web rails -v
# => Rails 7.2.3.1
```

##### 2. Rails アプリ生成

既存リポジトリには `Gemfile` / `Gemfile.lock` / `README.md` があるため、`--force --skip-bundle` を付けて実行。

```bash
docker compose run --rm web rails new . -d postgresql -j esbuild --css=tailwind --force --skip-bundle
```

- `--force`: 既存ファイルがあっても生成を続行
- `--skip-bundle`: 生成直後の `bundle install` を省略し、後で明示的に実行する

##### 3. config/database.yml の編集

PostgreSQL コンテナに接続するため、`default` セクションに以下を追加。

```yaml
host: db
username: postgres
password: password
```

##### 4. Procfile.dev の作成

`--skip-bundle` により `bin/dev` が生成されなかったため、手動で作成。

```text
web: env RUBY_DEBUG_OPEN=true bin/rails server -b 0.0.0.0 -p 3000
js: yarn build --watch
css: yarn build:css --watch
```

##### 5. bundle install の実行

`--skip-bundle` で省略された依存関係のインストールを実施。

```bash
docker compose run --rm web bundle install
# => Bundle complete! 17 Gemfile dependencies, 105 gems now installed.
```

##### 6. esbuild / Tailwind CSS のセットアップ

`--skip-bundle` により `bin/dev` と `package.json` が生成されていなかったため、install コマンドで補完。

```bash
docker compose run --rm web rails javascript:install:esbuild
docker compose run --rm web rails css:install:tailwind
```

- `bin/dev` と `package.json` が生成された
- `yarn build` / `yarn build:css` が成功したことを確認

##### 7. 起動確認

```bash
docker compose up
```

- `localhost:3000` で Rails の初期画面が表示された
- Rails 7.2.3.1 / Ruby 3.4.8 / Rack 3.2.6 を確認

#### トラブルと解決策

|問題|原因|解決策|
|---|---|---|
|`sh -lc` 経由で `rails` コマンドが見つからない|シェル環境の PATH 差|`sh -lc` を使わず直接 `docker compose run --rm web rails ...` で実行|
|`bundle exec rails -v` で `railties is not currently included`|`--skip-bundle` で依存関係が未インストール|`docker compose run --rm web bundle install` を実行|
|`bin/dev` が存在しない|`--skip-bundle` で install コマンドが走らなかった|`rails javascript:install:esbuild` と `rails css:install:tailwind` で補完|

#### 決定事項

- 以降の開発方針として、`Sorcery 0.18.0（最新）`、`Ruby 3.4.8`、`Rails 7.2` の組み合わせで進めます。
- README の内容は後程更新予定です。
- README 更新時には、上記のバージョン方針とセットアップ手順を反映します。

### 2026-07-12 実施内容

#### Issue #17: RSpec の導入・初期設定

#### Issue #22 実施手順

1. `Gemfile` の `group :development, :test do` に以下を追加。

```ruby
gem "rspec-rails"
gem "factory_bot_rails"
```

1. 依存関係をインストール。

```bash
docker compose run --rm web bundle install
```

1. RSpec の初期化ファイルを生成。

```bash
docker compose run --rm web rails generate rspec:install
```

1. テスト実行の動作確認。

```bash
docker compose run --rm web bundle exec rspec --format documentation
```

#### 確認結果（Issue #17）

- `bundle install` で以下がインストールされたことを確認。
  - `rspec-rails (8.0.4)`
  - `factory_bot_rails (6.5.1)`
- `rails generate rspec:install` で以下が生成された。
  - `.rspec`
  - `spec/spec_helper.rb`
  - `spec/rails_helper.rb`
- `bundle exec rspec --format documentation` の実行結果。

```text
No examples found.

Finished in 0.00032 seconds (files took 0.11812 seconds to load)
0 examples, 0 failures
```

#### 発生した事象と対応

- 初回は `Could not find generator 'rspec:install'` / `bundler: command not found: rspec` が発生。
- 原因は、`Gemfile` の追記後に保存せず `bundle install` を実行していたため。
- `Gemfile` 保存後に `bundle install` を再実行し、解消した。

#### 補足（FactoryBot の運用方針）

- `config.include FactoryBot::Syntax::Methods` は追加せず、明示的に `FactoryBot.create(:user)` の形式で記述する方針とした。

#### Issue #18: GitHub Actions による CI 初期設定

#### 実施内容

対象ファイル: `.github/workflows/ci.yml`

- トリガー設定を確認。
  - `pull_request` 時に実行
  - `main` ブランチへの `push` 時に実行
- `test` ジョブを RSpec 実行に合わせて修正。
  - `DATABASE_URL` を `postgres://postgres:postgres@localhost:5432/myapp_test` に変更
  - 実行コマンドを以下に変更

```yaml
run: |
  bin/rails db:prepare
  bundle exec rspec --format progress
```

- Minitest/system test 前提の実行を削除。
  - 旧: `bin/rails db:test:prepare test test:system`
- system test 用スクリーンショット保存ステップを削除。
  - `Keep screenshots from failed system tests`
- `scan_ruby` ジョブの Brakeman 実行オプションを調整。
  - `bin/brakeman --no-pager --except EOLRails`

#### 発生した事象と対応（Issue #18）

- `scan_ruby` のみ失敗し、`lint` と `test` は成功。
- 失敗理由は Brakeman の `EOLRails` 警告。
  - `Support for Rails 7.2.3.1 ends on 2026-08-09`
- セキュリティチェックを維持しつつ CI を安定運用するため、`EOLRails` のみ除外して再実行。

#### 確認結果（Issue #18）

- PR 上で以下 3 ジョブがすべて Green になることを確認。
  - `CI / lint (pull_request)`
  - `CI / scan_ruby (pull_request)`
  - `CI / test (pull_request)`
- `No conflicts with base branch` を確認。

#### 補足（運用方針）

- Branch protection rules（CI 未通過時のマージブロック）は GitHub 側で設定する。
- Node 20 deprecation 警告は CI 失敗原因ではないため、別PRで Actions 更新時に対応する。

#### Issue #21: Tailwind CSS の導入・初期設定

#### 確認結果（Issue #21）

- `rails new --css=tailwind` 実行時に以下が自動生成済みであることを確認。
  - `app/assets/stylesheets/application.tailwind.css`（`@import "tailwindcss";`）
  - `package.json` の `build:css` スクリプト（`@tailwindcss/cli` v4 を使用）
  - `Procfile.dev` の `css: yarn build:css --watch`
  - `application.html.erb` の `stylesheet_link_tag "application"`（コンパイル済みCSSを読み込む）
- `docker compose up` 起動時のログで Tailwind v4.3.2 のコンパイル動作を確認。

```text
tailwindcss v4.3.2
Done in 276ms
```

#### 補足（Tailwind v4 について）

- Issue の記載にある `config/tailwind.config.js` は Tailwind v3 の設定ファイルであり、v4 では不要。
- v4 では `@import "tailwindcss"` の記述のみで動作する。
- Tailwind クラスの動作確認は Issue #22（TOPページ作成）にて実施予定。

### 2026-07-13 実施内容

#### Issue #22: TOPページの作成・Tailwind CSS 動作確認

#### 実施手順（Issue #22）

1. コントローラ・ビューの生成。

```bash
docker compose exec web bin/rails generate controller top index
```

生成されたファイル：

- `app/controllers/top_controller.rb`
- `app/views/top/index.html.erb`
- `spec/requests/top_spec.rb`
- `spec/views/top/index.html.erb_spec.rb`
- `app/helpers/top_helper.rb`

1. `config/routes.rb` を修正。

自動生成された `get "top/index"` を削除し、`root "top#index"` に変更。

- `get "top/index"` → `/top/index` というURLになるため不適切
- `root "top#index"` → `http://localhost:3000/` でTOPページを表示

1. `app/assets/images/iwatamikan.jpg` に背景画像を配置。

1. `app/views/top/index.html.erb` にTailwindクラスを使ったTOPページを実装。

#### 実装内容（TOPページ構成）

- **ヘッダー**：ロゴ（左）・新規登録・ログインボタン（右）
- **ヒーローセクション**：ロボット画像を背景（`asset_path` でパス解決）、半透明オーバーレイ（`opacity-50`）、タイトル・キャッチコピーを中央表示
- **フッター**：利用規約・プライバシーポリシーリンク

#### 確認結果（Issue #22）

- `http://localhost:3000/` でTOPページが表示されることを確認。
- Tailwindクラス（`flex`・`text-5xl`・`rounded-full`・`hover:` など）が正常に動作することを確認。

#### Issue #22 補足

- `asset_path` ヘルパーを使うことでアセットパイプラインが画像の正しいURLを解決する。
- `background-size: auto 120%` により画像がタイル状に繰り返し表示される（`background-repeat` デフォルトが `repeat` のため）。意図的にこのデザインを採用。
- ログイン・新規登録ボタンのリンク先は現在 `#`（認証機能実装時に変更予定）。

### 2026-07-14 実施内容

#### Issue #19: i18n（国際化）の導入と日本語化の初期設定

#### 実施手順（Issue #19）

1. `Gemfile` に以下を追加。

```ruby
gem "rails-i18n"
```

1. 依存関係をインストール。

```bash
docker compose run --rm web bundle install
# => Installing rails-i18n 7.0.10
```

1. `config/application.rb` にデフォルトロケールを設定。

```ruby
# デフォルトロケールを日本語に設定
config.i18n.default_locale = :ja
```

1. `config/locales/ja.yml` を新規作成。

#### 確認結果（Issue #19）

- `rails console` にて以下を確認。
  - `I18n.locale` → `:ja`
  - `I18n.t "hello"` → `"こんにちは"`
- `bundle exec rspec` 実行結果：`3 examples, 0 failures`

#### 補足（Issue #19）

- `rails-i18n` gem により Rails 標準のバリデーションエラーメッセージが自動的に日本語化される。
- `ja.yml` はアプリ固有の翻訳を追加するためのファイルとして作成。今後モデル追加のたびに翻訳を追記していく。
- ロケール切り替え（多言語対応）が必要になった際は `around_action` と `I18n.with_locale` を使用する。

### 2026-07-18 実施内容

#### Issue #25: usersテーブルのマイグレーション作成

#### 実施手順（Issue #25）

1. マイグレーションファイルを生成。

```bash
docker compose exec web rails g migration CreateUsers email:string:uniq crypted_password:string salt:string name:string role:integer
```

1. 生成された `db/migrate/xxxxx_create_users.rb` を編集し、各カラムに `null: false`、`role` に `default: 0` を追加。

```ruby
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :crypted_password, null: false
      t.string :salt, null: false
      t.string :name, null: false
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
```

1. マイグレーションを実行。

```bash
docker compose exec web rails db:migrate
```

#### 発生した事象と対応（Issue #25）

- マイグレーションファイル生成直後（`null: false` / `default: 0` 未追記の状態）で一度 `db:migrate` を実行してしまい、`db/schema.rb` に制約が反映されない状態になった。
- Railsは実行済みマイグレーション（`schema_migrations` に記録済み）をファイル編集後も再実行しないため、`db:rollback` で一度戻し、編集済みの内容で `db:migrate` をやり直して解消した。

```bash
docker compose exec web rails db:rollback
docker compose exec web rails db:migrate
```

#### 確認結果（Issue #25）

- `db/schema.rb` に以下が反映されていることを確認。
  - `email` / `crypted_password` / `salt` / `name` が `null: false`
  - `role` が `null: false, default: 0`
  - `email` にユニークインデックス（`index_users_on_email`）
- 本番環境（Render + Neon）へのマージ・デプロイ後、Neonのテーブルエディタで同様の制約・インデックスが反映されていることを確認。

#### 補足（Issue #25）

- Sorceryの認証機能で使用する `crypted_password` / `salt` のカラム名は、Sorceryのデフォルト設定に合わせたもの（Issue #26で導入予定）。
- マイグレーションファイルを手動編集する場合は、`db:migrate` 実行前に編集を完了させること（実行後の編集はDBに反映されない）。

#### Issue #26: Sorcery（認証gem）の導入・初期設定

#### 実施手順（Issue #26）

1. `Gemfile` に `gem "sorcery"` を追加し、`bundle install` を実行。

```bash
bundle install
```

1. Sorceryの初期設定コマンドを実行。

```bash
docker compose exec web rails g sorcery:install
```

1. `rails g sorcery:install` により自動生成された `db/migrate/xxxxx_sorcery_core.rb` の中身を確認したところ、Issue #25で既に作成済みの `users` テーブルと重複する `create_table :users` が含まれていたため、当該マイグレーションファイルを削除した。

```bash
rm db/migrate/20260718075118_sorcery_core.rb
```

1. `config/initializers/sorcery.rb` の内容を確認。

#### 発生した事象と対応（Issue #26）

- `sorcery:install` ジェネレータは、`users` テーブルが未作成であることを前提に、`crypted_password` / `salt` などのカラムを持つ新規 `create_table :users` のマイグレーションを自動生成する。
- 本プロジェクトではIssue #25で `users` テーブルを既に作成済み（かつSorceryのデフォルトカラム名に合わせて設計済み）だったため、そのままマイグレーションを実行すると「テーブルが既に存在する」エラーになる。生成されたマイグレーションファイルの中身を確認のうえ削除して対応した。

#### 確認結果（Issue #26）

- `app/models/user.rb` に `authenticates_with_sorcery!` が生成されていることを確認。
- `config/initializers/sorcery.rb` の `user_config` 内、`email_attribute_name` / `crypted_password_attribute_name` / `salt_attribute_name` の設定（いずれもコメントアウト＝デフォルト値）が、Issue #25で作成した `users` テーブルのカラム名（`email` / `crypted_password` / `salt`）と一致していることを確認。カラム名の変更は不要と判断。
- `Rails.application.config.sorcery.submodules = []` のまま（コア機能のみ）とし、`remember_me` 等の追加サブモジュールは後続のIssue（ログイン機能実装時）で検討する。
- `docker compose exec web rails db:migrate` を実行し、エラーなく完了することを確認（未実行のマイグレーションが無いため実質的に何も処理されない状態）。
- コンテナを一度 `docker compose stop` → `docker compose up` で再起動し、起動ログにSorcery起因のエラー（`NoMethodError` 等）が無いこと、Pumaが正常起動しTOPページが200 OKで表示されることを確認。

#### 補足（Issue #26）

- 本Issueのスコープは「Sorceryの導入・初期設定」までであり、`User` モデルへのバリデーション追加（`validates :email` 等）やログイン機能の実装は含まない。それらは後続のIssueで対応する。

#### Issue #31: ヘッダー・フッターの共通レイアウト化（画面遷移のベース作成）

#### 実施手順（Issue #31）

1. 共通ヘッダーパーツ `app/views/shared/_header.html.erb` を作成。
   - ロゴ（`root_path` へのリンク）を左に配置。
   - `logged_in?` の値により、ナビゲーションの表示を出し分け。
     - 未ログイン時：「新規登録」「ログイン」ボタンを表示。
     - ログイン時：`current_user.name` とログアウトボタンを表示。
2. 共通フッターパーツ `app/views/shared/_footer.html.erb` を作成。
   - 「利用規約」「プライバシーポリシー」へのリンクを配置。
3. `app/views/layouts/application.html.erb` の `<body>` 内を修正し、`yield` の前後に共通ヘッダー・フッターを描画するよう変更。

```erb
<%= render "shared/header" %>
<%= yield %>
<%= render "shared/footer" %>
```

1. `app/views/top/index.html.erb` から、Issue #22で実装していたヘッダー・フッターの記述を削除し、`<main>` のヒーローセクションのみを残す構成に変更（レイアウト側で共通化したため）。

#### 認証系リンクの扱い（Issue #31）

- ログイン・新規登録・ログアウトのリンク先は、対応する認証機能が未実装のため、いずれも `#`（仮リンク）とし、実装対象のIssue番号をTODOコメントで明記した。
  - 「新規登録」→ Issue #27 実装後、`new_user_registration_path` 等に差し替え予定。
  - 「ログイン」→ Issue #28 実装後、`new_user_session_path` 等に差し替え予定。
  - 「ログアウト」→ Issue #29 実装後、`logout_path` 等に差し替え予定（`data: { turbo_method: :delete }` の付与も必要）。
  - フッターの「利用規約」「プライバシーポリシー」→ Issue #44 / #45 実装後、それぞれ差し替え予定。

#### テスト追加（Issue #31）

- `spec/requests/top_spec.rb` に、共通ヘッダーがTOPページに正しく描画されることを検証するテストを追加。
  - ヘッダーのロゴ（アプリ名）が表示されること。
  - 未ログイン状態のため「ログイン」「新規登録」が表示されること。
- ビューspec（`spec/views/top/index.html.erb_spec.rb`）ではなくリクエストspecで検証した理由：ビューspecは対象テンプレート単体をレンダリングし、レイアウト（`application.html.erb`）を経由しないため、レイアウト側に実装した共通ヘッダー・フッターの描画確認にはリクエストspecが適している。

#### 確認結果（Issue #31）

- ブラウザで `http://localhost:3000/` を表示し、以下を目視確認。
  - 共通ヘッダー（ロゴ、未ログイン時の「新規登録」「ログイン」ボタン）が表示される。
  - 共通フッター（「利用規約」「プライバシーポリシー」リンク）が表示される。
- `docker compose exec web bin/rubocop` を実行し、`39 files inspected, no offenses detected` を確認。
- `docker compose exec web bundle exec rspec` を実行し、`7 examples, 0 failures, 3 pending` を確認（pending 3件はIssue #31とは無関係の既存の自動生成スタブ）。

#### 補足（Issue #31）

- ヘッダー・フッターを `app/views/shared/` 配下の共通パーツとして切り出したことで、今後追加する全ページで同一のヘッダー・フッターが自動的に適用される。
- `logged_in?` / `current_user` はSorcery導入時（Issue #26）に `ActionController::Base` へ組み込まれており、追加の設定なしにビューから利用できる。

### 2026-07-19 実施内容

#### Issue #32: フラッシュメッセージ共通コンポーネント作成

#### 実施手順（Issue #32）

1. `app/views/shared/_flash_message.html.erb` に、`flash.each` でメッセージタイプ（`notice`/`alert`/`success`/`danger`/`warning`）ごとにTailwindの背景色（緑・赤・黄）を出し分ける`case/when`を実装。該当しないタイプは`bg-blue-500`にフォールバック。
2. `app/views/layouts/application.html.erb` の共通ヘッダー直後にpartialを組み込み。

```erb
<%= render "shared/header" %>
<%= render "shared/flash_message" %>
<%= yield %>
<%= render "shared/footer" %>
```

1. `TopController#index` に `flash[:notice] = "test"` を一時的に追加し、ブラウザで表示・配色を確認後、動作確認用コードは削除。

#### 発生した事象と対応（Issue #32）

- 実装初期の `class="alert alert-<%= message_type %>"` は Bootstrap のクラス命名（`alert alert-notice` 等）を踏襲したものだったが、本プロジェクトは Tailwind CSS のため、これらのクラスには対応するスタイル定義が存在せず、見た目に反映されなかった。Tailwindのユーティリティクラス（`bg-green-500` 等）を直接出し分ける方式に変更した。
- `case/when` の分岐で `when "warning", "danger" then "bg-yellow-500"` としており、`"danger"` が直前の `when "alert", "danger" then "bg-red-500"` と重複していた（`case/when` は上から評価されるため、`danger` は常に赤色の分岐に一致し、黄色の分岐には到達しない dead code だった）。`warning` のみを残す形に修正。
- Tailwindのクラス名に `rou` という誤字があり（`rounded-2xl` の書き損じ）、角丸が適用されていなかった。修正して解消。
- 見た目に影響しない `alert` という素のクラス（Bootstrap由来の名残）が残っていたため、使い道が無いことを確認のうえ削除し、`class`属性をシンプルにした。

#### テスト追加（Issue #32）

- `spec/views/shared/_flash_message.html.erb_spec.rb` を新規作成し、`type: :view` でpartial単体をテスト（`flash[:notice]`をセットして`render`し、表示文言を検証）。
- request specではなくview specを採用した理由：`flash`はリダイレクトを経由して初めて次のリクエストに引き継がれる仕組みのため、request specで`get "/"`する前に直接`flash`をセットする手段が無い。view specであれば`flash[:notice] = "..."`をセットしてから`render`するだけでpartial単体の表示確認ができる。

#### 確認結果（Issue #32）

- ブラウザで `flash[:notice]`（緑）・`flash[:alert]`（赤）・`flash[:warning]`（黄）の3種類の配色を目視確認。
- `docker compose exec web bundle exec rubocop` を実行し、`39 files inspected, no offenses detected` を確認。
- `docker compose exec web bundle exec rspec` を実行し、`8 examples, 0 failures, 3 pending` を確認（pending 3件は本Issueとは無関係の既存の自動生成スタブ）。

#### 補足（Issue #32）

- `message_type` がどのケースにも該当しない場合は `else` で `bg-blue-500`（notice/infoに近い色）にフォールバックするようにし、想定外のflashキーが来ても表示崩れが起きないようにした。
- 今後、`redirect_to root_path, notice: "..."` のようにコントローラ側でflashをセットするだけで、この共通コンポーネントがそのまま利用できる（Issue #27〜29のサインアップ・ログイン・ログアウト実装時に活用予定）。

#### Issue #27: 新規ユーザー登録機能（Sign up）

#### 実施手順（Issue #27）

1. ルーティング追加: `resources :users, only: %i[new create]`
2. `UsersController` を新規作成（`new`/`create`アクション、`user_params`でStrong Parameters制限）
3. `User`モデルにバリデーションを追加（`name`/`email`の必須・一意性チェック、Sorceryの仮想属性を考慮した`password`の条件付き文字数・確認一致チェック）
4. `app/views/users/new.html.erb` を新規作成し、Tailwind CSSでスタイリング
5. `config/locales/ja.yml` にラベル・フラッシュメッセージ等の文言を追加し、使っていない汎用文言は削除
6. `app/views/shared/_error_messages.html.erb` を新規作成し、バリデーションエラー一覧を表示

#### 発生した事象と対応（Issue #27）

- クラス名を`UserController`（単数形）としてしまい、ファイル名`users_controller.rb`との不一致でZeitwerkのオートロードが破綻し、`TypeError: superclass mismatch`が発生 → `UsersController`（複数形）に修正して解消。
- `user_params`が当初`crypted_password`/`salt`を直接permitしていたが、これらはSorceryがパスワードのハッシュ化時に内部で使うカラムであり、フォームが直接扱うべきは仮想属性の`password`/`password_confirmation`だった → 許可する属性を修正。
- パスワードの条件付きバリデーションで、`changes[:password_digest]`（`has_secure_password`由来の書き方）や`changes[:password_confirmation]`のように、DBに存在しない仮想属性に対して`changes`（ActiveRecordの実カラムの変更検知の仕組み）を使おうとしており機能しない状態だった → `password.present?`で仮想属性自体の値を直接判定する方式に修正。
- `ApplicationController`に`before_action :require_login`を追加した結果、ログイン機能（Issue #28）が未実装のままTOPページを含む全ページが未定義の`login_path`へリダイレクトを試み、`NameError`が発生 → Issue #28実装までは`before_action`をコメントアウトして保留することにした。
- `f.label`が日本語化されない事象が発生。原因はRailsのラベル翻訳キーの検索順序で、モデル名でスコープされた`helpers.label.user.email`のような階層が必要だったため（`helpers.label.email`のようなフラット構造では拾われない）→ `ja.yml`の階層を修正して解消。
- バリデーションエラーメッセージの属性名部分が英語のままだった。原因は`activerecord.attributes.user.*`が未定義だったため → 追加して解消。
- フォームのスタイリングがBootstrapのクラス（`container`/`row`/`form-control`/`btn btn-primary`等）のままになっており、Tailwind CSSを採用している本プロジェクトでは効いていなかった → Tailwindのユーティリティクラスに書き換え。

#### テスト追加（Issue #27）

- `spec/factories/users.rb`が空定義のままだったため、`email`（sequence）/`name`/`password`/`password_confirmation`のデフォルト値を追加。
- `spec/rails_helper.rb`の`RSpec.configure`に`config.include FactoryBot::Syntax::Methods`が設定されておらず、request specで`attributes_for`等のFactoryBotメソッドが使えなかった → 追加して解消。
- `spec/requests/users_spec.rb`を新規作成。GET `/users/new`（200・タイトル表示）、POST `/users`（正常系: 作成＋リダイレクト、異常系: 作成されずエラー表示）の計4件。

#### 確認結果（Issue #27）

- ブラウザで正常系（登録成功→TOPページへリダイレクト＋成功フラッシュ表示）・異常系（空欄送信→エラー一覧表示）を確認。
- `docker compose exec web bundle exec rubocop`: 41 files inspected, no offenses detected
- `docker compose exec web bundle exec rspec`: 12 examples, 0 failures, 3 pending（既存の無関係スタブ）
- `docker compose exec web bin/brakeman`: Security Warnings 1件（`EOLRails`、Rails 7.2の保守期限に関する一般的な注意喚起のみ）。CIでは`--except EOLRails`で除外済みのため実質0件。

#### 補足（Issue #27）

- `app/views/shared/_error_messages.html.erb`を`shared/`配下の共通パーツとして作成したため、Issue #28（ログイン機能）でも再利用できる。
- ヘッダーの新規登録リンク（`_header.html.erb`）を仮リンク（`"#"`）から`new_user_path`に差し替え、対応するTODOコメントを削除。
- ログインページへのリンク（`users/new.html.erb`内）は`login_path`が未実装のため仮リンク（`"#"`）のままとし、TODOコメントでIssue #28を明記。

#### Issue #28: ログイン機能（Sign in）＆自動ログイン保持

#### 実施手順（Issue #28）

1. ルーティング追加: `get "login"` / `post "login"` / `delete "logout"`（`user_sessions#new/create/destroy`）
2. `UserSessionsController`を新規作成（`new`/`create`/`destroy`、`skip_before_action :require_login, only: %i[new create]`）。`create`はSorceryの`login(email, password)`メソッドで認証・セッション管理を任せる方式にした（手動での`session[:user_id] = ...`は行わない）
3. `remember_me`サブモジュールを有効化: `config/initializers/sorcery.rb`の`submodules = [ :remember_me ]`、`db/migrate/20260719010000_add_remember_me_to_users.rb`を作成し`remember_me_token`/`remember_me_token_expires_at`カラムを追加
4. `UserSessionsController#create`に`remember_me! if params[:remember_me] == "1"`を追加
5. `app/views/user_sessions/new.html.erb`を新規作成（`form_with url: login_path`、モデル非依存の`*_field_tag`、remember_meチェックボックス付き）。パスワード再設定はMVP範囲外のため、リンクごとコメントアウトしTODOで理由を明記
6. `_header.html.erb`のログイン/ログアウトリンクを`login_path`/`logout_path`（ログアウトは`data: { turbo_method: :delete }`）に差し替え
7. `ApplicationController`の`before_action :require_login`が既に有効化されていたため、`TopController`に`skip_before_action :require_login, only: %i[index]`を追加し、TOPページを未ログインでも閲覧可能にした

#### 発生した事象と対応（Issue #28）

- `login`メソッドを`User.find_by(...).login(...)`のようにモデルのインスタンスに対して呼ぼうとする誤った書き方をしてしまった。Sorceryの`login`/`logout`/`remember_me!`は`authenticates_with_sorcery!`を宣言したコントローラー側で使えるメソッドであり、モデルのインスタンスメソッドではないため、コントローラー内で直接呼び出す形に修正。
- ヘッダーの「ログアウト」リンクをクリックすると`Routing Error: No route matches [GET] "/logout"`が発生。原因は`app/javascript/application.js`の中身が空（コメントのみ）で、`@hotwired/turbo-rails`がimportされておらず、Turboが一切機能していなかったため。`data: { turbo_method: :delete }`はTurboがクリックをフックしてDELETEリクエストに変換する仕組みなので、Turbo未導入だと通常の`<a>`タグとして扱われブラウザ標準のGETリクエストが飛んでしまう。`Gemfile`には`turbo-rails`gemが既に入っていたが、esbuild構成のためフロントエンド側の対応するnpmパッケージ・importが漏れていたことが原因と判明。`npm install @hotwired/turbo-rails`を実行し、`application.js`に`import "@hotwired/turbo-rails"`を追記して解消。

#### テスト追加（Issue #28）

- `spec/requests/user_sessions_spec.rb`を新規作成。GET `/login`（200・タイトル表示）、POST `/login`正常系（ログイン成功→リダイレクト＋ヘッダーがログアウト表示に切り替わる）・異常系（誤ったパスワード→失敗メッセージ表示）、DELETE `/logout`（ログアウト成功→リダイレクト＋ヘッダーが新規登録表示に戻る）の計5件。
- 当初`DELETE /logout`のテストで`expect(response.body).not_to include("ログアウト")`としていたが、ログアウト成功時のフラッシュメッセージ自体が「ログアウトしました」という文言で"ログアウト"を含むため誤って失敗する状態だった → 未ログイン状態特有の文言（「新規登録」リンクの表示）で検証する形に修正して解消。

#### 確認結果（Issue #28）

- ブラウザで新規登録→ログアウト→ログイン→remember_meチェックの一連の流れを確認。ログイン後はヘッダーがユーザー名＋ログアウト表示に切り替わり、remember_meチェックを入れてログインすると`remember_me_token`Cookieが有効期限付きで発行されることを開発者ツールで確認。
- `docker compose exec web bin/rubocop`: 45 files inspected, no offenses detected
- `docker compose exec web bundle exec rspec`: 17 examples, 0 failures, 3 pending（既存の無関係スタブ）
- `docker compose exec web bin/brakeman`: Security Warnings 1件（`EOLRails`のみ、CIでは除外済みのため実質0件）

#### 補足（Issue #28）

- パスワード再設定機能はMVP範囲外と判断し、実装しないことに決定。`user_sessions/new.html.erb`のリンクはコメントアウトし、TODOコメントに理由を明記（将来Issue化する場合に有効化する想定）。
- ログアウト機能（ヘッダーのログアウトボタン）まで含めて本Issueで完成させた（Issue #29は残タスクなしのため実質クローズ扱い）。
- ログイン成功後のリダイレクトはフレンドリーフォワーディングを実装せず、`root_path`固定のシンプルな方式とした。

### 2026-07-22 実施内容

#### Issue #33: schedulesテーブルのマイグレーション作成

#### 実施手順（Issue #33）

1. ER図とIssue本文のカラム構成を突き合わせ、食い違いを確認（後述）
2. `docker compose exec web rails g migration CreateSchedules title:string start_time:datetime end_time:datetime location:string description:text` でマイグレーションファイルを生成
3. `title`/`start_time`に`null: false`、`title`に`default: "練習会"`を追記し、`docker compose exec web rails db:migrate`を実行して`db/schema.rb`への反映を確認
4. `app/models/schedule.rb`を新規作成し、バリデーションを追加（`title`: 必須＋3〜30文字、`start_time`: 必須、`location`/`description`: 255文字以内）
5. `spec/factories/schedules.rb`を新規作成
6. `docker compose exec web bin/rubocop -A`・`bundle exec rspec`を実行し、既存テストへの影響がないことを確認

#### 発生した事象と対応（Issue #33）

- Issue本文は当初`date`（date型）＋`time`（time型）の2カラム構成で、予定の終了時刻を管理するカラムが存在しない内容だったが、ER図では`start_time`／`end_time`（共にdatetime）の2カラム構成だったため食い違いが判明。ER図を正としてユーザーがGitHub上でIssue本文を修正（`start_time`／`end_time`のdatetime構成に変更）。
- マイグレーション生成コマンドで属性指定の区切りにカンマを入れてしまうと（`title:string, start_time:datetime, ...`）、シェルが引数を分割する際にカンマが型名にくっついて渡ってしまい正しく解釈されない → スペース区切りに修正。
- マイグレーション名を単に`Schedules`にすると、Railsのジェネレータは名前のパターン（`CreateXxx`／`AddXxxToYyy`／`RemoveXxxFromYyy`）に応じて生成内容を変える仕組みのため、`add_column`が生成されてしまい、存在しないテーブルへの列追加になり失敗する → `CreateSchedules`に修正し、`create_table`ブロックが正しく生成されることを確認。
- `t.datetime :start_time, null: false, default: 13:30`のように時刻リテラルをクォートせず記述しており、Rubyの構文として不正な状態だった → `"2000-01-01 13:30:00"`のように文字列でクォートする必要があると気づき修正（最終的に`start_time`／`end_time`自体には`default`値を設定しない方針にした）。
- `validates :title, length: { minimum: 3 }, length: { maximum: 30 }, presence: true`のように、同一メソッド呼び出し内で`length:`キーを2回指定してしまい、Rubyのハッシュの仕様上、後に書いた`maximum`側で上書きされ`minimum`の指定が無効化されていた → `length: { within: 3..30 }`に統合して解消。
- `bin/rubocop -A`実行時、`schedule.rb`のクラス本体先頭に余分な空行があり`Layout/EmptyLinesAroundClassBody`で指摘・自動修正された。

#### テスト追加（Issue #33）

- `spec/factories/schedules.rb`を新規作成（`title`／`start_time`／`end_time`／`location`／`description`にダミー値を設定し、`create(:schedule)`で有効なレコードがすぐ作れるようにした）。
- Issue #33自体は画面を追加しないIssueのため、リポジトリのMVPテスト方針（画面追加ごとにrequest spec 1本）には該当せず、今回はRailsコンソールでのバリデーション動作確認に留めた（request/model specはIssue #34以降で必要に応じて追加）。

#### 確認結果（Issue #33）

- Railsコンソールで`Schedule.new.valid?`が`false`（必須項目`title`／`start_time`が空のため）、`Schedule.new(title: "練習会", start_time: Time.current).valid?`が`true`（必須項目が埋まっているため）となることを確認。
- `docker compose exec web bin/rubocop`: 47 files inspected, no offenses detected
- `docker compose exec web bundle exec rspec`: 17 examples, 0 failures, 3 pending（既存の無関係スタブ）

#### 補足（Issue #33）

- `schedules`テーブルには`user_id`等の外部キーを意図的に持たせていない（管理者であれば誰でも予定を作成できる想定のため）。
- ER図・テーブル定義の詳細は`/memories/repo/schema.md`（リポジトリメモリ）にも記録済み。
- ブランチ`feat/issue-33-schedules-migration`で作業。コミットは「feat: schedulesテーブルのマイグレーションを作成」「feat: Scheduleモデルとバリデーションを追加」「test: schedule用のFactoryBotを追加」の3分割で実施。

#### Issue #34: 予定の新規登録機能の作成（C：Create）

#### 実施手順（Issue #34）

1. Issue本文にまだ残っていた`date`/`time`表記を、`#33`で確定した`start_time`/`end_time`（datetime）に合わせてGitHub上で修正
2. `config/routes.rb`に`resources :schedules, only: %i[new create]`を追加
3. `app/controllers/schedules_controller.rb`を新規作成（`new`/`create`アクション、ストロングパラメーターでER図の5項目を許可）
4. `config/locales/ja.yml`に`activerecord.attributes.schedule.*`・`helpers.label.schedule.*`・`schedules.new`/`schedules.create`の文言を追加
5. `app/views/schedules/new.html.erb`を新規作成（Tailwind CSSで、50代〜60代のスタッフでも押しやすい大きめの入力欄・ボタンサイズに調整、`start_time`/`end_time`は`datetime_field`、`description`は`text_area`を使用）
6. ブラウザで正常系（5項目入力→保存→トップページへリダイレクト＋成功フラッシュ表示）・異常系（`title`/`start_time`未入力→画面遷移せずエラー表示）を確認
7. `spec/requests/schedules_spec.rb`を新規作成（GET `/schedules/new`、POST `/schedules`正常系・異常系の計4件）
8. `docker compose exec web bin/rubocop`・`bundle exec rspec`を実行し、既存テストへの影響がないことを確認

#### 発生した事象と対応（Issue #34）

- 異常系の確認時、`title`を空にして送信すると「タイトルは3文字以上で入力してください」と「タイトルを入力してください」の2件のエラーメッセージが同時に表示される事象が発生。原因は`title`に対して`presence: true`と`length: { within: 3..30 }`を別々に定義しており、値が空の場合は両方のバリデーションがそれぞれ反応してしまうため（Rubyの`||`のような早期リターンは無く、定義したバリデーションは基本的にすべて評価される）。`length`のオプションに`allow_blank: true`を追加し、値が空の場合は`length`チェックをスキップするよう修正して解消。

#### テスト追加（Issue #34）

- `spec/requests/schedules_spec.rb`を新規作成。`#34`から`schedules`系のページは`require_login`が有効（管理機能のため）なので、`before`ブロックで`post login_path`を実行しログイン状態を作ってから各テストを実行する構成にした。
  - GET `/schedules/new`: 200が返ること／「予定の新規登録」というタイトルが表示されること
  - POST `/schedules`（正常系）: `Schedule`件数が1件増えること／`root_path`へリダイレクトされること／成功フラッシュ（「予定を登録しました」）が表示されること
  - POST `/schedules`（異常系）: `Schedule`件数が変わらないこと／失敗フラッシュ（「予定の登録に失敗しました」）が表示されること

#### 確認結果（Issue #34）

- ブラウザで正常系・異常系（`title`/`start_time`未入力時のエラー表示、修正後は重複メッセージが解消されていることも含む）を確認。
- `docker compose exec web bin/rubocop`: 49 files inspected, no offenses detected
- `docker compose exec web bundle exec rspec`: 21 examples, 0 failures, 3 pending（既存の無関係スタブ）

#### 補足（Issue #34）

- 新規登録画面への導線（ヘッダー等からのリンク）はまだ設置していない。`#35`（カレンダーUI）実装時に、カレンダー画面から「新規登録」ボタンを設置する方針にまとめて対応する。
- カレンダーの特定の日付をクリックした際に、その日付が事前入力された状態で登録フォームに遷移するUXを`#35`で検討する方針で合意（`new_schedule_path(date: ...)`のようなクエリパラメータを想定）。
- `#35`・`#36`のIssue本文にも`date`/`time`という古いカラム名の記載が残っているため、それぞれのIssue着手時に本文修正が必要。
- ブランチ`feat/issue-34-schedule-create`で作業。

### 2026-07-23 実施内容（作業中）

#### Issue #35: 月間カレンダーUI導入・直近予定一覧表示（途中経過）

#### 実施手順（Issue #35）

1. Issue本文をGitHub上で修正（表示場所を「ログイン後のトップページ（`TopController#index`）」に確定、ビュー例を`app/views/top/index.html.erb`に変更、ロール別編集可否は`#37`のスコープ外である旨を追記）
2. 設計方針を決定: 別コントローラーは新設せず、`root "top#index"`のまま`logged_in?`で出し分ける方式を採用（未ログイン時は従来のsplash画面、ログイン時はカレンダー画面）
3. `Gemfile`に`gem "simple_calendar", "~> 2.4"`を追加し、`docker compose run --rm web bundle install`でインストール
4. `TopController#index`を修正し、ログイン時のみ`@schedules`（カレンダー描画用の全件）と`@upcoming_schedules`（`start_time`が今日以降・昇順・先頭5件）を取得するよう変更
5. `app/views/top/index.html.erb`を「出し分けの入口」に変更し、中身を`_guest_home.html.erb`（旧index.html.erbの内容）と`_calendar_home.html.erb`（新規、`month_calendar`ヘルパー＋直近予定一覧）に分割
6. ブラウザで動作確認

#### 発生した事象と対応（Issue #35）

- `docker compose exec web bundle install`を実行するとエラーになった。原因は、Gemfile.lockにgemが未反映の状態だと`web`コンテナ自体が`bundle exec`系コマンドの起動チェックで失敗し終了してしまうため、`exec`（起動中コンテナに対して実行）の対象コンテナが存在しない状態だったこと。`docker compose run --rm web bundle install`（一時コンテナを新規作成して1回だけ実行）に変更して解決。
- カレンダーを表示すると、曜日ヘッダーが4つ（月〜金の一部）しか表示されず、日付マス目も1行分しか出ない事象が発生。原因は`calendar`ヘルパーと`month_calendar`ヘルパーの違い（`calendar`はデフォルトで4日分のみ表示する汎用クラス`SimpleCalendar::Calendar`を使い、月全体を表示するには`month_calendar`ヘルパー（`SimpleCalendar::MonthCalendar`）を使う必要がある）と判明し、`month_calendar`に変更して解消。
- `month_calendar`に変更後、曜日・週の構造は正しくなったが、日付の数字（1、2、3…）が一切表示されない事象が発生。simple_calendarのgemは`<td>`という箱と、その日に該当する`events`データをブロックに渡してくれるだけで、日付の数字自体は自動描画しない仕様と判明。ブロック内に`<%= date.day %>`を明示的に追加して解消。
- 予定を1件登録して確認したところ、「直近の予定」一覧には表示されるのに、カレンダー本体のマス目には表示されない事象が発生。Railsコンソールで調査した結果、テストデータの`end_time`が`start_time`より3日も前の日時になっていたことが原因と判明。simple_calendar内部の複数日イベント対応ロジック（`(event_start_date..event_end_date).each`というRange処理）は、開始日が終了日より後だと空のRangeになり`.each`が一度も実行されないため、そのイベントがどの日付にも一切登録されない（`has-events`クラスも付与されない）という仕組みだった。壊れたテストデータの修正で表示されることを確認。
  - この調査を通じて、「`Schedule`モデルに`end_time`が`start_time`より前にならないようにするバリデーションが無い」というデータ品質上の課題を発見し、別Issue（データ品質改善）として切り出す方針で合意（Issueは草案提示済み、登録は次回）。
- ブラウザのアドレスバーに`http://localhost:3000/?start_date=.../schedules/new`のようにクエリ文字列付きURLの末尾にパスを継ぎ足してアクセスしてしまい、ルーティングされない事象が発生。URLの「パス」と「クエリ文字列（`?`以降）」の構造を再確認し、正しいURLに修正して解決。

#### 確認結果（Issue #35、途中経過）

- ログイン後のトップページに月間カレンダー（前月・翌月切り替え含む）と、登録した予定のタイトル・時刻が正しい日付のマス目に表示されることを確認
- 「直近の予定」セクションにも、今日以降の予定が日時・場所付きで表示されることを確認

#### 残課題（次回、2026-07-24以降）

- カレンダー表の見た目崩れ（コンテナ幅に対して表がはみ出し、曜日と日付列がズレて折り返される）のTailwindスタイリング調整
- データ品質改善Issue（`end_time`が`start_time`より前にならないようにするバリデーション追加）をGitHub上に登録
- `spec/requests/top_spec.rb`へのログイン時カレンダー表示テスト追加
- `docker compose exec web bin/rubocop`・`bundle exec rspec`・`bin/brakeman`の最終確認、コミット整理、PR作成
- ブランチ`feat/issue-35-calendar-ui`で作業中。

### 2026-07-24 実施内容

#### Issue #35: 月間カレンダーUI導入・直近予定一覧表示（残課題対応・完了）

#### 実施手順（Issue #35 続き）

1. `rails g simple_calendar:views`を実行し、gemのデフォルトビュー（`app/views/simple_calendar/_month_calendar.html.erb`等）をアプリ側にコピーして編集可能な状態にした
2. `_month_calendar.html.erb`の日付セル（`<td>`）に`border border-gray-200`を追加し、セルの境界線を明示
3. ブラウザで画面幅を変えて（デスクトップ幅・タブレット幅・スマートフォン幅の3パターン）レイアウト崩れが再現しないことを確認
4. テストデータを3件（同日に複数予定・長いタイトル）登録し、`h-24`のセル内に収まること、長いタイトルが`truncate`で省略表示されることを確認
5. `spec/requests/top_spec.rb`に「ログイン時」の`describe`ブロックを追加（カレンダー見出し表示・直近の予定にタイトルが表示されることの2件）
6. 最終チェック実施（`bin/rubocop`・`bundle exec rspec`・`bin/brakeman`）

#### 発生した事象と対応（Issue #35 続き）

- `border border-gray-200`を追加する前は、境界線が無いことで列の位置関係が視覚的に分かりにくく「崩れて見える」状態だった。境界線を追加したことで、実際には`table-fixed`により列は均等に幅計算されていたことが確認できた。
- テストデータ登録時、長いタイトルの予定を1件追加したところ、「直近の予定」には表示されるのにカレンダー本体からは表示されない事象が**再現**した。原因は前日発見した`end_time`が`start_time`より前になっている同一のバグ（今回は`end_time`が2日前の日時になっていた）。実データで`#80`の必要性を改めて裏付ける結果となった。Railsコンソールで`end_time`を`nil`に更新し解消・表示確認。

#### テスト追加（Issue #35 続き）

- `spec/requests/top_spec.rb`に`describe "GET /index（ログイン時）"`を追加
  - ログイン後、カレンダーの見出し（「教室カレンダー」）が表示されること
  - 「直近の予定」見出しと、`FactoryBot`で用意したスケジュールのタイトルが表示されること
  - `let!`を使い、リクエスト実行前にスケジュールがDBに存在する状態を保証。factoryのデフォルト`start_time`（2026-07-01）は現在時刻より過去のため、「直近の予定」の抽出条件（`start_time >= Time.current`）に該当するよう`1.day.from_now`で上書き

#### 確認結果（Issue #35、完了）

- `docker compose exec web bundle exec rspec spec/requests/top_spec.rb`: 6 examples, 0 failures
- `docker compose exec web bundle exec rubocop`: 50 files inspected, no offenses detected
- `docker compose exec web bundle exec rspec`: 23 examples, 0 failures, 3 pending（既存の無関係スタブ）
- `docker compose exec web bin/brakeman`: Security Warnings 1件（`EOLRails`のみ、CI側で除外設定済みのため実質0件）

#### 補足（Issue #35）

- 作業中に発見したデータ品質の課題（`end_time`が`start_time`より前でも保存できてしまう）は、Issue #80として登録済み。`#35`のスコープ外のため、`#35`完了後に別ブランチで着手する。
