import SwiftUI

@main
struct MemeManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Import from Clipboard") {
                    // This needs to be handled at the view level
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                .disabled(true) // Will be enabled when implemented properly
            }
        }
    }
}