# Phase 1: Project Setup & Foundation

## Overview

Set up the Xcode project structure and foundational components for the SwiftUI Meme Manager.

## Prerequisites

- [x] Xcode 15.0+ installed
- [x] macOS 14.0+ target (for latest SwiftUI features)
- [x] Swift 5.9+ support
- [x] Understanding of existing Python implementation

## Step 1: Xcode Project Creation

- [x] Open Xcode
- [x] Create new project: **macOS** → **App**
- [x] Project settings:
  - [x] Product Name: `MemeManager`
  - [x] Bundle Identifier: `com.yourname.mememanager`
  - [x] Language: **Swift**
  - [x] Interface: **SwiftUI**
  - [x] Use Core Data: **No** (we'll add SQLite manually)
  - [x] Include Tests: **Yes**
- [x] Save in: `/Users/shrike/projects/mememanager/MemeManagerSwiftUI/`

## Step 2: Project Structure Setup

Create the following folder structure in Xcode:

```
MemeManager/
├── App/
│   ├── MemeManagerApp.swift
│   └── ContentView.swift
├── Models/
│   ├── MemeImage.swift
│   ├── Tag.swift
│   └── DatabaseModels.swift
├── Views/
│   ├── Main/
│   │   ├── MainView.swift
│   │   └── SidebarView.swift
│   ├── Components/
│   │   ├── ImageGridView.swift
│   │   ├── ImageThumbnailView.swift
│   │   └── TagView.swift
│   └── Sheets/
│       ├── ImportView.swift
│       └── ImageDetailView.swift
├── ViewModels/
│   ├── MainViewModel.swift
│   ├── ImageGridViewModel.swift
│   └── SearchViewModel.swift
├── Services/
│   ├── DatabaseService.swift
│   ├── ImageProcessingService.swift
│   ├── FileManagerService.swift
│   └── ClipboardService.swift
├── Utils/
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   └── Image+Extensions.swift
│   └── Constants.swift
└── Resources/
    ├── Assets.xcassets
    └── MemeManager.entitlements
```

### File Creation Checklist:

- [x] Create folder groups in Xcode (right-click → New Group)
- [x] Create empty Swift files for each component listed above
- [x] Verify project builds with empty files

## Step 3: Dependencies & Package Manager

Add the following Swift Package Dependencies:

### SQLite Support:

- [x] Add SQLite.swift package:
  - [x] Xcode → File → Add Package Dependencies
  - [x] URL: `https://github.com/stephencelis/SQLite.swift`
  - [x] Version: Latest stable
  - [x] Add to target: MemeManager

### Image Processing (if needed):

- [x] Consider Kingfisher for advanced image handling:
  - [x] URL: `https://github.com/onevcat/Kingfisher`
  - [x] **Note**: Evaluate if needed or if native SwiftUI is sufficient

## Step 4: App Configuration

### App Entitlements (MemeManager.entitlements):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
</dict>
</plist>
```

### Minimum Target Setup:

- [x] Set deployment target to macOS 14.0
- [x] Configure Info.plist for file type associations:
  - [x] Add supported image file types (PNG, JPG, GIF, WEBP)
  - [x] Set up document types if needed

## Step 5: Basic App Structure

### MemeManagerApp.swift:

```swift
import SwiftUI

@main
struct MemeManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowResizability(.contentSize)
    }
}
```

### ContentView.swift (Initial):

```swift
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
```

## Step 6: Constants Setup

### Constants.swift:

```swift
import Foundation

struct AppConstants {
    // File System
    static let storageDirectory = "MemeManager"
    static let thumbnailDirectory = "Thumbnails"
    static let databaseName = "MemeManager.db"

    // Image Processing
    static let thumbnailSize = CGSize(width: 200, height: 200)
    static let maxImageSize = CGSize(width: 2048, height: 2048)

    // Supported Formats
    static let supportedImageTypes = ["png", "jpg", "jpeg", "gif", "webp", "bmp"]

    // UI
    static let gridColumns = 4
    static let gridSpacing: CGFloat = 10
}
```

## Step 7: Build & Test

- [x] Build project (⌘+B) - should compile without errors
- [x] Run project (⌘+R) - should show basic window
- [x] Verify window sizing and basic navigation structure
- [x] Check that all groups and files are properly organized

## Step 8: Version Control Integration

- [x] Add `.gitignore` for Xcode projects:

```gitignore
# Xcode
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
!*.xcodeproj/project.xcworkspace/
*.xcworkspace/*
!*.xcworkspace/contents.xcworkspacedata

# Build products
build/
DerivedData/

# Various settings
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/

# Other
*.moved-aside
*.xccheckout
*.xcscmblueprint
```

- [x] Commit initial project setup
- [x] Tag as `swiftui-v0.1-setup`

## Validation Checklist

- [x] ✅ Xcode project creates and builds successfully
- [x] ✅ Basic window appears with navigation structure
- [x] ✅ All required folders and files are created
- [x] ✅ SQLite.swift dependency is properly integrated
- [x] ✅ App entitlements are configured for file access
- [x] ✅ Project is committed to git

## Common Issues & Solutions

- **Build errors**: Check that all files have proper import statements
- **Package dependency issues**: Clean build folder and re-add packages
- **Entitlements not working**: Verify signing settings in project configuration
- **Window sizing issues**: Check ContentView frame modifiers

## Next Steps

Once this phase is complete, proceed to **02-Core-Architecture.md** for database and model setup.

---

**Estimated Time**: 2-4 hours depending on Xcode familiarity
