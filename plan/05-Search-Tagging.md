# Phase 5: Search & Tagging System

## Overview

Implement comprehensive search functionality and tag management system that matches the Python implementation's capabilities.

## Prerequisites

- [ ] Phase 4 (Image Management) completed
- [ ] Database service with tag operations working
- [ ] UI foundation properly implemented
- [ ] Image display system functional

## Step 1: Enhanced Search Implementation

### SearchViewModel.swift - Dedicated Search Logic:

```swift
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [MemeImage] = []
    @Published var isSearching: Bool = false
    @Published var searchSuggestions: [String] = []
    @Published var recentSearches: [String] = []

    private var searchCancellable: AnyCancellable?
    private var serviceManager: ServiceManager?

    init() {
        setupSearchBinding()
        loadRecentSearches()
    }

    func configure(with serviceManager: ServiceManager) {
        self.serviceManager = serviceManager
    }

    private func setupSearchBinding() {
        searchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.performSearch(query: searchText)
                }
            }
    }

    func performSearch(query: String) async {
        guard let serviceManager = serviceManager else { return }

        if query.isEmpty {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        do {
            let results = try await serviceManager.database.searchImages(query: query)

            await MainActor.run {
                self.searchResults = results
                self.isSearching = false

                // Add to recent searches if not empty
                if !query.isEmpty && !self.recentSearches.contains(query) {
                    self.recentSearches.insert(query, at: 0)
                    if self.recentSearches.count > 10 {
                        self.recentSearches.removeLast()
                    }
                    self.saveRecentSearches()
                }
            }
        } catch {
            await MainActor.run {
                self.isSearching = false
                print("Search error: \(error)")
            }
        }
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
    }

    func selectRecentSearch(_ search: String) {
        searchText = search
    }

    // MARK: - Persistence
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "RecentSearches"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        }
    }

    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "RecentSearches")
        }
    }
}
```

### Enhanced SearchSectionView.swift:

```swift
import SwiftUI

struct SearchSectionView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var serviceManager: ServiceManager
    @State private var showingSearchSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search & Filter")
                .font(.headline)

            // Search field with suggestions
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search memes...", text: $searchViewModel.searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            showingSearchSuggestions = false
                        }
                        .onTapGesture {
                            showingSearchSuggestions = !searchViewModel.recentSearches.isEmpty
                        }

                    if searchViewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    if !searchViewModel.searchText.isEmpty {
                        Button(action: {
                            searchViewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

                // Search suggestions dropdown
                if showingSearchSuggestions && !searchViewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchViewModel.recentSearches.prefix(5), id: \.self) { search in
                            Button(action: {
                                searchViewModel.selectRecentSearch(search)
                                showingSearchSuggestions = false
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text(search)
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .background(Color.clear)
                            .onHover { hovering in
                                // Add hover effect
                            }
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.top, 2)
                }
            }

            // Quick filter buttons
            QuickFilterView()
                .environmentObject(searchViewModel)
        }
        .onAppear {
            searchViewModel.configure(with: serviceManager)
        }
        .onChange(of: searchViewModel.searchResults) { results in
            mainViewModel.updateSearchResults(results)
        }
        .onTapGesture {
            showingSearchSuggestions = false
        }
    }
}

struct QuickFilterView: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var popularTags: [Tag] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Filters")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60, maximum: 100), spacing: 4)
            ], spacing: 4) {
                ForEach(popularTags.prefix(6)) { tag in
                    Button(tag.name) {
                        searchViewModel.searchText = tag.name
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
        .task {
            await loadPopularTags()
        }
    }

    private func loadPopularTags() async {
        // Load most frequently used tags
        // Implementation depends on database service
    }
}
```

### Step 1 Checklist:

- [ ] Create `SearchViewModel` with proper debouncing
- [ ] Implement real-time search with loading states
- [ ] Add search suggestions and recent searches
- [ ] Create enhanced search UI with dropdowns
- [ ] Add quick filter buttons for popular tags
- [ ] Test search performance and responsiveness

## Step 2: Tag Management System

### TagManagementView.swift - Tag Editor:

