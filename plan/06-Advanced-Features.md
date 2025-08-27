# Phase 6: Advanced Features & Polish

## Overview

Implement advanced features including keyboard shortcuts, menu integration, preferences, and system-level integrations that make the app feel native to macOS.

## Prerequisites

- [ ] Phase 5 (Search & Tagging) completed
- [ ] Core functionality working properly
- [ ] UI and data layers stable
- [ ] Search and tag management functional

## Step 1: Menu Bar Integration

### Create MenuCommands.swift:

```swift
import SwiftUI

struct ImportCommands: Commands {
    var body: some Commands {
        CommandMenu("Import") {
            Button("Select Files...") {
                NotificationCenter.default.post(name: .importFilesRequested, object: nil)
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Paste from Clipboard") {
                NotificationCenter.default.post(name: .pasteFromClipboardRequested, object: nil)
            }
            .keyboardShortcut("v", modifiers: .command)

            Divider()

            Button("Import from URL...") {
                NotificationCenter.default.post(name: .importFromURLRequested, object: nil)
            }
            .keyboardShortcut("u", modifiers: [.command, .shift])
        }

        CommandMenu("Edit") {
            Button("Find...") {
                NotificationCenter.default.post(name: .focusSearchRequested, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Button("Select All") {
                NotificationCenter.default.post(name: .selectAllRequested, object: nil)
            }
            .keyboardShortcut("a", modifiers: .command)

            Divider()

            Button("Copy Selected") {
                NotificationCenter.default.post(name: .copySelectedRequested, object: nil)
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Delete Selected") {
                NotificationCenter.default.post(name: .deleteSelectedRequested, object: nil)
            }
            .keyboardShortcut(.delete)
        }

        CommandMenu("View") {
            Button("Refresh") {
                NotificationCenter.default.post(name: .refreshRequested, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Show Tag Manager") {
                NotificationCenter.default.post(name: .showTagManagerRequested, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            Button("Preferences...") {
                NotificationCenter.default.post(name: .showPreferencesRequested, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

// Notification names
extension Notification.Name {
    static let importFilesRequested = Notification.Name("importFilesRequested")
    static let pasteFromClipboardRequested = Notification.Name("pasteFromClipboardRequested")
    static let importFromURLRequested = Notification.Name("importFromURLRequested")
    static let focusSearchRequested = Notification.Name("focusSearchRequested")
    static let selectAllRequested = Notification.Name("selectAllRequested")
    static let copySelectedRequested = Notification.Name("copySelectedRequested")
    static let deleteSelectedRequested = Notification.Name("deleteSelectedRequested")
    static let refreshRequested = Notification.Name("refreshRequested")
    static let showTagManagerRequested = Notification.Name("showTagManagerRequested")
    static let showPreferencesRequested = Notification.Name("showPreferencesRequested")
}
```

### Step 1 Checklist:

- [ ] Create comprehensive menu commands
- [ ] Add keyboard shortcuts for all major actions
- [ ] Implement notification-based command handling
- [ ] Test all menu items and shortcuts
- [ ] Ensure shortcuts don't conflict with system shortcuts

## Step 2: Keyboard Shortcuts & Global Actions

### KeyboardShortcutHandler.swift:

