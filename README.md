# Masklet

<p align="center">
  <img src="Resources/Icons/AppIcon.png" alt="Masklet icon" width="160">
</p>

<p align="center">
  <strong>A native macOS clipboard privacy guard for working with AI tools.</strong>
</p>

<p align="center">
  English · <a href="#中文说明">中文说明</a>
</p>

## Overview

Masklet is a native macOS menu bar app that sanitizes clipboard text before it is pasted into AI tools, browsers, chat apps, or other configured targets.

It replaces sensitive values such as IP addresses, tokens, passwords, and internal hosts with stable placeholders like `<IP_A>`, `<TOKEN_A>`, and `<PASSWORD_A>`. When AI-generated commands are copied back from configured apps, Masklet can restore those placeholders to the original values locally.

All processing happens on your Mac. Clipboard content is not uploaded.

## Features

- Native macOS menu bar app built with Swift, SwiftUI, and AppKit.
- Local clipboard monitoring and sanitization.
- Stable reversible aliases for IP addresses and internal hosts, such as `<IP_A>` and `<IP_B>`.
- Reversible placeholders for tokens and passwords, such as `<TOKEN_A>` and `<PASSWORD_A>`.
- Redaction support for password-like fields, bearer tokens, GitHub tokens, AWS access keys, API keys, secrets, and optional email addresses.
- Automatic placeholder restoration when copying commands back from configured target apps.
- Source and target app filtering via Bundle IDs.
- English by default, with Chinese UI available in Settings.
- DMG packaging script for local distribution.

## Example

Copy this:

```text
ssh root@10.2.3.4
password: prod-password
curl http://10.2.3.4:8080/api
Authorization: Bearer abcdefghijklmnopqrstuvwxyz
```

Masklet turns the clipboard into:

```text
ssh root@<IP_A>
password:<PASSWORD_A>
curl http://<IP_A>:8080/api
Authorization: Bearer <TOKEN_A>
```

If an AI tool returns:

```text
curl http://<IP_A>:8080/api -H 'Authorization: Bearer <TOKEN_A>'
```

Masklet can restore it to:

```text
curl http://10.2.3.4:8080/api -H 'Authorization: Bearer abcdefghijklmnopqrstuvwxyz'
```

## Build

Requirements:

- macOS 14 or later
- Xcode Command Line Tools
- Swift 6 compatible toolchain

Run tests:

```sh
env CLANG_MODULE_CACHE_PATH=/private/tmp/masklet-clang-cache SWIFTPM_CACHE_PATH=/private/tmp/masklet-swiftpm-cache swift test
```

Build the app:

```sh
./scripts/build_app.sh
```

The app bundle will be written to:

```text
.build/app/Masklet.app
```

Build a DMG:

```sh
./scripts/package_dmg.sh
```

The DMG will be written to:

```text
dist/Masklet-0.1.0.dmg
```

Build a DMG with a specific version:

```sh
VERSION=1.2.3 ./scripts/package_dmg.sh
```

Build architecture-specific DMGs:

```sh
ARCH=arm64 VERSION=1.2.3 ./scripts/package_dmg.sh     # Apple Silicon
ARCH=x86_64 VERSION=1.2.3 ./scripts/package_dmg.sh    # Intel
```

Outputs:

```text
dist/Masklet-1.2.3-apple-silicon.dmg
dist/Masklet-1.2.3-intel.dmg
```

## Release

This repository includes a GitHub Actions workflow at `.github/workflows/release.yml`.

When a GitHub Release is published, the workflow will:

1. Read the release tag, such as `v1.2.3`.
2. Run the test suite.
3. Build `Masklet.app`.
4. Package both `dist/Masklet-1.2.3-apple-silicon.dmg` and `dist/Masklet-1.2.3-intel.dmg`.
5. Upload both DMGs to the release assets.

Recommended release flow:

```sh
git tag v1.2.3
git push origin v1.2.3
```

Then create and publish a GitHub Release from that tag.

## Install

Open the DMG and drag `Masklet.app` to `Applications`.

This project is not signed or notarized yet. On first launch, macOS may show a security warning. For local testing, right-click the app and choose `Open`.

## Privacy

Masklet is designed to be local-first:

- No clipboard content is sent to a server.
- No analytics or telemetry are included.
- Original values and mappings are kept locally for restoration.
- The app can be paused from the menu bar at any time.

## Current Limitations

macOS pasteboard APIs reliably expose clipboard changes, but they do not reliably expose the original source app or the future paste target. Masklet records the frontmost app at copy time and can filter by configured Bundle IDs.

More precise paste-time detection may require Accessibility permissions, a custom paste shortcut, or browser extension support.

## Roadmap

- Developer ID signing and notarization.
- Launch at login support with `SMAppService`.
- Accessibility-based active window metadata.
- Custom user regex rules.
- Mapping expiration timestamps.
- Settings import/export.

## License

Apache License 2.0. See [LICENSE](LICENSE).

---

## 中文说明

<p align="center">
  <img src="Resources/Icons/AppIcon.png" alt="Masklet 图标" width="160">
</p>

<p align="center">
  <strong>一个用于 AI 工具场景的 macOS 原生剪贴板隐私保护工具。</strong>