```swift
import SwiftUI

struct TagManagementView: View {
    let image: MemeImage
    @State private var currentTags: [Tag] = []
    @State private var newTagName: String = ""
    @State private var availableTags: [Tag] = []
    @State private var filteredTags: [Tag] = []
    @State private var isLoading = false

    @EnvironmentObject var serviceManager: ServiceManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Text("Edit Tags")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(image.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Current tags display
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Tags")
                    .font(.headline)

                if currentTags.isEmpty {
                    Text("No tags assigned")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 8)
                    ], spacing: 8) {
                        ForEach(currentTags) { tag in
                            TagChipView(tag: tag, isRemovable: true) {
                                removeTag(tag)
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 60)

            Divider()

            // Add new tag section
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Tags")
                    .font(.headline)

                HStack {
                    TextField("Enter tag name...", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addNewTag()
                        }

                    Button("Add") {
                        addNewTag()
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                // Tag suggestions
                if !filteredTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filteredTags.prefix(10)) { tag in
                                Button(tag.name) {
                                    addExistingTag(tag)
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            Spacer()

            // Action buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    saveTags()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .task {
            await loadTagData()
        }
        .onChange(of: newTagName) { newValue in
            filterAvailableTags(query: newValue)
        }
    }

    // MARK: - Tag Operations
    private func addNewTag() {
        let tagName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !tagName.isEmpty,
              !currentTags.contains(where: { $0.name.lowercased() == tagName }) else {
            return
        }

        // Create temporary tag for UI
        let tempTag = Tag(id: -1, name: tagName)
        currentTags.append(tempTag)
        newTagName = ""
    }

    private func addExistingTag(_ tag: Tag) {
        guard !currentTags.contains(where: { $0.id == tag.id }) else { return }

        currentTags.append(tag)
        newTagName = ""
    }

    private func removeTag(_ tag: Tag) {
        currentTags.removeAll { $0.id == tag.id }
    }

    private func loadTagData() async {
        do {
            // Load current tags for the image
            let imageTags = try await serviceManager.database.getImageTags(imageId: image.id)

            // Load all available tags
            let allTags = try await serviceManager.database.getAllTags()

            await MainActor.run {
                self.currentTags = imageTags
                self.availableTags = allTags.filter { availableTag in
                    !imageTags.contains { $0.id == availableTag.id }
                }
            }
        } catch {
            print("Error loading tag data: \(error)")
        }
    }

    private func filterAvailableTags(query: String) {
        if query.isEmpty {
            filteredTags = Array(availableTags.prefix(10))
        } else {
            filteredTags = availableTags.filter { tag in
                tag.name.lowercased().contains(query.lowercased())
            }
        }
    }

    private func saveTags() {
        isLoading = true

        Task {
            do {
                // Remove all existing tags for this image
                try await serviceManager.database.removeAllImageTags(imageId: image.id)

                // Add all current tags
                for tag in currentTags {
                    let tagId: Int64

                    if tag.id == -1 {
                        // New tag, create it first
                        tagId = try await serviceManager.database.addTag(name: tag.name)
                    } else {
                        tagId = tag.id
                    }

                    try await serviceManager.database.addImageTag(imageId: image.id, tagId: tagId)
                }

                await MainActor.run {
                    self.isLoading = false
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("Error saving tags: \(error)")
                }
            }
        }
    }
}

struct TagChipView: View {
    let tag: Tag
    let isRemovable: Bool
    let onRemove: (() -> Void)?

    init(tag: Tag, isRemovable: Bool = false, onRemove: (() -> Void)? = nil) {
        self.tag = tag
        self.isRemovable = isRemovable
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.caption)
                .foregroundColor(.primary)

            if isRemovable {
                Button(action: {
                    onRemove?()
                }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}
```

### Step 2 Checklist:

- [ ] Create `TagManagementView` with full CRUD operations
- [ ] Implement tag suggestions and autocomplete
- [ ] Add visual tag chips with remove functionality
- [ ] Create new tag creation workflow
- [ ] Add tag validation and deduplication
- [ ] Test tag management with database operations

## Step 3: Advanced Search Features

### SearchFiltersView.swift - Filter Panel:

```swift
import SwiftUI

struct SearchFiltersView: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var selectedTags: Set<Tag> = []
    @State private var dateRange: DateRange = .all
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var availableTags: [Tag] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filters")
                .font(.headline)

            // Tag filters
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(availableTags.prefix(20)) { tag in
                        TagFilterChip(
                            tag: tag,
                            isSelected: selectedTags.contains(tag)
                        ) {
                            toggleTagSelection(tag)
                        }
                    }
                }
            }

            Divider()

            // Date range filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Date Added")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Date Range", selection: $dateRange) {
                    Text("All Time").tag(DateRange.all)
                    Text("Today").tag(DateRange.today)
                    Text("This Week").tag(DateRange.thisWeek)
                    Text("This Month").tag(DateRange.thisMonth)
                    Text("This Year").tag(DateRange.thisYear)
                }
                .pickerStyle(.menu)
            }

            Divider()

            // Sort order
            VStack(alignment: .leading, spacing: 8) {
                Text("Sort By")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Sort Order", selection: $sortOrder) {
                    Text("Date Added (Newest)").tag(SortOrder.dateDescending)
                    Text("Date Added (Oldest)").tag(SortOrder.dateAscending)
                    Text("Name (A-Z)").tag(SortOrder.nameAscending)
                    Text("Name (Z-A)").tag(SortOrder.nameDescending)
                }
                .pickerStyle(.menu)
            }

            Spacer()

            // Reset filters
            Button("Reset Filters") {
                resetFilters()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .task {
            await loadAvailableTags()
        }
        .onChange(of: selectedTags) { _ in
            applyFilters()
        }
        .onChange(of: dateRange) { _ in
            applyFilters()
        }
        .onChange(of: sortOrder) { _ in
            applyFilters()
        }
    }

    private func toggleTagSelection(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    private func resetFilters() {
        selectedTags.removeAll()
        dateRange = .all
        sortOrder = .dateDescending
    }

    private func applyFilters() {
        // Apply filters through search view model
        searchViewModel.applyFilters(
            tags: Array(selectedTags),
            dateRange: dateRange,
            sortOrder: sortOrder
        )
    }

    private func loadAvailableTags() async {
        // Load all available tags from database
    }
}

struct TagFilterChip: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(tag.name)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

enum DateRange: CaseIterable {
    case all, today, thisWeek, thisMonth, thisYear
}

enum SortOrder: CaseIterable {
    case dateDescending, dateAscending, nameAscending, nameDescending
}
```

### Step 3 Checklist:

- [ ] Create advanced search filters panel
- [ ] Implement tag-based filtering
- [ ] Add date range filtering
- [ ] Create sort order options
- [ ] Add filter reset functionality
- [ ] Test complex search combinations

## Step 4: Search Integration

### Update MainViewModel with enhanced search:

```swift
extension MainViewModel {
    func updateSearchResults(_ results: [MemeImage]) {
        images = results
    }

    func showTagEditor(for image: MemeImage) {
        selectedImage = image
        showTagEditor = true
    }

    func refreshImageTags() {
        // Refresh tags for all images after tag changes
        Task {
            await loadImages()
        }
    }
}

// Add to MainView
struct MainView: View {
    @EnvironmentObject var mainViewModel: MainViewModel

    var body: some View {
        // ... existing code ...
        .sheet(isPresented: $mainViewModel.showTagEditor) {
            if let image = mainViewModel.selectedImage {
                TagManagementView(image: image)
                    .onDisappear {
                        mainViewModel.refreshImageTags()
                    }
            }
        }
    }
}
```

### Step 4 Checklist:

- [ ] Integrate search results with main view
- [ ] Connect tag editor to main workflow
- [ ] Update image display after tag changes
- [ ] Test search and tag management integration
- [ ] Verify data consistency across views

## Step 5: Tag Analytics & Management

### TagAnalyticsView.swift - Tag Overview:

