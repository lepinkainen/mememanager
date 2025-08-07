# Agent Guidelines for Meme Manager Project

This document provides guidance for AI agents working on the Meme Manager project.

## Project Overview
The project is a desktop application for storing and organizing meme images. Key features include image import, tagging, search, and management.

## Technology Stack
- **Language**: Python 3.11+
- **GUI Framework**: CustomTkinter
- **Database**: SQLite
- **Image Processing**: Pillow (PIL)
- **Dependency Management**: uv
- **Linting/Formatting**: ruff
- **Type Checking**: mypy
- **Task Management**: Taskfile

## Development Workflow
All common development tasks are managed through `Taskfile`. Use the following commands:

- `task build`: Build the application.
- `task test`: Run the test suite.
- `task lint`: Run the ruff linter to check for style issues.
- `task format`: Format the code using ruff.
- `task typecheck`: Run mypy for static type checking.

Before submitting any changes, ensure that all tests, linting, and type checks pass.

## Project Structure
```
mememanager/
├── AGENTS.md                 # This file
├── CLAUDE.md                 # Project details for Claude agent
├── Taskfile.yml              # Task definitions
├── pyproject.toml            # Python project config
├── src/
│   ├── main.py               # Application entry point
│   ├── database/
│   │   └── manager.py        # Database operations
│   ├── ui/
│   │   └── main_window.py    # Main application window
│   └── utils/
│       └── image_handler.py  # Image processing utilities
├── storage/
│   └── memes/                # Image storage directory
└── build/                    # Build artifacts
```

## Key Guidelines
- Use `uv` for all Python dependency management.
- Adhere to the coding style enforced by `ruff`.
- All code must pass `mypy` type checking.
- Do not commit build artifacts in the `build/` directory.
- For any new feature, add corresponding tests.