</p>

## 简介

Masklet 是一个 macOS 原生菜单栏应用，用于在你把文本粘贴到 AI 工具、浏览器、聊天软件或其他配置目标之前，自动对剪贴板中的敏感信息做本地脱敏。

它会把 IP 地址、Token、密码、内部主机等敏感值替换成稳定占位符，例如 `<IP_A>`、`<TOKEN_A>`、`<PASSWORD_A>`。当你从配置过的 AI 工具或浏览器复制命令回来时，Masklet 可以把这些占位符在本地还原成原始值。

所有处理都在本机完成，不会上传剪贴板内容。

## 功能

- 使用 Swift、SwiftUI、AppKit 构建的 macOS 原生菜单栏应用。
- 本地监听并处理剪贴板文本。
- 将 IP 地址和内部主机替换为稳定可还原占位符，例如 `<IP_A>`、`<IP_B>`。
- 将 Token 和密码替换为可还原占位符，例如 `<TOKEN_A>`、`<PASSWORD_A>`。
- 支持 password 字段、Bearer Token、GitHub Token、AWS Access Key、API Key、Secret，以及可选邮箱脱敏。
- 从配置目标应用复制 AI 返回命令时，支持自动还原占位符。
- 支持通过 Bundle ID 配置来源应用和目标应用。
- 默认英文界面，可在设置中切换中文。
- 提供 DMG 打包脚本，方便本地分发。

## 示例

复制这段文本：

```text
ssh root@10.2.3.4
password: prod-password
curl http://10.2.3.4:8080/api
Authorization: Bearer abcdefghijklmnopqrstuvwxyz
```

Masklet 会将剪贴板替换为：

```text
ssh root@<IP_A>
password:<PASSWORD_A>
curl http://<IP_A>:8080/api
Authorization: Bearer <TOKEN_A>
```

如果 AI 返回：

```text
curl http://<IP_A>:8080/api -H 'Authorization: Bearer <TOKEN_A>'
```

Masklet 可以还原为：

```text
curl http://10.2.3.4:8080/api -H 'Authorization: Bearer abcdefghijklmnopqrstuvwxyz'
```

## 构建

要求：

- macOS 14 或更高版本
- Xcode Command Line Tools
- Swift 6 兼容工具链

运行测试：

```sh
env CLANG_MODULE_CACHE_PATH=/private/tmp/masklet-clang-cache SWIFTPM_CACHE_PATH=/private/tmp/masklet-swiftpm-cache swift test
```

构建 App：

```sh
./scripts/build_app.sh
```

输出路径：

```text
.build/app/Masklet.app
```

构建 DMG：

```sh
./scripts/package_dmg.sh
```

输出路径：

```text
dist/Masklet-0.1.0.dmg
```

指定版本号构建 DMG：

```sh
VERSION=1.2.3 ./scripts/package_dmg.sh
```

分别构建 Apple Silicon 和 Intel DMG：

```sh
ARCH=arm64 VERSION=1.2.3 ./scripts/package_dmg.sh     # Apple Silicon
ARCH=x86_64 VERSION=1.2.3 ./scripts/package_dmg.sh    # Intel
```

输出文件：

```text
dist/Masklet-1.2.3-apple-silicon.dmg
dist/Masklet-1.2.3-intel.dmg
```

## 发版

仓库包含 GitHub Actions workflow：`.github/workflows/release.yml`。

当你发布 GitHub Release 时，workflow 会自动：

1. 读取 release tag，例如 `v1.2.3`。
2. 运行测试。
3. 构建 `Masklet.app`。
4. 分别打包 `dist/Masklet-1.2.3-apple-silicon.dmg` 和 `dist/Masklet-1.2.3-intel.dmg`。
5. 将两个 DMG 上传到该 release 的 assets。

推荐发版流程：

```sh
git tag v1.2.3
git push origin v1.2.3
```

然后在 GitHub 上基于这个 tag 创建并发布 Release。

## 安装

打开 DMG，将 `Masklet.app` 拖入 `Applications`。

当前项目还没有开发者证书签名和 Apple notarization。首次打开时 macOS 可能会提示安全风险。本地测试可以右键应用并选择 `Open`。

## 隐私

Masklet 采用本地优先设计：

- 不会将剪贴板内容发送到服务器。
- 不包含分析或遥测。
- 原始值和映射关系仅保存在本地，用于后续还原。
- 可以随时从菜单栏暂停应用。

## 当前限制

macOS pasteboard API 可以可靠地检测剪贴板变化，但无法可靠地提供“复制来源应用”或“未来粘贴目标”。Masklet 当前会记录复制时的前台应用，并支持通过 Bundle ID 过滤。

更精确的粘贴时检测可能需要 Accessibility 权限、自定义粘贴快捷键，或浏览器扩展支持。

## 路线图

- Developer ID 签名和 notarization。
- 使用 `SMAppService` 支持开机自启。
- 基于 Accessibility 获取活动窗口信息。
- 支持用户自定义正则规则。
- 支持映射关系过期时间。
- 支持设置导入和导出。

## License

Apache License 2.0。详见 [LICENSE](LICENSE)。
