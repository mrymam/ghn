# ghn (GitHub Notifications)

macOS のメニューバーで GitHub のレビューリクエストをポーリングし、新着を通知するアプリです。

## 主な機能

- メニューバー常駐 + 未読バッジ
- レビューリクエストされた PR の一覧表示
- 新しいレビューリクエストの macOS 通知
- PR クリックでブラウザを開く
- ポーリング間隔・Organization の設定 UI

## 技術構成

- **Go**: ポーリング + 差分検出 + NDJSON 出力（[ghv/pkg/github](https://github.com/mrymam/ghv) を利用）
- **Swift / SwiftUI**: メニューバー UI（`MenuBarExtra`）

## 前提条件

- macOS 13+
- Xcode 15+
- Go 1.21+
- `gh auth login` 済み

## インストール

### macOS アプリ

```bash
git clone https://github.com/mrymam/ghn.git
cd ghn
make build-app
```

ビルド後、`build/Release/GHN.app` を `/Applications/` にコピー。

### CLI のみ

```bash
git clone https://github.com/mrymam/ghn.git
cd ghn
make build-go
cp bin/ghn /usr/local/bin/
```

## ビルド

```bash
# Go バイナリのみ
make build-go

# Swift アプリ（Go バイナリ同梱）
make build-app
```

## 設定

`~/.config/ghn/config.json` またはアプリの Settings から設定可能。

```json
{
  "org": "mycompany",
  "polling": "3m"
}
```
