// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "QQMusicClient",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "QQMusicClient", targets: ["QQMusicClient"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "QQMusicClient", dependencies: ["CCommonCrypto"]),
        .systemLibrary(name: "CCommonCrypto", path: "Sources/CCommonCrypto"),
    ]
)
