# Project overview: Meme Organizer App

I want to create an application to store and organise meme images, it can be either a web app (self-hosted, no login) or anything that runs on macOS, multi-platform is optional (linux + windows)
It should be able to:

- take in images from: drag & drop, copy & paste and selecting via a file dialog
- allow the user to rename + tag the image with multiple tags and save it to the file system
- OPTIONAL: use a local LLM model via ollama or an online LLM via API to analyse and rename + tag the image automatically
- Searching for memes based on text search (image name + tags)
- If any metadata needs to be stored it should be in the image names or an sqlite database
- Meme images should be copyable from the application so that they can be pasted for sharing in discord and slack etc.
  What would be the best programming languages for this? My personal preferences are Python and Go for backend

# Meme Organizer App Development Todo List

## ✅ COMPLETED - Project Setup & Structure

- [x] Create Python project with virtual environment (using uv)
- [x] Install required dependencies:
  - `customtkinter` (modern UI framework)
  - `Pillow` (image processing)
  - `sqlite3` (built-in database)
  - ~~`requests` (for API calls)~~ - will add when needed for LLM
  - ~~`tkinterdnd2` (drag & drop support)~~ - removed due to system dependencies
- [x] Set up project directory structure:
  ```
  mememanager/
  ├── src/
  │   ├── main.py
  │   ├── database/
  │   │   ├── __init__.py
  │   │   └── manager.py
  │   ├── ui/
  │   │   ├── __init__.py
  │   │   ├── main_window.py
  │   │   └── components/
  │   └── utils/
  │       ├── __init__.py
  │       └── image_handler.py
  ├── storage/
  │   └── memes/
  ├── tests/
  ├── build/
  ├── pyproject.toml
  ├── Taskfile.yml
  ├── CLAUDE.md
  └── README.md
  ```

## ✅ COMPLETED - Database Setup

- [x] Create SQLite database schema with tables:
  - `images` (id, filename, original_name, path, created_date, updated_date)
  - `tags` (id, name)
  - `image_tags` (image_id, tag_id) - junction table
- [x] Implement database manager class with methods:
  - [x] Initialize database and create tables
  - [x] Add/update/delete images
  - [x] Add/remove tags
  - [x] Associate tags with images
  - [x] Search images by name and tags

## ✅ COMPLETED - Core Image Handling

- [x] Implement image file operations:
  - [x] Save images to organized folder structure (`storage/memes/YYYY/MM/`)
  - [x] Generate unique filenames to avoid conflicts
  - [x] Support common image formats (PNG, JPG, JPEG, GIF, WEBP, BMP)
  - [x] Create image thumbnails for UI display (function implemented)
  - [x] Copy images to clipboard functionality (basic file path implementation)

## 🔄 IN PROGRESS - User Interface Development

- [x] Create main application window with CustomTkinter
- [x] Implement main layout with sections:
  - [x] Image import area (file dialog buttons)
  - [x] ~~Image grid/list view with thumbnails~~ **NEEDS WORK: Currently text placeholders**
  - [x] Search bar and filters
  - [ ] **PRIORITY: Image details panel (tags, rename field)**
  - [x] Status bar for feedback

### 🔄 Image Import Features - PARTIALLY COMPLETE

- [ ] ~~Drag & drop functionality~~ **DEFERRED: Library issues**
  - [ ] ~~Visual feedback during drag operations~~
  - [ ] ~~Support multiple file drops~~
  - [ ] ~~File type validation~~
- [x] Clipboard paste support:
  - [x] Detect image data in clipboard (file paths)
  - [x] **COMPLETED: Handle binary clipboard image paste** (using PIL ImageGrab)
- [x] File dialog for manual selection:
  - [x] Multiple file selection support
  - [x] Image format filtering

### 🚨 PRIORITY - Image Display & Management

- [ ] **HIGH PRIORITY: Create actual image thumbnail grid view** (replace text placeholders)
- [ ] **HIGH PRIORITY: Implement image selection (single/multiple)**
- [ ] **HIGH PRIORITY: Add context menu for image operations:**
  - [ ] Copy to clipboard (proper image data)
  - [ ] Delete image
  - [ ] Open in default viewer
- [ ] **HIGH PRIORITY: Image detail view with:**
  - [ ] Large preview
  - [ ] Editable name field
  - [ ] Tag management UI (add/remove tags)
  - [ ] Metadata display

### ✅ COMPLETED - Search & Filter System (Basic)

- [x] Implement search functionality:
  - [x] Real-time search as user types
  - [x] Search by image name
  - [x] Search by tags
  - [x] Combined name + tag search
  - [x] Clear filters button
- [ ] **FUTURE: Add advanced filter options:**
  - [ ] Filter by date added
  - [ ] Filter by tags (tag cloud or dropdown)

## 🎯 NEXT PHASE - Core Features to Complete MVP

### Image Thumbnail Grid (TOP PRIORITY)

