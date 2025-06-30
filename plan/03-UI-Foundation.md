# Phase 3: UI Foundation & Basic Views

## Overview
Build the core SwiftUI interface structure, replicating the layout and functionality of the Python CustomTkinter implementation.

## Prerequisites
- [ ] Phase 2 (Core Architecture) completed
- [ ] All services properly implemented and tested
- [ ] Understanding of Python UI layout from `main_window.py`

## Step 1: Main App Structure

### Update MemeManagerApp.swift:
```swift
import SwiftUI

@main
struct MemeManagerApp: App {
    @StateObject private var serviceManager: ServiceManager
    
    init() {
        do {
            let services = try ServiceManager()
            _serviceManager = StateObject(wrappedValue: services)
        } catch {
            fatalError("Failed to initialize services: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowResizability(.contentSize)
        .commands {
            ImportCommands()
        }
    }
}
```

### Step 1 Checklist:
- [ ] Update app to inject service manager
- [ ] Set minimum window size matching Python app (1200x800)
- [ ] Add menu bar commands for import operations
- [ ] Configure window resizing behavior
- [ ] Test app launches with services properly injected

## Step 2: Main Navigation Structure

### ContentView.swift - Main Layout:
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceManager: ServiceManager
    @StateObject private var mainViewModel = MainViewModel()
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView()
                .frame(minWidth: 250, idealWidth: 300)
                .environmentObject(mainViewModel)
        } detail: {
            MainContentView()
                .environmentObject(mainViewModel)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Import") {
                    mainViewModel.showImportSheet = true
                }
            }
        }
        .sheet(isPresented: $mainViewModel.showImportSheet) {
            ImportView()
                .environmentObject(mainViewModel)
        }
    }
}
```

### Step 2 Checklist:
- [ ] Create main navigation split view (sidebar + detail)
- [ ] Set up proper view model injection
- [ ] Add toolbar with import button
- [ ] Configure sheet presentation for import dialog
- [ ] Test navigation structure displays correctly

## Step 3: Sidebar Implementation

### SidebarView.swift - Left Panel:
```swift
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Text("🎭 Meme Manager")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Statistics
                StatisticsView()
            }
            .padding()
            
            Divider()
            
            // Import Section
            ImportSectionView()
                .padding(.horizontal)
            
            Divider()
            
            // Search Section
            SearchSectionView()
                .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ImportSectionView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Import Images")
                .font(.headline)
            
            Button("📁 Select Files") {
                mainViewModel.showFileImporter = true
            }
            .buttonStyle(.bordered)
            
            Button("📋 Paste from Clipboard") {
                mainViewModel.pasteFromClipboard()
            }
            .buttonStyle(.bordered)
        }
    }
}

struct SearchSectionView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search & Filter")
                .font(.headline)
            
            SearchField(text: $mainViewModel.searchText)
                .textFieldStyle(.roundedBorder)
            
            Button("Clear") {
                mainViewModel.searchText = ""
            }
            .buttonStyle(.bordered)
            .disabled(mainViewModel.searchText.isEmpty)
        }
    }
}
```

### Step 3 Checklist:
- [ ] Create `SidebarView` with proper sections
- [ ] Implement import buttons (file dialog + clipboard)
- [ ] Add search field with real-time filtering
- [ ] Create statistics display section
- [ ] Match Python app's sidebar layout and functionality
- [ ] Test all sidebar interactions

## Step 4: Main Content Area

### MainContentView.swift - Right Panel:
```swift
import SwiftUI

