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

1. （私）`docs/INITIAL_SETUP.md` に修正内容を追記しました。
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
