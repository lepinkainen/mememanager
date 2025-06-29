# Meme Manager Project

## Project Overview
A desktop application for storing and organizing meme images with tagging, search, and sharing capabilities.

## Technology Stack
- **Language**: Python 3.11+
- **GUI Framework**: CustomTkinter (modern, native-looking GUI)
- **Database**: SQLite (embedded, no external dependencies)
- **Image Processing**: Pillow (PIL)
- **Dependency Management**: uv (modern Python package manager)
- **Linting/Formatting**: ruff
- **Type Checking**: mypy
- **Task Management**: Taskfile (taskfile.dev/task)

## Core Features (MVP)
1. **Image Import**:
   - Drag & drop support
   - Copy & paste from clipboard
   - File dialog selection
   - Support formats: PNG, JPG, JPEG, GIF, WEBP

2. **Storage & Organization**:
   - Save images to `storage/memes/YYYY/MM/` structure
   - SQLite database for metadata (tags, names, paths)
   - Unique filename generation to avoid conflicts

3. **Tagging System**:
   - Multiple tags per image
   - Tag autocomplete/suggestions
   - Tag-based organization

4. **Search & Filter**:
   - Real-time text search
   - Search by image name and tags
   - Combined search functionality

5. **Image Management**:
   - Copy images to clipboard for sharing
   - Rename images
   - Thumbnail grid view
   - Image preview

## Project Structure
```
mememanager/
├── CLAUDE.md                 # This file
├── Taskfile.yml              # Task definitions
├── pyproject.toml            # Python project config
├── src/
│   ├── main.py               # Application entry point
│   ├── database/
│   │   ├── __init__.py
│   │   └── manager.py        # Database operations
│   ├── ui/
│   │   ├── __init__.py
│   │   ├── main_window.py    # Main application window
│   │   └── components/       # UI components
│   └── utils/
│       ├── __init__.py
│       └── image_handler.py  # Image processing utilities
├── storage/
│   └── memes/                # Image storage directory
└── build/                    # Build artifacts
```

## Database Schema
- **images**: id, filename, original_name, path, created_date, updated_date
- **tags**: id, name
- **image_tags**: image_id, tag_id (junction table)

## Commands (via Taskfile)
- `task build` - Build the application
- `task test` - Run tests
- `task lint` - Run ruff linting
- `task format` - Format code with ruff
- `task typecheck` - Run mypy type checking

## Development Guidelines
- Follow tech stack guidelines from `llm-shared/project_tech_stack.md`
- Use uv for dependency management
- All code should pass ruff linting and mypy type checking
- Build artifacts go in `build/` directory
- Test thoroughly before marking tasks complete

## Future Enhancements (Post-MVP)
- LLM integration for auto-tagging (Ollama/OpenAI)
- Multi-platform packaging
- Advanced filtering options
- Export functionality
- Duplicate image detection
- Image editing capabilities

## Current Status
Project is in initial development phase. Core MVP features are being implemented first, with LLM integration planned for a later iteration.