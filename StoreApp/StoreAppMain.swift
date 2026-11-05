import SwiftUI

@main
struct StoreAppMain: App {
    init() {
        StoreHandshake.report()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { StoreHandshake.report() }
        }
    }
}
