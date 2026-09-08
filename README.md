# `stagit` for GitHub

GitHub の重厚な Web UI をバイパスし、個人の全 Git リポジトリを完全静的な HTML ポータルとして自動統合・配信するシステムです。

すべての所有リポジトリ（パブリック / プライベート）を単一のインデックス配下に集約し、ポータル全体を最小限のオーバーヘッドで(Cloudflare Pagesから)配信します。
なお、リポジトリにクルデンシャルを放流したことがある人は使うことができないものです。

## 特徴

* 超軽量な静的サイト: `stagit`（Oxalorg フォーク）を用いて、シンプルで高速な Web UI を生成。
* 完全自動同期(WIP): 各リポジトリへの `git push` をフック（Webhook / `repository_dispatch`）し、GitHub Actions 上で全自動ビルド・デプロイを完結。
* 強固なアクセス制御: 成果物を Cloudflare Pages にデプロイし、Cloudflare Access（Zero Trust）を被せることで非公開コードや研究資産の漏洩を防止。
* 巨大差分の自動安全保護: 25 MiB を超えるような巨大な diff / ログページをビルド時に自動検知・サニタイズし、CI/CD パイプラインとデプロイの安定性を確保。(手書きSVGファイルをGitHubにあげた私のせいで作られたセーフティネットです)

## アーキテクチャ

```text
[ Any Repo ] --( git push )--> [ Webhook / repository_dispatch ]
                                          │
                                          ▼
                              [ Portal Repo (Actions) ]
                                          │
                           1. gh CLI で全 bare repo を取得
                           2. stagit / stagit-index をビルド＆実行
                           3. 巨大 HTML ファイルのサニタイズ（粛清）
                           4. gh-pages ブランチへ Force Push
                                          │
                                          ▼
                                 [ Cloudflare Pages ]
                                          │
                                [ Cloudflare Access ]
                                          │
                                          ▼
                                   [ User Terminal ]

```

## セットアップ & 設定

### 1. 必須 Secrets

本リポジトリの **Settings > Secrets and variables > Actions** に以下を登録する。

* `PORTAL_PAT`: 全リポジトリの `git clone --bare` 権限およびポータルへの参照権限を持つ Personal Access Token（`repo` スコープ必須）。

### 2. リポジトリ側の自動同期設定

各個別のリポジトリで `git push` が発生した際、本ポータルの `repository_dispatch` イベント（`type: repo_pushed`）をキックする Webhook / タスクを登録しておく。

### 3. デプロイ先（Cloudflare Pages）

1. Cloudflare Pages で本リポジトリを連携。
2. ビルドブランチを **`gh-pages`** に指定（Build command: `ls` / Build output directory: `/`）。
3. (お好みで)Cloudflare Access ポリシーを設定し、ポータル全体にログイン認証を適用する。

---

必要に応じて、リポジトリ構成や運用ルールに合わせて適宜調整して使用してください。
間違っても、クルデンシャルなんて流してしまわないように。
ちなみに過去に一度でもやらかしてると、そのcommitを拾って公開してくるシステムです。
後悔はしてるんだから、公開はしてほしくないですよね。全てはやらかした自分の責任ということで(3敗)

