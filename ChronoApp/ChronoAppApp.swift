import SwiftUI

@main
struct ChronoAppApp: App {
    @StateObject private var windowController = WindowController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    windowController.setupWindow()
                }
        }
    }
}

class WindowController: ObservableObject {
    var window: NSWindow?

    func setupWindow() {
        if let window = NSApplication.shared.windows.first {
            self.window = window
            // Set the window to always stay on top
            window.level = .floating
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]  // Full-screen support
        }
    }
}