- [ ] Replace text placeholders with actual thumbnail images
- [ ] Implement proper grid layout with image previews
- [ ] Add image selection highlighting
- [ ] Optimize thumbnail loading for performance

### Tag Management UI (HIGH PRIORITY)

- [ ] Create tag input/editing interface
- [ ] Implement tag autocomplete/suggestions
- [ ] Add visual tag display (chips/badges)
- [ ] Enable tag addition/removal from UI

### Enhanced Clipboard Support

- [ ] Implement proper binary image clipboard handling
- [ ] Platform-specific clipboard image copying
- [ ] Test clipboard functionality across different image sources

## 🔮 FUTURE PHASES - Optional Features

### LLM Integration (Optional Features)

- [ ] Create LLM integration module:
  - [ ] Ollama local model integration
  - [ ] OpenAI API integration (with API key management)
  - [ ] Image analysis prompt templates
- [ ] Implement auto-tagging features:
  - [ ] Analyze image content and suggest tags
  - [ ] Auto-generate descriptive filenames
  - [ ] Batch processing for multiple images
- [ ] Add LLM settings UI:
  - [ ] Choose between local/API models
  - [ ] Configure API keys
  - [ ] Enable/disable auto-analysis

### Settings & Configuration

- [ ] Create settings/preferences system:
  - [ ] Storage location configuration
  - [ ] Default tags setup
  - [ ] LLM provider selection
  - [ ] UI theme options
- [ ] Implement settings persistence (JSON config file)

### Enhanced User Experience

- [ ] Add comprehensive error handling:
  - [ ] File access errors
  - [ ] Database connection issues
  - [ ] Network errors for API calls
  - [ ] Invalid image format handling
- [ ] Implement user feedback:
  - [ ] Progress bars for long operations
  - [ ] Status messages
  - [ ] Confirmation dialogs for destructive actions
- [x] Add keyboard shortcuts:
  - [x] **COMPLETED: Cmd+V/Ctrl+V for paste**
  - [ ] Ctrl+C for copy selected image
  - [ ] Delete key for removing images
  - [ ] Ctrl+F for search focus

### Drag & Drop (Optional Enhancement)

- [x] **COMPLETED: Graceful drag & drop handling**
  - [x] Optional tkinterdnd2 integration
  - [x] Fallback when system libraries unavailable
  - [x] User feedback about drag & drop availability
- [ ] **FUTURE: Enhanced drag & drop features**
  - [ ] Visual feedback during drag operations
  - [ ] Multiple file drop support
  - [ ] File type validation during drop

## ✅ COMPLETED - Testing & Quality Assurance

- [x] Professional development setup:
  - [x] Linting with ruff (all checks pass)
  - [x] Type checking with mypy (all checks pass)
  - [x] Build system (wheel/source distribution)
  - [x] Task management with Taskfile
- [x] Test core functionality:
  - [x] Database operations (comprehensive tests)
  - [x] Image import from file dialog
  - [x] Search functionality
- [ ] **TODO: Test remaining functionality:**
  - [ ] Image thumbnail display
  - [ ] Tag management UI
  - [ ] Copy to clipboard (when implemented)
- [ ] Test edge cases:
  - [ ] Large image files
  - [ ] Many images (performance)
  - [ ] Special characters in filenames/tags

## ✅ COMPLETED - Documentation & Project Setup

- [x] Create project documentation:
  - [x] CLAUDE.md with complete project context
  - [x] README.md with setup instructions
  - [x] Professional Python packaging
- [ ] **FUTURE: Distribution preparation:**
  - [ ] Create executable with PyInstaller
  - [ ] Test on different operating systems
  - [ ] Create installer/package for easy distribution

## 🌟 Future Enhancements (Nice to Have)

- [ ] Import from URLs
- [ ] Duplicate image detection
- [ ] Image editing capabilities (crop, resize)
- [ ] Export functionality (backup, sharing)
- [ ] Light theme support (dark theme already implemented)
- [ ] Bulk operations (batch tagging, renaming)
- [ ] Image similarity search
- [ ] Statistics and analytics view

---

## 📊 Current Status: ~80% Complete MVP

### ✅ **Working Now:**

- Application launches with modern GUI
- File dialog image import
- Clipboard paste from screenshots and copied images
- **NEW: Keyboard shortcuts (Cmd+V/Ctrl+V for paste)**
- SQLite database with full schema
- Real-time search functionality
- Professional development setup
- Graceful drag & drop support (when system libraries available)

### 🚨 **Immediate Next Steps:**

1. **Implement actual thumbnail grid display** (replace text placeholders)
2. **Create tag management UI** (add/edit/remove tags)
3. **Build image detail panel** (large preview + metadata editing)
4. **Enhance clipboard support** (proper image data copying)

### 🎯 **MVP Complete When:**

- Thumbnail grid shows actual images
- Users can add/edit tags through UI
- Images can be copied to clipboard properly
- Basic image management workflow is complete
