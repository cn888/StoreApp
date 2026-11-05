import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StoreViewModel()
    @State private var showTip = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.043, green: 0.051, blue: 0.071).ignoresSafeArea()
                content
            }
            .navigationTitle("应用市场")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .disabled(vm.loading)
                }
            }
            .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索应用")
            .task { if vm.apps.isEmpty { await vm.load() } }
            .refreshable { await vm.load() }
            .alert("无法打开安装链接", isPresented: $showTip) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("请确认网络正常，且 IPA 与描述文件仍在线。")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if vm.apps.isEmpty && vm.loading {
            loadingView
        } else if vm.apps.isEmpty, let err = vm.errorMessage {
            errorView(err)
        } else {
            listView
        }
    }

    // MARK: - 加载中
    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().scaleEffect(1.2)
            Text("正在获取应用清单…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 出错
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("加载失败")
                .font(.headline)
            Text(msg)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Button("重试") { Task { await vm.load() } }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 列表
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                summaryBar
                ForEach(vm.filtered) { item in
                    AppCard(item: item,
                            title: vm.buttonTitle(item),
                            needsUpdate: vm.needsUpdate(item),
                            isNew: vm.isNew(item),
                            iconURL: vm.iconURL(item)) {
                        install(item)
                    }
                }
                if vm.filtered.isEmpty {
                    Text("没有找到匹配的应用")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
                footer
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var summaryBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 13))
                .foregroundStyle(.green)
            Text(vm.updateCount > 0
                 ? "\(vm.updateCount) 个应用可更新"
                 : "全部已是最新")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
            if !vm.updatedText.isEmpty {
                Text(vm.updatedText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 13))
        .padding(.top, 4)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("下拉刷新 · 点「获取」由系统完成安装")
            Text("同一应用重复安装即为更新，数据保留")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
        .padding(.top, 18)
    }

    // MARK: - 动作
    private func install(_ item: StoreItem) {
        vm.install(item) { ok in
            if !ok { showTip = true }
        }
    }
}

// MARK: - 卡片
struct AppCard: View {
    let item: StoreItem
    let title: String
    let needsUpdate: Bool
    let isNew: Bool
    let iconURL: URL?
    let onTap: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 13) {
                icon
                middle
                Spacer(minLength: 6)
                button
            }
            if expanded {
                notesView
            }
        }
        .padding(13)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.white.opacity(0.06), lineWidth: 0.6))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        }
    }

    private var icon: some View {
        AsyncImage(url: iconURL) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            default:
                ZStack {
                    LinearGradient(colors: [Color(red: 0.42, green: 0.24, blue: 0.79),
                                            Color(red: 0.17, green: 0.53, blue: 0.94)],
                                   startPoint: .top, endPoint: .bottom)
                    Image(systemName: "app.fill").foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.09), lineWidth: 0.6))
    }

    private var middle: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                if needsUpdate {
                    tag("可更新", .green)
                } else if isNew {
                    tag("NEW", .blue)
                }
            }
            Text(item.desc ?? "")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("v\(item.latest.version) · \(item.latest.sizeText) · \(item.latest.date)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    private func tag(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold))
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 5))
            .foregroundStyle(color)
    }

    private var button: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .frame(minWidth: 62)
                .padding(.vertical, 7)
                .padding(.horizontal, 12)
                .background(buttonColor, in: Capsule())
                .foregroundStyle(buttonTextColor)
        }
        .buttonStyle(.plain)
    }

    private var buttonColor: Color {
        if needsUpdate { return Color(red: 0.13, green: 0.77, blue: 0.37) }
        if title.hasPrefix("已装") { return Color.white.opacity(0.1) }
        return Color(red: 0.04, green: 0.52, blue: 1.0)
    }

    private var buttonTextColor: Color {
        title.hasPrefix("已装") ? Color.secondary : .white
    }

    private var notesView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().overlay(Color.white.opacity(0.08))
            Text("更新说明")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(item.latest.notes?.isEmpty == false ? (item.latest.notes ?? "") : "—")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let hist = item.history, !hist.isEmpty {
                Text("历史版本：" + hist.map { "v" + $0.version }.joined(separator: "、"))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 10)
    }
}

#Preview {
    ContentView()
}
