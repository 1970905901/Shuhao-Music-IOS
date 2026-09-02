# Shuhao Music

第三方 QQ 音乐 iOS 客户端。

- 应用名：Shuhao Music
- Bundle ID：`shuhaomusic.com`
- 版本号：随构建日期更新（如 `20260902`）

## 构建

本仓库使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成 Xcode 工程，并通过 GitHub Actions 构建未签名 IPA。

推送或手动触发 Actions 后，可在 Artifacts 中下载未签名 IPA。

## 本地开发

```bash
brew install xcodegen
xcodegen generate
open ShuhaoMusic.xcodeproj
```

> 需要 macOS + Xcode 15+ 才能本地开发；Windows 用户可直接通过 GitHub Actions 获取构建产物。
