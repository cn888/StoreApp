import Foundation
import UIKit

/// 探测「已安装」与「已装版本」。
///
/// iOS 沙盒不允许枚举已安装 App，所以用两条互补的证据：
///   1. canOpenURL(scheme) —— 能判断装没装（版本未知）
///   2. 共享钥匙串 —— 目标 App 启动时上报过版本，就能拿到精确版本
struct InstallProbe {

    /// bundleId -> 版本（来自共享钥匙串）
    static func versionMap() -> [String: String] {
        StoreHandshake.readAll()
    }

    /// scheme 是否可打开（= 该 App 已安装）
    /// 注意：只有 Info.plist 的 LSApplicationQueriesSchemes 里列过的 scheme 才有效
    @MainActor
    static func isInstalled(scheme: String) -> Bool {
        guard !scheme.isEmpty, let url = URL(string: "\(scheme)://probe") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// 打开目标 App（让用户点一下，App 启动后会写版本，商店就能识别版本）
    @MainActor
    static func open(scheme: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(scheme)://open") else {
            completion(false)
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }
}