```swift
import SwiftUI

struct TagAnalyticsView: View {
    @State private var tagStats: [TagStatistic] = []
    @State private var isLoading = true

    @EnvironmentObject var serviceManager: ServiceManager

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Tag Management")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Button("Cleanup Unused Tags") {
                        cleanupUnusedTags()
                    }
                    .buttonStyle(.bordered)
                }

                // Statistics
                if isLoading {
                    ProgressView("Loading tag statistics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(tagStats) { stat in
                        TagStatisticRow(statistic: stat)
                    }
                }
            }
            .padding()
            .task {
                await loadTagStatistics()
            }
        }
    }

    private func loadTagStatistics() async {
        isLoading = true

        do {
            let stats = try await serviceManager.database.getTagStatistics()

            await MainActor.run {
                self.tagStats = stats.sorted { $0.imageCount > $1.imageCount }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Error loading tag statistics: \(error)")
            }
        }
    }

    private func cleanupUnusedTags() {
        Task {
            do {
                let removedCount = try await serviceManager.database.removeUnusedTags()
                await loadTagStatistics()

                await MainActor.run {
                    // Show success message
                    print("Removed \(removedCount) unused tags")
                }
            } catch {
                print("Error cleaning up tags: \(error)")
            }
        }
    }
}

struct TagStatistic: Identifiable {
    let id: Int64
    let name: String
    let imageCount: Int
}

struct TagStatisticRow: View {
    let statistic: TagStatistic

    var body: some View {
        HStack {
            Text(statistic.name)
                .font(.body)

            Spacer()

            Text("\(statistic.imageCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
}
```

### Step 5 Checklist:

- [ ] Create tag analytics and management view
- [ ] Show tag usage statistics
- [ ] Add cleanup functionality for unused tags
- [ ] Create tag merging capabilities
- [ ] Test tag analytics with real data

## Step 6: Search Performance Optimization

### Implement search indexing and caching:

```swift
// Add to DatabaseService.swift
extension DatabaseService {
    func createSearchIndex() throws {
        // Create full-text search index for better performance
        let createIndexSQL = """
            CREATE VIRTUAL TABLE IF NOT EXISTS images_fts USING fts5(
                filename, original_name, tags, content='images'
            );
        """

        try db.execute(createIndexSQL)
    }

    func updateSearchIndex(for imageId: Int64) throws {
        // Update search index when image or tags change
        let image = try getImage(id: imageId)
        let tags = try getImageTags(imageId: imageId)

        let tagsString = tags.map { $0.name }.joined(separator: " ")

        let updateSQL = """
            INSERT OR REPLACE INTO images_fts (rowid, filename, original_name, tags)
            VALUES (?, ?, ?, ?)
        """

        try db.execute(updateSQL, [imageId, image?.filename ?? "", image?.originalName ?? "", tagsString])
    }

    func performOptimizedSearch(query: String) throws -> [MemeImage] {
        // Use FTS index for better search performance
        let searchSQL = """
            SELECT images.* FROM images
            JOIN images_fts ON images.id = images_fts.rowid
            WHERE images_fts MATCH ?
            ORDER BY rank
        """

        return try db.prepare(searchSQL).bind(query).map { row in
            // Convert row to MemeImage
        }
    }
}
```

### Step 6 Checklist:

- [ ] Implement full-text search indexing
- [ ] Add search result caching
- [ ] Optimize database queries for search
- [ ] Test search performance with large datasets
- [ ] Add search analytics and metrics

## Validation Checklist

- [ ] ✅ Real-time search works with proper debouncing
- [ ] ✅ Tag management system allows full CRUD operations
- [ ] ✅ Search suggestions and recent searches work
- [ ] ✅ Advanced filters (tags, date, sort) function correctly
- [ ] ✅ Tag analytics provide useful insights
- [ ] ✅ Search performance is acceptable with large datasets
- [ ] ✅ Search and tag data remains consistent across views

## Common Issues & Solutions

- **Slow search performance**: Implement proper indexing and caching
- **Tag synchronization issues**: Ensure proper data flow and refresh mechanisms
- **Memory issues with large tag lists**: Implement proper pagination and lazy loading
- **Search not updating**: Check debouncing and Combine setup
- **Tag editor not saving**: Verify database transaction handling

## Next Steps

Once this phase is complete, proceed to **06-Advanced-Features.md** for implementing keyboard shortcuts, menu integration, and other advanced features.

---

**Estimated Time**: 2-3 days for complete search and tagging implementation