```swift
import SwiftUI
import Carbon

class KeyboardShortcutHandler: ObservableObject {
    private var mainViewModel: MainViewModel?
    private var searchViewModel: SearchViewModel?

    init() {
        setupNotificationObservers()
    }

    func configure(mainViewModel: MainViewModel, searchViewModel: SearchViewModel) {
        self.mainViewModel = mainViewModel
        self.searchViewModel = searchViewModel
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .importFilesRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleImportFiles()
        }

        NotificationCenter.default.addObserver(
            forName: .pasteFromClipboardRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePasteFromClipboard()
        }

        NotificationCenter.default.addObserver(
            forName: .focusSearchRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleFocusSearch()
        }

        NotificationCenter.default.addObserver(
            forName: .copySelectedRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleCopySelected()
        }

        NotificationCenter.default.addObserver(
            forName: .deleteSelectedRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDeleteSelected()
        }

        NotificationCenter.default.addObserver(
            forName: .refreshRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleRefresh()
        }
    }

    // MARK: - Action Handlers
    private func handleImportFiles() {
        mainViewModel?.showFileImporter = true
    }

    private func handlePasteFromClipboard() {
        mainViewModel?.pasteFromClipboard()
    }

    private func handleFocusSearch() {
        // Focus search field - implementation depends on UI structure
        NotificationCenter.default.post(name: .focusSearchField, object: nil)
    }

    private func handleCopySelected() {
        guard let selectedImage = mainViewModel?.selectedImage else { return }
        mainViewModel?.copyImageToClipboard(selectedImage)
    }

    private func handleDeleteSelected() {
        guard let selectedImage = mainViewModel?.selectedImage else { return }
        mainViewModel?.showDeleteConfirmation(for: selectedImage)
    }

    private func handleRefresh() {
        mainViewModel?.loadImages()
    }
}

extension Notification.Name {
    static let focusSearchField = Notification.Name("focusSearchField")
}
```

### Enhanced SearchSectionView with focus handling:

```swift
struct SearchSectionView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var serviceManager: ServiceManager
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // ... existing search UI ...

            TextField("Search memes...", text: $searchViewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .focused($isSearchFocused)
                .onReceive(NotificationCenter.default.publisher(for: .focusSearchField)) { _ in
                    isSearchFocused = true
                }
        }
        // ... rest of the view ...
    }
}
```

### Step 2 Checklist:

- [ ] Create keyboard shortcut handler with notification system
- [ ] Implement all major keyboard shortcuts
- [ ] Add focus management for search field
- [ ] Test shortcuts work from any part of the app
- [ ] Add visual feedback for shortcut actions

## Step 3: Preferences System

### PreferencesView.swift - Settings Panel:

```swift
import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferences = AppPreferences()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            GeneralPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ImportPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

            StoragePreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Label("Storage", systemImage: "externaldrive")
                }

            AdvancedPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $preferences.appearance) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
                .pickerStyle(.segmented)

                Toggle("Show thumbnails in grid", isOn: $preferences.showThumbnails)

                Stepper("Grid columns: \(preferences.gridColumns)",
                       value: $preferences.gridColumns,
                       in: 2...8)
            }

            Section("Search") {
                Toggle("Real-time search", isOn: $preferences.realtimeSearch)

                Toggle("Search in file names", isOn: $preferences.searchInFilenames)

                Toggle("Search in tags", isOn: $preferences.searchInTags)

                Stepper("Max recent searches: \(preferences.maxRecentSearches)",
                       value: $preferences.maxRecentSearches,
                       in: 5...50)
            }
        }
        .padding()
    }
}

struct ImportPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    @State private var showingStorageLocationPicker = false

    var body: some View {
        Form {
            Section("Import Behavior") {
                Toggle("Auto-organize by date", isOn: $preferences.autoOrganizeByDate)

                Toggle("Generate thumbnails immediately", isOn: $preferences.generateThumbnailsImmediately)

                Toggle("Optimize large images", isOn: $preferences.optimizeLargeImages)

                Picker("Duplicate handling", selection: $preferences.duplicateHandling) {
                    Text("Ask each time").tag(DuplicateHandling.ask)
                    Text("Skip duplicates").tag(DuplicateHandling.skip)
                    Text("Import anyway").tag(DuplicateHandling.import)
                }
            }

            Section("Default Tags") {
                VStack(alignment: .leading) {
                    Text("Add these tags to all imported images:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TagListEditor(tags: $preferences.defaultTags)
                }
            }
        }
        .padding()
    }
}

struct StoragePreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    @State private var storageInfo: StorageInfo?

    var body: some View {
        Form {
            Section("Storage Location") {
                HStack {
                    Text("Current location:")
                    Spacer()
                    Text(preferences.storageLocation.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Change Location...") {
                    selectStorageLocation()
                }

                Button("Reset to Default") {
                    preferences.resetStorageLocation()
                }
            }

            Section("Storage Information") {
                if let info = storageInfo {
                    HStack {
                        Text("Total images:")
                        Spacer()
                        Text("\(info.fileCount)")
                    }

                    HStack {
                        Text("Total size:")
                        Spacer()
                        Text("\(String(format: "%.1f", info.totalSizeMB)) MB")
                    }
                } else {
                    Text("Loading storage information...")
                        .foregroundColor(.secondary)
                }
            }

            Section("Cleanup") {
                Button("Clean Thumbnails Cache") {
                    cleanThumbnailsCache()
                }

                Button("Remove Orphaned Files") {
                    removeOrphanedFiles()
                }

                Button("Rebuild Database Index") {
                    rebuildDatabaseIndex()
                }
            }
        }
        .padding()
        .task {
            await loadStorageInfo()
        }
    }

    private func selectStorageLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let url = panel.url {
                preferences.storageLocation = url
            }
        }
    }

    private func loadStorageInfo() async {
        // Load storage information from file manager service
    }

    private func cleanThumbnailsCache() {
        // Implement thumbnail cache cleanup
    }

    private func removeOrphanedFiles() {
        // Implement orphaned file cleanup
    }

    private func rebuildDatabaseIndex() {
        // Implement database index rebuild
    }
}
```

