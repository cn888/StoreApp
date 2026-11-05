import Foundation
import SwiftUI
import UIKit

@MainActor
final class StoreViewModel: ObservableObject {

    /// 清单地址（改这里就能换数据源）
    static let manifestURL = "https://www.airobotbox.com/store/apps.json"
    static let baseURL = "https://www.airobotbox.com/store/"

    @Published var apps: [StoreItem] = []
    @Published var updatedText: String = ""
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var query: String = ""
    @Published var lastRefresh = Date()

    private let instKey = "store.installed"

    /// key -> 已装版本（真实探测结果优先，本地点击记录兜底）
    @Published private(set) var installed: [String: String] = [:]
    /// key -> 是否已安装（canOpenURL 或钥匙串有记录）
    @Published private(set) var presence: [String: Bool] = [:]
    /// 已装但拿不到版本（App 从未启动过）
    @Published private(set) var versionUnknown: Set<String> = []

    init() {
        loadInstalled()
    }

    private func loadInstalled() {
        installed = UserDefaults.standard.dictionary(forKey: instKey) as? [String: String] ?? [:]
    }

    private func markInstalled(_ key: String, _ version: String) {
        installed[key] = version
        UserDefaults.standard.set(installed, forKey: instKey)
    }

    /// 重新探测所有 App 的安装状态与版本
    @MainActor
    func refreshInstallState() {
        let fromKeychain = InstallProbe.versionMap()
        var pres: [String: Bool] = [:]
        var vers: [String: String] = [:]
        var unknown = Set<String>()

        for item in apps {
            let kv = fromKeychain[item.bundleId]
            let openable = InstallProbe.isInstalled(scheme: item.urlScheme)
            let isThere = openable || (kv != nil)
            pres[item.key] = isThere
            if let kv {
                vers[item.key] = kv
            } else if isThere {
                if let mine = installed[item.key] { vers[item.key] = mine }
                else { unknown.insert(item.key) }
            }
        }
        presence = pres
        installed = vers
        versionUnknown = unknown
    }

    // MARK: - 拉清单
    func load() async {
        loading = true
        errorMessage = nil
        defer { loading = false }

        guard let url = URL(string: Self.manifestURL) else { return }
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        req.timeoutInterval = 15

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                throw NSError(domain: "store", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "服务器返回 \(http.statusCode)"])
            }
            let m = try JSONDecoder().decode(Manifest.self, from: data)
            apps = m.apps.sorted { a, b in
                (b.latest.date).compare(a.latest.date) == .orderedAscending
            }
            updatedText = m.updated ?? ""
            lastRefresh = Date()
            await refreshInstallState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 显示用
    var filtered: [StoreItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return apps }
        return apps.filter {
            $0.name.lowercased().contains(q) || ($0.desc ?? "").lowercased().contains(q)
        }
    }

    var updateCount: Int {
        apps.filter { needsUpdate($0) }.count
    }

    func needsUpdate(_ item: StoreItem) -> Bool {
        guard presence[item.key] == true, let mine = installed[item.key] else { return false }
        return VersionTool.compare(item.latest.version, mine) > 0
    }

    func isInstalled(_ item: StoreItem) -> Bool {
        presence[item.key] == true
    }

    /// 已装版本（nil = 未装或版本未知）
    func installedVersion(_ item: StoreItem) -> String? {
        installed[item.key]
    }

    func isVersionUnknown(_ item: StoreItem) -> Bool {
        versionUnknown.contains(item.key)
    }

    func buttonTitle(_ item: StoreItem) -> String {
        guard presence[item.key] == true else { return "获取" }
        if let mine = installed[item.key] {
            if VersionTool.compare(item.latest.version, mine) > 0 { return "更新" }
            return "已装 \(mine)"
        }
        return "已装"
    }

    /// 打开目标 App，促使其上报版本
    @MainActor
    func openApp(_ item: StoreItem, completion: @escaping (Bool) -> Void) {
        InstallProbe.open(scheme: item.urlScheme) { ok in
            completion(ok)
        }
    }

    func iconURL(_ item: StoreItem) -> URL? {
        if item.icon.hasPrefix("http") { return URL(string: item.icon) }
        return URL(string: Self.baseURL + item.icon)
    }

    /// 是不是 3 天内上架的（显示 NEW）
    func isNew(_ item: StoreItem) -> Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: item.latest.date) else { return false }
        return Date().timeIntervalSince(d) < 3 * 86400
    }

    // MARK: - 安装 / 更新
    func install(_ item: StoreItem, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: item.latest.install) else {
            completion(false)
            return
        }
        UIApplication.shared.open(url, options: [:]) { ok in
            if ok {
                self.markInstalled(item.key, item.latest.version)
            }
            completion(ok)
        }
    }
}
