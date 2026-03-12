.PHONY: build build-go build-app generate clean

# Go バイナリのみビルド
build-go:
	go build -o bin/ghn ./cmd/ghn/

# Xcode プロジェクト生成
generate:
	xcodegen generate

# Swift アプリビルド（Go バイナリも含む）
build-app: build-go generate
	xcodebuild -project GHNApp.xcodeproj -scheme GHNApp -configuration Release build

# デフォルト: 全部ビルド
build: build-app

clean:
	rm -rf bin/ build/
	xcodebuild -project GHNApp.xcodeproj -scheme GHNApp clean 2>/dev/null || true