### AppPreferences.swift - Settings Management:

```swift
import SwiftUI
import Foundation

class AppPreferences: ObservableObject {
    @Published var appearance: AppearanceMode {
        didSet { save() }
    }

    @Published var showThumbnails: Bool {
        didSet { save() }
    }

    @Published var gridColumns: Int {
        didSet { save() }
    }

    @Published var realtimeSearch: Bool {
        didSet { save() }
    }

    @Published var searchInFilenames: Bool {
        didSet { save() }
    }

    @Published var searchInTags: Bool {
        didSet { save() }
    }

    @Published var maxRecentSearches: Int {
        didSet { save() }
    }

    @Published var autoOrganizeByDate: Bool {
        didSet { save() }
    }

    @Published var generateThumbnailsImmediately: Bool {
        didSet { save() }
    }

    @Published var optimizeLargeImages: Bool {
        didSet { save() }
    }

    @Published var duplicateHandling: DuplicateHandling {
        didSet { save() }
    }

    @Published var defaultTags: [String] {
        didSet { save() }
    }

    @Published var storageLocation: URL {
        didSet { save() }
    }

    private let userDefaults = UserDefaults.standard

    init() {
        self.appearance = AppearanceMode(rawValue: userDefaults.string(forKey: "appearance") ?? "system") ?? .system
        self.showThumbnails = userDefaults.bool(forKey: "showThumbnails")
        self.gridColumns = userDefaults.integer(forKey: "gridColumns") == 0 ? 4 : userDefaults.integer(forKey: "gridColumns")
        self.realtimeSearch = userDefaults.bool(forKey: "realtimeSearch")
        self.searchInFilenames = userDefaults.bool(forKey: "searchInFilenames")
        self.searchInTags = userDefaults.bool(forKey: "searchInTags")
        self.maxRecentSearches = userDefaults.integer(forKey: "maxRecentSearches") == 0 ? 10 : userDefaults.integer(forKey: "maxRecentSearches")
        self.autoOrganizeByDate = userDefaults.bool(forKey: "autoOrganizeByDate")
        self.generateThumbnailsImmediately = userDefaults.bool(forKey: "generateThumbnailsImmediately")
        self.optimizeLargeImages = userDefaults.bool(forKey: "optimizeLargeImages")
        self.duplicateHandling = DuplicateHandling(rawValue: userDefaults.string(forKey: "duplicateHandling") ?? "ask") ?? .ask
        self.defaultTags = userDefaults.stringArray(forKey: "defaultTags") ?? []

        // Storage location
        if let data = userDefaults.data(forKey: "storageLocation"),
           let url = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: data) as URL? {
            self.storageLocation = url
        } else {
            self.storageLocation = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("MemeManager")
        }
    }

    private func save() {
        userDefaults.set(appearance.rawValue, forKey: "appearance")
        userDefaults.set(showThumbnails, forKey: "showThumbnails")
        userDefaults.set(gridColumns, forKey: "gridColumns")
        userDefaults.set(realtimeSearch, forKey: "realtimeSearch")
        userDefaults.set(searchInFilenames, forKey: "searchInFilenames")
        userDefaults.set(searchInTags, forKey: "searchInTags")
        userDefaults.set(maxRecentSearches, forKey: "maxRecentSearches")
        userDefaults.set(autoOrganizeByDate, forKey: "autoOrganizeByDate")
        userDefaults.set(generateThumbnailsImmediately, forKey: "generateThumbnailsImmediately")
        userDefaults.set(optimizeLargeImages, forKey: "optimizeLargeImages")
        userDefaults.set(duplicateHandling.rawValue, forKey: "duplicateHandling")
        userDefaults.set(defaultTags, forKey: "defaultTags")

        // Save storage location
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: storageLocation, requiringSecureCoding: true) {
            userDefaults.set(data, forKey: "storageLocation")
        }
    }

    func resetStorageLocation() {
        storageLocation = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MemeManager")
    }
}

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
}

enum DuplicateHandling: String, CaseIterable {
    case ask = "ask"
    case skip = "skip"
    case import = "import"
}
```

