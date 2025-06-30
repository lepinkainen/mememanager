import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            MainView()
        }
        .navigationTitle("🎭 Meme Manager")
    }
}