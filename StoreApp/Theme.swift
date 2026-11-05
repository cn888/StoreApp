import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 自适应浅色 / 深色的配色（全部走 UIColor 动态颜色，跟系统外观实时切换）
enum Theme {
    static let bg        = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 1)
            : UIColor(red: 0.949, green: 0.953, blue: 0.965, alpha: 1)
    })
    static let card      = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.055)
            : UIColor(white: 1.0, alpha: 1.0)
    })
    static let cardLine  = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.06)
            : UIColor(white: 0.0, alpha: 0.06)
    })
    static let bar       = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.05)
            : UIColor(white: 1.0, alpha: 0.9)
    })
    static let installedBtn = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.10)
            : UIColor(white: 0.0, alpha: 0.06)
    })
    static let installedText = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.62, alpha: 1)
            : UIColor(white: 0.35, alpha: 1)
    })
    static let iconPlaceholder1 = Color(red: 0.42, green: 0.24, blue: 0.79)
    static let iconPlaceholder2 = Color(red: 0.17, green: 0.53, blue: 0.94)

    static let accent = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let update = Color(red: 0.13, green: 0.77, blue: 0.37)
}