### Step 3 Checklist:

- [ ] Create comprehensive preferences system
- [ ] Implement tabbed preferences interface
- [ ] Add all major app settings and configurations
- [ ] Create persistent storage for preferences
- [ ] Test preferences apply immediately where appropriate

## Step 4: System Integration Features

### SystemIntegrationService.swift:

```swift
import AppKit
import UniformTypeIdentifiers

class SystemIntegrationService: ObservableObject {

    // MARK: - Finder Integration
    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }

    func openWithDefaultApp(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    // MARK: - Sharing
    func shareImages(_ images: [MemeImage]) {
        let urls = images.compactMap { $0.url }
        guard !urls.isEmpty else { return }

        let sharingService = NSSharingServicePicker(items: urls)

        // Show sharing picker
        if let window = NSApp.mainWindow {
            let rect = NSRect(x: window.frame.midX, y: window.frame.midY, width: 1, height: 1)
            sharingService.show(relativeTo: rect, of: window.contentView!, preferredEdge: .minY)
        }
    }

    // MARK: - Quick Look
    func quickLookImages(_ images: [MemeImage], startingAt index: Int = 0) {
        let urls = images.compactMap { $0.url }
        guard !urls.isEmpty else { return }

        // Use QLPreviewPanel for Quick Look
        let panel = QLPreviewPanel.shared()
        panel?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Spotlight Integration
    func updateSpotlightMetadata(for image: MemeImage) {
        guard let url = image.url else { return }

        let item = NSMetadataItem()
        // Set searchable attributes
        item.setValue(image.displayName, forKey: NSMetadataItemDisplayNameKey)
        item.setValue(image.tags.map { $0.name }.joined(separator: ", "), forKey: NSMetadataItemKeywordsKey)
        item.setValue("Meme Manager", forKey: NSMetadataItemCreatorKey)

        // Update metadata
        do {
            try url.setResourceValue(item, forKey: .customKeysKey)
        } catch {
            print("Failed to update Spotlight metadata: \(error)")
        }
    }

    // MARK: - Services Menu Integration
    func registerServices() {
        NSUpdateDynamicServices()

        // Register for image services
        let serviceProvider = ImageServiceProvider()
        NSApplication.shared.servicesProvider = serviceProvider
    }
}

class ImageServiceProvider: NSObject {
    @objc func importImageFromService(_ pasteboard: NSPasteboard,
                                    userData: String,
                                    error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        // Handle service requests to import images
        if let imageData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {

            // Import the image through notification
            NotificationCenter.default.post(
                name: .importImageFromService,
                object: image
            )
        }
    }
}

extension Notification.Name {
    static let importImageFromService = Notification.Name("importImageFromService")
}
```

### Step 4 Checklist:

- [ ] Create system integration service
- [ ] Add Finder integration (reveal, open with)
- [ ] Implement sharing service integration
- [ ] Add Quick Look support
- [ ] Create Spotlight metadata updates
- [ ] Test all system integrations

