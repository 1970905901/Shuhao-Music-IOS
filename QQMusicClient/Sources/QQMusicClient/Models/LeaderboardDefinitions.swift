import Foundation

/// 各平台热门排行榜（参考项目 leaderboard.js 硬编码，取常用榜单）
extension Playlist {
    static let qqLeaderboards: [Playlist] = [
        Playlist(id: "tx__4", name: "流行指数榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__26", name: "热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__27", name: "新歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__62", name: "飙升榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__58", name: "说唱榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__57", name: "喜力电音榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__28", name: "网络歌曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__5", name: "内地榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__3", name: "欧美榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__59", name: "香港地区榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__16", name: "韩国榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__29", name: "影视金曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__17", name: "日本榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "tx__52", name: "腾讯音乐人原创榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
    ]

    static let kugouLeaderboards: [Playlist] = [
        Playlist(id: "kg__8888", name: "TOP500", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__6666", name: "飙升榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__52144", name: "抖音热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__52767", name: "快手热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__24971", name: "DJ热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__23784", name: "网络红歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__31308", name: "内地榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__31313", name: "香港地区榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__54848", name: "台湾地区榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__31310", name: "欧美榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__31311", name: "韩国榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__31312", name: "日本榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__33161", name: "古风新歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kg__33165", name: "粤语金曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
    ]

    static let kuwoLeaderboards: [Playlist] = [
        Playlist(id: "kw__93", name: "飙升榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__17", name: "新歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__16", name: "热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__158", name: "抖音热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__104", name: "华语榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__182", name: "粤语榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__22", name: "欧美榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__184", name: "韩语榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__183", name: "日语榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__26", name: "经典怀旧榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__64", name: "影视金曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__176", name: "DJ嗨歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "kw__12", name: "Billboard榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
    ]

    static let neteaseLeaderboards: [Playlist] = [
        Playlist(id: "wy__19723756", name: "飙升榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__3779629", name: "新歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__3778678", name: "热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__2884035", name: "原创榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__991319590", name: "说唱榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__71384707", name: "古典榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__1978921795", name: "电音榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__71385702", name: "ACG榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__745956260", name: "韩语榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__10520166", name: "国电榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__21845217", name: "KTV唛榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__60131", name: "日本Oricon榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__180106", name: "UK排行榜周榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        Playlist(id: "wy__60198", name: "美国Billboard榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
    ]
}
