import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var viewModel: MemeManagerViewModel
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(viewModel)
        } detail: {
            MainView()
                .environmentObject(viewModel)
        }
        .navigationTitle("🎭 Meme Manager")
        .onDrop(of: [UTType.image], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Success", isPresented: $viewModel.showingSuccess) {
            Button("OK") { }
        } message: {
            Text(viewModel.successMessage ?? "Operation completed successfully")
        }
        .focusable()
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { object, error in
                    if let url = object {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                viewModel.importImages(from: urls)
            }
        }
        
        return !providers.isEmpty
    }
}