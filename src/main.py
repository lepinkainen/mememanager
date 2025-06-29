"""Main entry point for the Meme Manager application."""

from pathlib import Path

from .ui.main_window import MemeManagerApp


def main() -> None:
    """Main entry point for the application."""
    print("🎭 Meme Manager - Starting up...")

    # Ensure storage directory exists
    storage_dir = Path("storage/memes")
    storage_dir.mkdir(parents=True, exist_ok=True)

    print("📁 Storage directory ready")
    print("🚀 Launching GUI...")

    # Start the GUI application
    app = MemeManagerApp()
    app.run()


if __name__ == "__main__":
    main()
