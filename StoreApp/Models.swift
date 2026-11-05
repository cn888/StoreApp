import Foundation

/// 服务端清单 apps.json 的模型
struct Manifest: Codable {
    var apps: [StoreItem]
    var updated: String?
}

struct StoreItem: Codable, Identifiable {
    var key: String
    var name: String
    var bundleId: String
    var desc: String?
    var icon: String
    var latest: StoreVersion
    var history: [StoreVersion]?

    var id: String { key }
}

struct StoreVersion: Codable, Identifiable {
    var version: String
    var date: String
    var size: Int
    var ipa: String
    var plist: String
    var install: String
    var notes: String?

    var id: String { version + "@" + date }

    var sizeText: String {
        if size > 1_048_576 { return String(format: "%.1f MB", Double(size) / 1_048_576) }
        return "\(max(1, size / 1024)) KB"
    }
}

enum VersionTool {
    /// a > b 返回 1，相等 0，小于 -1
    static func compare(_ a: String, _ b: String) -> Int {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        let n = max(pa.count, pb.count)
        for i in 0..<n {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x > y { return 1 }
            if x < y { return -1 }
        }
        return 0
    }
}
