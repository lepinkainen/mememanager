"""Main application window using CustomTkinter."""

from pathlib import Path
from tkinter import filedialog

import customtkinter as ctk

from ..database.manager import DatabaseManager
from ..utils.image_handler import ImageHandler


class MemeManagerApp(ctk.CTk):
    """Main application window for Meme Manager."""

    def __init__(self) -> None:
        """Initialize the main application window."""
        super().__init__()

        # Initialize components
        self.db_manager = DatabaseManager()
        self.image_handler = ImageHandler()

        # Configure main window
        self.title("🎭 Meme Manager")
        self.geometry("1200x800")
        self.minsize(800, 600)

        # Set theme
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")

        # Initialize UI
        self.setup_ui()

        # Status variables
        self.current_images: list[dict] = []
        self.selected_image_id: int | None = None

        # Load initial data
        self.refresh_images()

    def setup_ui(self) -> None:
        """Set up the user interface layout."""
        # Configure grid weights
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(1, weight=1)

        # Create sidebar
        self.create_sidebar()

        # Create main content area
        self.create_main_content()

        # Create status bar
        self.create_status_bar()

    def create_sidebar(self) -> None:
        """Create the left sidebar with controls."""
        self.sidebar_frame = ctk.CTkFrame(self, width=250, corner_radius=0)
        self.sidebar_frame.grid(row=0, column=0, rowspan=3, sticky="nsew")
        self.sidebar_frame.grid_rowconfigure(4, weight=1)

        # Title
        self.logo_label = ctk.CTkLabel(
            self.sidebar_frame,
            text="🎭 Meme Manager",
            font=ctk.CTkFont(size=20, weight="bold")
        )
        self.logo_label.grid(row=0, column=0, padx=20, pady=(20, 10))

        # Import section
        self.import_label = ctk.CTkLabel(
            self.sidebar_frame,
            text="Import Images",
            font=ctk.CTkFont(size=16, weight="bold")
        )
        self.import_label.grid(row=1, column=0, padx=20, pady=(20, 5))

        # Import buttons
        self.file_button = ctk.CTkButton(
            self.sidebar_frame,
            text="📁 Select Files",
            command=self.open_file_dialog
        )
        self.file_button.grid(row=2, column=0, padx=20, pady=5)

        self.paste_button = ctk.CTkButton(
            self.sidebar_frame,
            text="📋 Paste from Clipboard",
            command=self.paste_from_clipboard
        )
        self.paste_button.grid(row=3, column=0, padx=20, pady=5)

        # Search section
        self.search_label = ctk.CTkLabel(
            self.sidebar_frame,
            text="Search & Filter",
            font=ctk.CTkFont(size=16, weight="bold")
        )
        self.search_label.grid(row=5, column=0, padx=20, pady=(20, 5))

        # Search entry
        self.search_entry = ctk.CTkEntry(
            self.sidebar_frame,
            placeholder_text="Search memes..."
        )
        self.search_entry.grid(row=6, column=0, padx=20, pady=5, sticky="ew")
        self.search_entry.bind("<KeyRelease>", self.on_search_changed)

        # Clear search button
        self.clear_search_button = ctk.CTkButton(
            self.sidebar_frame,
            text="Clear",
            width=80,
            command=self.clear_search
        )
        self.clear_search_button.grid(row=7, column=0, padx=20, pady=5)

        # Statistics
        self.stats_label = ctk.CTkLabel(
            self.sidebar_frame,
            text="Statistics",
            font=ctk.CTkFont(size=16, weight="bold")
        )
        self.stats_label.grid(row=8, column=0, padx=20, pady=(20, 5))

        self.stats_text = ctk.CTkLabel(
            self.sidebar_frame,
            text="Images: 0\nTags: 0",
            justify="left"
        )
        self.stats_text.grid(row=9, column=0, padx=20, pady=5)

    def create_main_content(self) -> None:
        """Create the main content area."""
        # Main content frame
        self.main_frame = ctk.CTkFrame(self)
        self.main_frame.grid(row=0, column=1, rowspan=2, padx=10, pady=10, sticky="nsew")
        self.main_frame.grid_columnconfigure(0, weight=1)
        self.main_frame.grid_rowconfigure(1, weight=1)

        # Drop zone (initially visible when no images)
        self.drop_zone = ctk.CTkFrame(self.main_frame)
        self.drop_zone.grid(row=0, column=0, padx=20, pady=20, sticky="ew")

        self.drop_label = ctk.CTkLabel(
            self.drop_zone,
            text="📁 Use the import buttons to add images\n(Drag & drop coming soon)",
            font=ctk.CTkFont(size=18),
            height=100
        )
        self.drop_label.pack(expand=True, fill="both", padx=20, pady=20)

        # Scrollable frame for image grid
        self.scrollable_frame = ctk.CTkScrollableFrame(self.main_frame)
        self.scrollable_frame.grid(row=1, column=0, padx=10, pady=10, sticky="nsew")
        self.scrollable_frame.grid_columnconfigure(0, weight=1)

        # Image details panel (hidden initially)
        self.details_frame = ctk.CTkFrame(self.main_frame)
        self.details_frame.grid_columnconfigure(1, weight=1)

    def create_status_bar(self) -> None:
        """Create the status bar at the bottom."""
        self.status_frame = ctk.CTkFrame(self, height=30, corner_radius=0)
        self.status_frame.grid(row=2, column=1, sticky="ew", padx=0, pady=0)
        self.status_frame.grid_columnconfigure(0, weight=1)

        self.status_label = ctk.CTkLabel(
            self.status_frame,
            text="Ready",
            anchor="w"
        )
        self.status_label.grid(row=0, column=0, padx=10, pady=5, sticky="w")


    def open_file_dialog(self) -> None:
        """Open file dialog to select images."""
        file_types = [
            ("Image files", "*.png *.jpg *.jpeg *.gif *.webp *.bmp"),
            ("All files", "*.*")
        ]

        files = filedialog.askopenfilenames(
            title="Select meme images",
            filetypes=file_types
        )

        if files:
            self.import_files([Path(file) for file in files])

    def paste_from_clipboard(self) -> None:
        """Import image from clipboard."""
        self.update_status("Checking clipboard...")

        result = self.image_handler.save_image_from_clipboard("clipboard_image")
        if result:
            filename, path = result
            # Add to database
            self.db_manager.add_image(filename, "clipboard_image", str(path))
            self.update_status(f"Image imported from clipboard: {filename}")
            self.refresh_images()
        else:
            self.update_status("No image found in clipboard")

    def import_files(self, file_paths: list[Path]) -> None:
        """Import multiple image files."""
        imported_count = 0
        total_files = len(file_paths)

        for i, file_path in enumerate(file_paths):
            self.update_status(f"Importing {i+1}/{total_files}: {file_path.name}")

            if self.image_handler.validate_image_file(file_path):
                try:
                    filename, storage_path = self.image_handler.save_image(
                        file_path, file_path.name
                    )
                    # Add to database
                    self.db_manager.add_image(filename, file_path.name, str(storage_path))
                    imported_count += 1
                except Exception as e:
                    print(f"Error importing {file_path}: {e}")

        self.update_status(f"Imported {imported_count}/{total_files} images")
        self.refresh_images()

    def on_search_changed(self, event: object) -> None:
        """Handle search query changes."""
        query = self.search_entry.get().strip()
        if query:
            self.current_images = self.db_manager.search_images(query)
        else:
            self.current_images = self.db_manager.get_all_images()
        self.update_image_display()

    def clear_search(self) -> None:
        """Clear search and show all images."""
        self.search_entry.delete(0, "end")
        self.refresh_images()

    def refresh_images(self) -> None:
        """Refresh the image list from database."""
        self.current_images = self.db_manager.get_all_images()
        self.update_image_display()
        self.update_statistics()

    def update_image_display(self) -> None:
        """Update the image grid display."""
        # Clear existing widgets
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()

        if not self.current_images:
            # Show drop zone when no images
            self.drop_zone.grid()
            empty_label = ctk.CTkLabel(
                self.scrollable_frame,
                text="No images found. Import some memes to get started!",
                font=ctk.CTkFont(size=16)
            )
            empty_label.pack(pady=50)
        else:
            # Hide drop zone and show image grid
            self.drop_zone.grid_remove()
            self.create_image_grid()

    def create_image_grid(self) -> None:
        """Create the image thumbnail grid."""
        # This is a placeholder - will be implemented in the next task
        for _i, image in enumerate(self.current_images):
            image_frame = ctk.CTkFrame(self.scrollable_frame)
            image_frame.pack(fill="x", padx=5, pady=5)

            # Placeholder for actual thumbnail
            placeholder_label = ctk.CTkLabel(
                image_frame,
                text=f"🖼️ {image['filename'][:30]}...",
                font=ctk.CTkFont(size=12)
            )
            placeholder_label.pack(side="left", padx=10, pady=5)

            # Show tags
            tags = self.db_manager.get_image_tags(image["id"])
            if tags:
                tag_text = ", ".join([tag["name"] for tag in tags])
                tag_label = ctk.CTkLabel(
                    image_frame,
                    text=f"Tags: {tag_text}",
                    font=ctk.CTkFont(size=10)
                )
                tag_label.pack(side="right", padx=10, pady=5)

    def update_statistics(self) -> None:
        """Update the statistics display."""
        stats = self.db_manager.get_database_stats()
        stats_text = f"Images: {stats['images']}\nTags: {stats['tags']}"
        self.stats_text.configure(text=stats_text)

    def update_status(self, message: str) -> None:
        """Update the status bar message."""
        self.status_label.configure(text=message)
        self.update_idletasks()

    def run(self) -> None:
        """Start the application main loop."""
        self.mainloop()


def main() -> None:
    """Create and run the main application."""
    app = MemeManagerApp()
    app.run()


if __name__ == "__main__":
    main()