## Step 5: Advanced UI Features

### ImageDetailView.swift - Full Image Viewer:

```swift
import SwiftUI

struct ImageDetailView: View {
    let image: MemeImage
    @State private var fullImage: NSImage?
    @State private var isLoading = true
    @State private var showingTagEditor = false
    @State private var showingRenameDialog = false
    @State private var zoomLevel: CGFloat = 1.0

    @EnvironmentObject var serviceManager: ServiceManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 20) {
                        // Image display
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .frame(width: 200, height: 200)
                            } else if let fullImage = fullImage {
                                Image(nsImage: fullImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(zoomLevel)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                zoomLevel = max(0.5, min(3.0, value))
                                            }
                                    )
                            } else {
                                Text("Failed to load image")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: geometry.size.width * 0.8,
                               maxHeight: geometry.size.height * 0.7)

                        // Image information
                        ImageInfoPanel(image: image)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(image.displayName)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit Tags") {
                    showingTagEditor = true
                }

                Button("Rename") {
                    showingRenameDialog = true
                }

                Button("Copy") {
                    copyImageToClipboard()
                }

                Button("Share") {
                    shareImage()
                }
            }
        }
        .task {
            await loadFullImage()
        }
        .sheet(isPresented: $showingTagEditor) {
            TagManagementView(image: image)
        }
        .sheet(isPresented: $showingRenameDialog) {
            RenameImageView(image: image)
        }
    }

    private func loadFullImage() async {
        guard let url = image.url else { return }

        isLoading = true

        if let image = NSImage(contentsOf: url) {
            await MainActor.run {
                self.fullImage = image
                self.isLoading = false
            }
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func copyImageToClipboard() {
        guard let fullImage = fullImage else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fullImage])
    }

    private func shareImage() {
        guard let url = image.url else { return }

        serviceManager.systemIntegration.shareImages([image])
    }
}

struct ImageInfoPanel: View {
    let image: MemeImage
    @State private var imageInfo: ImageInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image Information")
                .font(.headline)

            Grid(alignment: .leading) {
                GridRow {
                    Text("Name:")
                        .fontWeight(.medium)
                    Text(image.displayName)
                }

                GridRow {
                    Text("Filename:")
                        .fontWeight(.medium)
                    Text(image.filename)
                }

                if let info = imageInfo {
                    GridRow {
                        Text("Size:")
                            .fontWeight(.medium)
                        Text("\(Int(info.size.width)) × \(Int(info.size.height))")
                    }

                    GridRow {
                        Text("File Size:")
                            .fontWeight(.medium)
                        Text(ByteCountFormatter.string(fromByteCount: info.fileSize, countStyle: .file))
                    }

                    GridRow {
                        Text("Type:")
                            .fontWeight(.medium)
                        Text(info.type.preferredFilenameExtension?.uppercased() ?? "Unknown")
                    }
                }

                GridRow {
                    Text("Created:")
                        .fontWeight(.medium)
                    Text(image.createdDate, format: .dateTime)
                }

                if !image.tags.isEmpty {
                    GridRow {
                        Text("Tags:")
                            .fontWeight(.medium)
                        TagsFlowView(tags: image.tags)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .task {
            await loadImageInfo()
        }
    }

    private func loadImageInfo() async {
        // Load image information
    }
}
```

### Step 5 Checklist:

- [ ] Create full-screen image detail view
- [ ] Add zoom and pan functionality
- [ ] Implement image information panel
- [ ] Add toolbar with common actions
- [ ] Test image viewing with various sizes and formats

## Step 6: Export & Backup Features

### ExportService.swift:

