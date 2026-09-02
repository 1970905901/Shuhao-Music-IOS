# QQMusicClient

支持 iOS 15.0+ 的第三方 QQ 音乐客户端 Swift Package。

## 功能清单

- [x] 歌曲搜索
- [x] 歌单浏览与详情
- [x] 专辑详情
- [x] 歌手详情
- [x] 音频播放（AVPlayer + 后台播放 + 锁屏控制）
- [x] 播放队列与上一曲/下一曲/自动切歌
- [x] 歌词解析与高亮滚动
- [x] 播放历史（本地持久化）
- [x] 我的收藏（本地持久化）
- [x] iPhone / iPad 双栏适配

## 使用方式

### 方案 A：作为本地 Swift Package 引入（推荐）

1. 在 Xcode 中新建 **iOS App** 项目：
   - Interface: SwiftUI
   - Language: Swift
   - Deployment Target: iOS 15.0
2. 将 `QQMusicClient` 文件夹拖拽到项目根目录，作为本地 Swift Package 引用。
3. 在主 Target 的 `Info.plist` 中添加后台音频模式（见 `Resources/Info.plist` 模板）。
4. 将 `AppTemplate/QQMusicClientApp.swift` 复制到主项目，并加入主 Target。
5. 确保主 Target 依赖了 `QQMusicClient` Package。

### 方案 B：直接复制源码

1. 新建 iOS App 项目。
2. 将 `Sources/QQMusicClient` 下所有文件复制到主项目。
3. 复制 `AppTemplate/QQMusicClientApp.swift` 到主项目。
4. 配置 `Info.plist` 后台音频模式。

## 目录说明

- `Sources/QQMusicClient/Models/`：QQ 音乐 API 数据模型、歌词模型、历史记录模型
- `Sources/QQMusicClient/Services/`：网络请求、音频播放、历史/收藏本地存储
- `Sources/QQMusicClient/ViewModels/`：基于 `ObservableObject` 的状态管理
- `Sources/QQMusicClient/Views/`：SwiftUI 视图
- `Sources/QQMusicClient/Utils/`：常量与音频会话配置
- `AppTemplate/`：宿主 App 入口模板（含 `@main`）
- `Resources/`：`Info.plist` 等配置模板

## 注意事项

- 本项目不使用任何 iOS 16/17+ 独占 API。
- 网络请求基于 `URLSession` + `async/await`。
- 音频播放基于 `AVPlayer` + `MPRemoteCommandCenter`。
- QQ 音乐 API 参数可能随官方调整而变化，实际联调时需检查 Cookie / guid / g_tk 等。
