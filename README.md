# Meme Manager

A desktop application for organizing and managing meme images with tagging, search, and sharing capabilities.

## Features (MVP)

- **Image Import**: Drag & drop, copy & paste, file dialog
- **Storage**: Organized folder structure with SQLite metadata
- **Tagging**: Multiple tags per image with search
- **Search**: Real-time text search by name and tags
- **Sharing**: Copy images to clipboard

## Setup

### Prerequisites

On macOS with Homebrew Python, you need to install tkinter support:
```bash
brew install python-tk
```

### Installation

1. Install dependencies:
   ```bash
   task setup
   ```

2. Run the application:
   ```bash
   task run
   ```

## Development

- `task lint` - Run linting
- `task format` - Format code
- `task typecheck` - Type checking
- `task test` - Run tests
- `task build` - Build application

## Technology Stack

- Python 3.11+ with CustomTkinter
- SQLite database
- uv for dependency management
- ruff for linting/formatting
- mypy for type checking