```swift
import Foundation
import AppKit

class ExportService: ObservableObject {
    private let databaseService: DatabaseService
    private let fileManager: FileManagerService

    init(databaseService: DatabaseService, fileManager: FileManagerService) {
        self.databaseService = databaseService
        self.fileManager = fileManager
    }

    // MARK: - Export Options
    func exportImageCollection(images: [MemeImage], to destinationURL: URL, format: ExportFormat) async throws {
        switch format {
        case .folder:
            try await exportToFolder(images: images, destination: destinationURL)
        case .archive:
            try await exportToArchive(images: images, destination: destinationURL)
        case .json:
            try await exportToJSON(images: images, destination: destinationURL)
        }
    }

    private func exportToFolder(images: [MemeImage], destination: URL) async throws {
        // Create destination directory
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        // Export metadata
        let metadata = ExportMetadata(images: images, exportDate: Date())
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: destination.appendingPathComponent("metadata.json"))

        // Copy image files
        for image in images {
            guard let sourceURL = image.url else { continue }

            let destinationImageURL = destination.appendingPathComponent(image.filename)
            try FileManager.default.copyItem(at: sourceURL, to: destinationImageURL)
        }
    }

    private func exportToArchive(images: [MemeImage], destination: URL) async throws {
        // Create ZIP archive with images and metadata
        // Implementation would use a ZIP library
    }

    private func exportToJSON(images: [MemeImage], destination: URL) async throws {
        let exportData = ExportData(
            version: "1.0",
            exportDate: Date(),
            images: images.map { image in
                ExportImage(
                    filename: image.filename,
                    originalName: image.originalName,
                    tags: image.tags.map { $0.name },
                    createdDate: image.createdDate
                )
            }
        )

        let jsonData = try JSONEncoder().encode(exportData)
        try jsonData.write(to: destination)
    }

    // MARK: - Backup
    func createBackup(to destinationURL: URL) async throws {
        // Create complete backup including database and images
        let backupFolder = destinationURL.appendingPathComponent("MemeManager_Backup_\(Date().timeIntervalSince1970)")
        try FileManager.default.createDirectory(at: backupFolder, withIntermediateDirectories: true)

        // Copy database
        let databaseURL = databaseService.databaseURL
        let backupDatabaseURL = backupFolder.appendingPathComponent("database.db")
        try FileManager.default.copyItem(at: databaseURL, to: backupDatabaseURL)

        // Copy all images
        let imagesBackupURL = backupFolder.appendingPathComponent("images")
        try FileManager.default.copyItem(at: fileManager.storageDirectory, to: imagesBackupURL)

        // Create backup manifest
        let manifest = BackupManifest(
            version: "1.0",
            createdDate: Date(),
            imageCount: try databaseService.getImageCount(),
            tagCount: try databaseService.getTagCount()
        )

        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: backupFolder.appendingPathComponent("manifest.json"))
    }
}

// MARK: - Export Models
struct ExportMetadata: Codable {
    let images: [MemeImage]
    let exportDate: Date
}

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let images: [ExportImage]
}

struct ExportImage: Codable {
    let filename: String
    let originalName: String
    let tags: [String]
    let createdDate: Date
}

struct BackupManifest: Codable {
    let version: String
    let createdDate: Date
    let imageCount: Int
    let tagCount: Int
}

enum ExportFormat: String, CaseIterable {
    case folder = "folder"
    case archive = "archive"
    case json = "json"
}
```

### Step 6 Checklist:

- [ ] Create export service with multiple formats
- [ ] Implement backup functionality
- [ ] Add export UI with format selection
- [ ] Test export and backup operations
- [ ] Add progress tracking for long operations

## Validation Checklist

- [ ] ✅ Menu bar integration works with all commands
- [ ] ✅ Keyboard shortcuts function properly throughout app
- [ ] ✅ Preferences system saves and applies settings
- [ ] ✅ System integrations (Finder, sharing, etc.) work correctly
- [ ] ✅ Advanced UI features enhance user experience
- [ ] ✅ Export and backup functionality is reliable
- [ ] ✅ App feels native to macOS with proper conventions

## Common Issues & Solutions

- **Menu commands not working**: Check notification observers and command setup
- **Keyboard shortcuts conflicting**: Verify shortcut assignments and system conflicts
- **Preferences not persisting**: Check UserDefaults implementation and save timing
- **System integration failures**: Verify entitlements and permissions
- **Export errors**: Check file permissions and error handling

## Next Steps

Once this phase is complete, proceed to **07-Testing-Polish.md** for comprehensive testing and final polish.

---

**Estimated Time**: 3-4 days for complete advanced features implementation
