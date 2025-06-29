"""Database manager for handling meme metadata and tags."""

import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Any


class DatabaseManager:
    """Manages SQLite database operations for meme metadata."""

    def __init__(self, db_path: str = "mememanager.db"):
        """Initialize database manager with given database path."""
        self.db_path = Path(db_path)
        self.init_database()

    def init_database(self) -> None:
        """Initialize database and create tables if they don't exist."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Create images table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS images (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    filename TEXT NOT NULL UNIQUE,
                    original_name TEXT NOT NULL,
                    path TEXT NOT NULL,
                    created_date TEXT NOT NULL,
                    updated_date TEXT NOT NULL
                )
            """)

            # Create tags table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS tags (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL UNIQUE
                )
            """)

            # Create junction table for image-tag relationships
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS image_tags (
                    image_id INTEGER NOT NULL,
                    tag_id INTEGER NOT NULL,
                    PRIMARY KEY (image_id, tag_id),
                    FOREIGN KEY (image_id) REFERENCES images (id) ON DELETE CASCADE,
                    FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
                )
            """)

            # Create indexes for better search performance
            cursor.execute(
                "CREATE INDEX IF NOT EXISTS idx_images_filename ON images(filename)"
            )
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name)")

            conn.commit()

    def add_image(self, filename: str, original_name: str, path: str) -> int:
        """Add a new image to the database and return its ID."""
        now = datetime.now().isoformat()

        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO images (filename, original_name, path, created_date, updated_date)
                VALUES (?, ?, ?, ?, ?)
            """,
                (filename, original_name, path, now, now),
            )
            result = cursor.lastrowid
            if result is None:
                raise RuntimeError("Failed to insert image")
            return result

    def update_image(
        self,
        image_id: int,
        filename: str | None = None,
        original_name: str | None = None,
    ) -> bool:
        """Update image information."""
        if not filename and not original_name:
            return False

        now = datetime.now().isoformat()
        updates = ["updated_date = ?"]
        values: list[str | int] = [now]

        if filename:
            updates.append("filename = ?")
            values.append(filename)

        if original_name:
            updates.append("original_name = ?")
            values.append(original_name)

        values.append(image_id)

        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            query = f"UPDATE images SET {', '.join(updates)} WHERE id = ?"
            cursor.execute(query, values)
            return cursor.rowcount > 0

    def delete_image(self, image_id: int) -> bool:
        """Delete an image and its associated tags."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM images WHERE id = ?", (image_id,))
            return cursor.rowcount > 0

    def get_image(self, image_id: int) -> dict[str, Any] | None:
        """Get image information by ID."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM images WHERE id = ?", (image_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def get_all_images(self) -> list[dict[str, Any]]:
        """Get all images from the database."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM images ORDER BY created_date DESC")
            return [dict(row) for row in cursor.fetchall()]

    def add_tag(self, name: str) -> int:
        """Add a new tag and return its ID, or return existing tag ID."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            try:
                cursor.execute("INSERT INTO tags (name) VALUES (?)", (name,))
                result = cursor.lastrowid
                if result is None:
                    raise RuntimeError("Failed to insert tag")
                return result
            except sqlite3.IntegrityError:
                # Tag already exists, return its ID
                cursor.execute("SELECT id FROM tags WHERE name = ?", (name,))
                row = cursor.fetchone()
                if row is None:
                    raise RuntimeError("Tag not found after insert failure") from None
                return int(row[0])

    def get_tag_by_name(self, name: str) -> dict[str, Any] | None:
        """Get tag information by name."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM tags WHERE name = ?", (name,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def get_all_tags(self) -> list[dict[str, Any]]:
        """Get all tags from the database."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM tags ORDER BY name")
            return [dict(row) for row in cursor.fetchall()]

    def add_image_tag(self, image_id: int, tag_id: int) -> bool:
        """Associate a tag with an image."""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO image_tags (image_id, tag_id) VALUES (?, ?)",
                    (image_id, tag_id),
                )
                return True
        except sqlite3.IntegrityError:
            return False  # Association already exists

    def remove_image_tag(self, image_id: int, tag_id: int) -> bool:
        """Remove tag association from an image."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "DELETE FROM image_tags WHERE image_id = ? AND tag_id = ?",
                (image_id, tag_id),
            )
            return cursor.rowcount > 0

    def get_image_tags(self, image_id: int) -> list[dict[str, Any]]:
        """Get all tags for a specific image."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT t.* FROM tags t
                JOIN image_tags it ON t.id = it.tag_id
                WHERE it.image_id = ?
                ORDER BY t.name
            """,
                (image_id,),
            )
            return [dict(row) for row in cursor.fetchall()]

    def search_images(self, query: str) -> list[dict[str, Any]]:
        """Search images by filename, original name, or tags."""
        search_term = f"%{query}%"

        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()

            # Search in image names and tags
            cursor.execute(
                """
                SELECT DISTINCT i.* FROM images i
                LEFT JOIN image_tags it ON i.id = it.image_id
                LEFT JOIN tags t ON it.tag_id = t.id
                WHERE i.filename LIKE ? OR i.original_name LIKE ? OR t.name LIKE ?
                ORDER BY i.created_date DESC
            """,
                (search_term, search_term, search_term),
            )

            return [dict(row) for row in cursor.fetchall()]

    def get_images_by_tag(self, tag_name: str) -> list[dict[str, Any]]:
        """Get all images that have a specific tag."""
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT i.* FROM images i
                JOIN image_tags it ON i.id = it.image_id
                JOIN tags t ON it.tag_id = t.id
                WHERE t.name = ?
                ORDER BY i.created_date DESC
            """,
                (tag_name,),
            )
            return [dict(row) for row in cursor.fetchall()]

    def get_database_stats(self) -> dict[str, int]:
        """Get database statistics."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT COUNT(*) FROM images")
            image_count = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM tags")
            tag_count = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM image_tags")
            association_count = cursor.fetchone()[0]

            return {
                "images": image_count,
                "tags": tag_count,
                "associations": association_count,
            }