struct MainContentView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if mainViewModel.images.isEmpty {
                EmptyStateView()
            } else {
                ImageGridView()
            }
            
            StatusBarView()
                .frame(height: 30)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No images found")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Import some memes to get started!")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatusBarView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        HStack {
            Text(mainViewModel.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if mainViewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
```

### Step 4 Checklist:
- [ ] Create main content view with conditional display
- [ ] Implement empty state view matching Python app
- [ ] Add status bar with loading indicator
- [ ] Create proper layout structure for image grid
- [ ] Test empty state and loading states

## Step 5: View Models

### MainViewModel.swift - Core State Management:
```swift
import SwiftUI
import Combine

@MainActor
class MainViewModel: ObservableObject {
    @Published var images: [MemeImage] = []
    @Published var searchText: String = ""
    @Published var statusMessage: String = "Ready"
    @Published var isLoading: Bool = false
    @Published var showImportSheet: Bool = false
    @Published var showFileImporter: Bool = false
    @Published var selectedImage: MemeImage?
    
    private var cancellables = Set<AnyCancellable>()
    private var serviceManager: ServiceManager?
    
    init() {
        setupSearchBinding()
    }
    
    func configure(with serviceManager: ServiceManager) {
        self.serviceManager = serviceManager
        loadImages()
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    // Core operations
    func loadImages() { }
    func performSearch(query: String) { }
    func importImages(from urls: [URL]) { }
    func pasteFromClipboard() { }
    func deleteImage(_ image: MemeImage) { }
    func updateImageTags(_ image: MemeImage, tags: [Tag]) { }
    
    // Status management
    func updateStatus(_ message: String) { }
    func setLoading(_ loading: Bool) { }
}
```

### Step 5 Checklist:
- [ ] Create `MainViewModel` with all required published properties
- [ ] Implement search debouncing for performance
- [ ] Add proper async/await handling for database operations
- [ ] Create methods for all core operations
- [ ] Add proper error handling and user feedback
- [ ] Test view model state management

## Step 6: Image Grid Foundation

### ImageGridView.swift - Thumbnail Display:
```swift
import SwiftUI

struct ImageGridView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 10)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(mainViewModel.images) { image in
                    ImageThumbnailView(image: image)
                        .onTapGesture {
                            mainViewModel.selectedImage = image
                        }
                }
            }
            .padding()
        }
    }
}

struct ImageThumbnailView: View {
    let image: MemeImage
    @State private var thumbnailImage: NSImage?
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail image
            Group {
                if let thumbnailImage = thumbnailImage {
                    Image(nsImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            
            // Image name
            Text(image.displayName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 150)
            
            // Tags preview
            if !image.tags.isEmpty {
                TagsPreviewView(tags: Array(image.tags.prefix(2)))
            }
        }
        .frame(width: 170)
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        // Load thumbnail asynchronously
    }
}
```

### Step 6 Checklist:
- [ ] Create `ImageGridView` with adaptive grid layout
- [ ] Implement `ImageThumbnailView` with proper image loading
- [ ] Add async thumbnail loading with loading states
- [ ] Create tags preview component
- [ ] Add proper error handling for image loading
- [ ] Test grid layout and thumbnail display

## Step 7: File Import Integration

### ImportView.swift - File Selection:
```swift
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Images")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                Button("Select Files") {
                    // Show file picker
                }
                .buttonStyle(.borderedProminent)
                
                Button("Paste from Clipboard") {
                    mainViewModel.pasteFromClipboard()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 200)
        .fileImporter(
            isPresented: $mainViewModel.showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        // Handle file import result
    }
}
```

### Step 7 Checklist:
- [ ] Create `ImportView` with file picker integration
- [ ] Implement file importer with proper UTType filtering
- [ ] Add clipboard import functionality
- [ ] Handle multiple file selection
- [ ] Add proper error handling and user feedback
- [ ] Test import workflows

## Step 8: Integration & Testing

### Connect all components:
- [ ] Ensure service manager is properly injected throughout view hierarchy
- [ ] Connect view models to services
- [ ] Test data flow from services to UI
- [ ] Verify search functionality works end-to-end
- [ ] Test import workflows with actual image files

### UI Testing:
- [ ] Test window resizing behavior
- [ ] Verify sidebar and main content layout
- [ ] Test empty state and loading states
- [ ] Validate image grid layout with various screen sizes
- [ ] Test keyboard shortcuts and menu items

### Step 8 Checklist:
- [ ] All views properly connected to view models
- [ ] Service integration working correctly
- [ ] UI responds to data changes
- [ ] Search functionality works in real-time
- [ ] Import workflows complete successfully
- [ ] Error states are properly handled and displayed

## Validation Checklist
- [ ] ✅ Main app structure matches Python implementation layout
- [ ] ✅ Sidebar contains all required sections and functionality
- [ ] ✅ Main content area displays images or empty state appropriately
- [ ] ✅ Search functionality works with real-time filtering
- [ ] ✅ Import workflows (file picker + clipboard) are functional
- [ ] ✅ Status bar provides appropriate user feedback
- [ ] ✅ View models properly manage state and data flow

## Common Issues & Solutions
- **View not updating**: Check @Published properties and ObservableObject conformance
- **Image loading issues**: Verify file URLs and image processing service integration
- **Navigation problems**: Check environment object injection and view hierarchy
- **Performance issues**: Implement lazy loading and proper view recycling
- **Layout issues**: Test with various window sizes and content amounts

## Next Steps
Once this phase is complete, proceed to **04-Image-Management.md** for implementing full image processing and management features.

---
**Estimated Time**: 2-3 days for complete UI foundation implementation