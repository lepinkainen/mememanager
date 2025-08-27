# Meme Manager Project

## Project Overview
A desktop application for storing and organizing meme images with tagging, search, and sharing capabilities. **Currently implementing SwiftUI version** alongside the original Python/CustomTkinter design.

## Technology Stack

### Current Implementation (SwiftUI)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI for macOS 14+
- **Package Manager**: Swift Package Manager
- **Database**: SQLite via SQLite.swift library  
- **Architecture**: MVVM with @MainActor view models

### Original Python Implementation
- **Language**: Python 3.11+
- **GUI Framework**: CustomTkinter (modern, native-looking GUI)
- **Database**: SQLite (embedded, no external dependencies)
- **Image Processing**: Pillow (PIL)
- **Dependency Management**: uv (modern Python package manager)
- **Linting/Formatting**: ruff
- **Type Checking**: mypy

## Project Structure
```
mememanager/
├── CLAUDE.md                          # This file  
├── MemeManagerSwiftUI/                # SwiftUI implementation
│   ├── Package.swift                  # Swift package definition
│   └── MemeManager/                   # Main source code
│       ├── App/                       # App entry point
│       ├── Models/                    # Data models (MemeImage, Tag)
│       ├── Services/                  # Business logic layer
│       │   ├── DatabaseService.swift  # SQLite operations
│       │   ├── FileManagerService.swift
│       │   ├── ImageProcessingService.swift
│       │   ├── ClipboardService.swift
│       │   └── ThumbnailManager.swift
│       ├── ViewModels/                # MVVM layer
│       ├── Views/                     # SwiftUI views
│       │   ├── Main/                  # Primary interface
│       │   ├── Components/            # Reusable UI components
│       │   └── Sheets/                # Modal dialogs
│       └── Utils/                     # Helper utilities
├── storage/                           # Image storage
│   ├── memes/YYYY/MM/                 # Organized by date
│   └── thumbnails/YYYY/MM/            # Generated thumbnails
└── plan/                              # Development documentation
```

## Architecture Patterns

### Service Layer
All business logic is centralized in service classes:
- `DatabaseService.shared` - Singleton for SQLite operations
- `FileManagerService.shared` - File system operations with date-based organization
- `ImageProcessingService.shared` - Image manipulation and thumbnail generation
- `ClipboardService` - System clipboard integration
- `ThumbnailManager` - Async thumbnail generation and caching

### MVVM Implementation
- `MemeManagerViewModel` handles UI state with `@Published` properties
- Uses Combine for reactive search (300ms debounce)
- `@MainActor` ensures UI updates happen on main thread
- View models coordinate between Services and Views

### Database Schema
- **images**: id, filename, original_name, path, created_date, updated_date
- **tags**: id, name (unique constraint)
- **image_tags**: image_id, tag_id (junction table with cascade deletes)

## Development Commands

### SwiftUI Build
```bash
cd MemeManagerSwiftUI && swift build
cd MemeManagerSwiftUI && swift run
```

### Development Guidelines
- Follow `llm-shared/project_tech_stack.md` for dependency choices
- Use service singletons for shared state (DatabaseService, FileManagerService, etc.)
- All UI updates must be `@MainActor` or dispatched to main queue
- File operations use security-scoped resources for sandbox compliance
- Store images in `storage/memes/YYYY/MM/` with unique filenames to avoid conflicts
- Generate thumbnails asynchronously in `storage/thumbnails/YYYY/MM/`

## Core Features (Implemented)
1. **Image Import**: Drag & drop, clipboard paste, file dialog
2. **Storage**: Date-organized folders with SQLite metadata tracking
3. **Search**: Real-time text + tag filtering with Combine debouncing
4. **Tagging**: Many-to-many relationships with junction table
5. **Thumbnails**: Async generation with caching for performance
6. **Clipboard**: Copy images back to system clipboard

## Current Status
SwiftUI implementation is functional with core MVP features complete. The original Python design exists as documentation/reference but the active development is on the SwiftUI version.