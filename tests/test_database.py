"""Tests for database manager."""

import tempfile
from pathlib import Path

from src.database.manager import DatabaseManager


def test_database_initialization() -> None:
    """Test database initialization."""
    with tempfile.TemporaryDirectory() as tmpdir:
        db_path = Path(tmpdir) / "test.db"
        manager = DatabaseManager(str(db_path))

        # Database should be created
        assert db_path.exists()

        # Should be able to get empty stats
        stats = manager.get_database_stats()
        assert stats["images"] == 0
        assert stats["tags"] == 0


def test_tag_operations() -> None:
    """Test tag operations."""
    with tempfile.TemporaryDirectory() as tmpdir:
        db_path = Path(tmpdir) / "test.db"
        manager = DatabaseManager(str(db_path))

        # Add a tag
        tag_id = manager.add_tag("funny")
        assert tag_id > 0

        # Adding same tag should return same ID
        tag_id2 = manager.add_tag("funny")
        assert tag_id == tag_id2

        # Get tag by name
        tag = manager.get_tag_by_name("funny")
        assert tag is not None
        assert tag["name"] == "funny"
        assert tag["id"] == tag_id


def test_image_operations() -> None:
    """Test image operations."""
    with tempfile.TemporaryDirectory() as tmpdir:
        db_path = Path(tmpdir) / "test.db"
        manager = DatabaseManager(str(db_path))

        # Add an image
        image_id = manager.add_image("test.jpg", "original.jpg", "/path/to/test.jpg")
        assert image_id > 0

        # Get the image
        image = manager.get_image(image_id)
        assert image is not None
        assert image["filename"] == "test.jpg"
        assert image["original_name"] == "original.jpg"

        # Update the image
        success = manager.update_image(image_id, filename="updated.jpg")
        assert success

        # Verify update
        updated_image = manager.get_image(image_id)
        assert updated_image is not None
        assert updated_image["filename"] == "updated.jpg"
