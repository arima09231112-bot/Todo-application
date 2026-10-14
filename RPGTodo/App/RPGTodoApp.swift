import SwiftUI
import SwiftData

@main
struct RPGTodoApp: App {
    private let container = AppStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
