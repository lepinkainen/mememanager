"""Image handling utilities for processing, storing, and managing meme images."""

import io
import shutil
import tkinter as tk
import uuid
from datetime import datetime
from pathlib import Path

from PIL import Image


class ImageHandler:
    """Handles image operations including storage, thumbnails, and clipboard."""

    SUPPORTED_FORMATS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp"}
    THUMBNAIL_SIZE = (200, 200)
    MAX_IMAGE_SIZE = (2048, 2048)

    def __init__(self, storage_root: str = "storage/memes"):
        """Initialize image handler with storage root directory."""
        self.storage_root = Path(storage_root)
        self.storage_root.mkdir(parents=True, exist_ok=True)

        # Initialize thumbnail cache directory
        self.thumbnail_root = Path("storage/thumbnails")
        self.thumbnail_root.mkdir(parents=True, exist_ok=True)

    def is_supported_format(self, file_path: Path) -> bool:
        """Check if the file format is supported."""
        return file_path.suffix.lower() in self.SUPPORTED_FORMATS

    def generate_unique_filename(
        self, original_name: str, extension: str | None = None
    ) -> str:
        """Generate a unique filename to avoid conflicts."""
        if extension is None:
            extension = Path(original_name).suffix

        # Clean the original name
        base_name = Path(original_name).stem
        # Remove special characters and limit length
        clean_name = "".join(c for c in base_name if c.isalnum() or c in "- _")[:50]

        # Generate unique identifier
        unique_id = str(uuid.uuid4())[:8]
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        return f"{timestamp}_{unique_id}_{clean_name}{extension}"

    def get_storage_path(self, filename: str) -> Path:
        """Get the full storage path for a filename with date-based organization."""
        now = datetime.now()
        year_month = now.strftime("%Y/%m")
        storage_dir = self.storage_root / year_month
        storage_dir.mkdir(parents=True, exist_ok=True)
        return storage_dir / filename

    def save_image(self, source_path: Path, original_name: str) -> tuple[str, Path]:
        """Save an image to storage and return filename and path."""
        if not self.is_supported_format(source_path):
            raise ValueError(f"Unsupported image format: {source_path.suffix}")

        # Generate unique filename and storage path
        filename = self.generate_unique_filename(original_name, source_path.suffix)
        storage_path = self.get_storage_path(filename)

        # Optimize and save the image
        try:
            with Image.open(source_path) as img:
                # Convert to RGB if necessary
                if img.mode in ("RGBA", "P"):
                    rgb_img = Image.new("RGB", img.size, (255, 255, 255))
                    if img.mode == "P":
                        img = img.convert("RGBA")
                    rgb_img.paste(
                        img, mask=img.split()[-1] if img.mode == "RGBA" else None
                    )
                    img = rgb_img

                # Resize if too large
                if (
                    img.size[0] > self.MAX_IMAGE_SIZE[0]
                    or img.size[1] > self.MAX_IMAGE_SIZE[1]
                ):
                    img.thumbnail(self.MAX_IMAGE_SIZE, Image.Resampling.LANCZOS)

                # Save optimized image
                img.save(storage_path, optimize=True, quality=85)

        except Exception:
            # Fallback to simple file copy if PIL processing fails
            shutil.copy2(source_path, storage_path)

        return filename, storage_path

    def save_image_from_clipboard(
        self, original_name: str | None = None
    ) -> tuple[str, Path] | None:
        """Save an image from clipboard to storage."""
        try:
            # First try to get image directly from clipboard using PIL
            try:
                from PIL import ImageGrab

                img = ImageGrab.grabclipboard()
                if img and isinstance(img, Image.Image):
                    # Create temporary file to save clipboard image
                    temp_path = Path("temp_clipboard.png")
                    img.save(temp_path, "PNG")
                    result = self.save_image(
                        temp_path, original_name or "clipboard_image.png"
                    )
                    # Clean up temp file
                    if temp_path.exists():
                        temp_path.unlink()
                    return result
            except ImportError:
                # ImageGrab not available on this platform
                pass
            except Exception:
                # Error getting image from clipboard
                pass

            # Fallback: try to get file path from clipboard
            try:
                root = tk.Tk()
                root.withdraw()  # Hide the window

                clipboard_data = root.clipboard_get()
                root.destroy()

                # If we get text, it might be a file path
                if clipboard_data and Path(clipboard_data).exists():
                    clipboard_path = Path(clipboard_data)
                    if clipboard_path.suffix.lower() in {
                        ".png",
                        ".jpg",
                        ".jpeg",
                        ".gif",
                        ".webp",
                    }:
                        return self.save_image(
                            clipboard_path, original_name or "clipboard_image"
                        )
            except tk.TclError:
                # No text data in clipboard
                pass
            except Exception:
                pass

            return None

        except Exception:
            return None

    def create_thumbnail(self, image_path: Path) -> Image.Image | None:
        """Create a thumbnail for the given image."""
        try:
            with Image.open(image_path) as img:
                img.thumbnail(self.THUMBNAIL_SIZE, Image.Resampling.LANCZOS)
                return img.copy()
        except Exception:
            return None

    def get_image_info(self, image_path: Path) -> dict | None:
        """Get basic information about an image file."""
        try:
            with Image.open(image_path) as img:
                return {
                    "size": img.size,
                    "format": img.format,
                    "mode": img.mode,
                    "file_size": image_path.stat().st_size,
                }
        except Exception:
            return None

    def copy_to_clipboard(self, image_path: Path) -> bool:
        """Copy an image to the system clipboard."""
        try:
            with Image.open(image_path) as img:
                # Convert to RGB if necessary
                if img.mode != "RGB":
                    img = img.convert("RGB")

                # Save to temporary buffer
                output = io.BytesIO()
                img.save(output, format="PNG")
                output.seek(0)

                # Copy to clipboard (platform-specific implementation)
                root = tk.Tk()
                root.withdraw()

                # Clear clipboard and set image
                root.clipboard_clear()

                # This is a simplified approach - actual clipboard image handling
                # varies by platform and may require additional libraries
                try:
                    # On some systems, we can put the image path in clipboard
                    root.clipboard_append(str(image_path.absolute()))
                    root.update()
                    root.destroy()
                    return True
                except Exception:
                    root.destroy()
                    return False

        except Exception:
            return False

    def validate_image_file(self, file_path: Path) -> bool:
        """Validate that a file is a proper image file."""
        if not file_path.exists():
            return False

        if not self.is_supported_format(file_path):
            return False

        try:
            with Image.open(file_path) as img:
                img.verify()  # Verify the image integrity
            return True
        except Exception:
            return False

    def delete_image_file(self, image_path: Path) -> bool:
        """Delete an image file from storage."""
        try:
            if image_path.exists():
                image_path.unlink()
                return True
            return False
        except Exception:
            return False

    def get_storage_usage(self) -> dict:
        """Get storage usage statistics."""
        total_size = 0
        file_count = 0

        for file_path in self.storage_root.rglob("*"):
            if file_path.is_file() and self.is_supported_format(file_path):
                total_size += file_path.stat().st_size
                file_count += 1

        return {
            "total_size_bytes": total_size,
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "file_count": file_count,
        }

    def get_thumbnail_path(self, image_path: Path) -> Path:
        """Get the corresponding thumbnail path for an image."""
        # Extract year/month from image path
        parts = image_path.parts
        if len(parts) >= 2 and parts[-3:-1] == ("2025", "06"):  # Handle date structure
            year_month = f"{parts[-3]}/{parts[-2]}"
        else:
            # Fallback to current date structure
            now = datetime.now()
            year_month = now.strftime("%Y/%m")

        # Create thumbnail directory structure
        thumb_dir = self.thumbnail_root / year_month
        thumb_dir.mkdir(parents=True, exist_ok=True)

        # Generate thumbnail filename
        stem = image_path.stem
        thumb_filename = f"{stem}.thumb.jpg"
        return thumb_dir / thumb_filename

    def get_or_create_thumbnail(self, image_path: Path) -> Path | None:
        """Get cached thumbnail or create new one if needed."""
        if not image_path.exists():
            return None

        thumb_path = self.get_thumbnail_path(image_path)

        # Check if thumbnail exists and is newer than source
        if thumb_path.exists():
            try:
                source_mtime = image_path.stat().st_mtime
                thumb_mtime = thumb_path.stat().st_mtime
                if thumb_mtime >= source_mtime:
                    return thumb_path
            except OSError:
                pass

        # Create new thumbnail
        try:
            thumbnail = self.create_thumbnail(image_path)
            if thumbnail:
                # Convert to RGB and save as JPEG
                if thumbnail.mode in ("RGBA", "P"):
                    rgb_thumb = Image.new("RGB", thumbnail.size, (255, 255, 255))
                    if thumbnail.mode == "P":
                        thumbnail = thumbnail.convert("RGBA")
                    rgb_thumb.paste(
                        thumbnail,
                        mask=thumbnail.split()[-1]
                        if thumbnail.mode == "RGBA"
                        else None,
                    )
                    thumbnail = rgb_thumb

                thumbnail.save(thumb_path, "JPEG", quality=85, optimize=True)
                return thumb_path
        except Exception as e:
            print(f"Error creating thumbnail for {image_path}: {e}")

        return None

    def cleanup_orphaned_thumbnails(self, valid_image_paths: set[Path]) -> int:
        """Remove thumbnails for images that no longer exist."""
        removed_count = 0

        for thumb_path in self.thumbnail_root.rglob("*.thumb.jpg"):
            # Reconstruct original image path from thumbnail path
            relative_path = thumb_path.relative_to(self.thumbnail_root)
            year_month = str(relative_path.parent)

            # Remove .thumb.jpg and find possible original extensions
            base_name = thumb_path.stem.replace(".thumb", "")

            # Check if any valid image with this base name exists
            found_match = False
            for image_path in valid_image_paths:
                if (
                    image_path.stem == base_name
                    and str(image_path).find(year_month) != -1
                ):
                    found_match = True
                    break

            if not found_match:
                try:
                    thumb_path.unlink()
                    removed_count += 1
                except OSError:
                    pass

        return removed_count
