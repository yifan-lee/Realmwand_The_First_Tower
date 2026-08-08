#!/usr/bin/env python3
"""Build a no-gap, original-resolution environment tile atlas."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from split_concept_sheets import (
    assign_components,
    find_components,
    isolate_assets,
    square_canvases,
)


COLUMNS = 5
ROWS = 4
NAMES = (
    "floor_neutral",
    "floor_atk",
    "floor_def",
    "floor_spd",
    "floor_one_way_hole",
    "wall_block",
    "wall_straight",
    "wall_corner",
    "wall_junction",
    "wall_pillar",
    "door_locked",
    "door_open",
    "stairs_up",
    "stairs_down",
    "one_way_threshold",
    "portal_inactive",
    "portal_active",
    "mechanism_off",
    "mechanism_on",
    "pressure_plate",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path(
            "assets/backup/concepts/unfinished_world/transparent/"
            "environment_tiles_sheet_wall_matched.png"
        ),
    )
    parser.add_argument(
        "--frames-directory",
        type=Path,
        default=Path(
            "assets/backup/concepts/unfinished_world/split_original/"
            "tiles_wall_matched"
        ),
    )
    parser.add_argument(
        "--atlas",
        type=Path,
        default=Path(
            "assets/backup/tiles/unfinished_world_tiles_original.png"
        ),
    )
    parser.add_argument("--preview", type=Path)
    return parser.parse_args()


def create_preview(atlas: Image.Image, output_path: Path) -> None:
    checker = Image.new("RGBA", atlas.size, (225, 225, 225, 255))
    draw = ImageDraw.Draw(checker)
    checker_size = 16
    for y in range(0, checker.height, checker_size):
        for x in range(0, checker.width, checker_size):
            if (x // checker_size + y // checker_size) % 2 == 0:
                draw.rectangle(
                    (
                        x,
                        y,
                        x + checker_size - 1,
                        y + checker_size - 1,
                    ),
                    fill=(185, 185, 185, 255),
                )
    checker.alpha_composite(atlas)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    checker.convert("RGB").save(output_path)


def make_edge_to_edge_tiles(
    padded_tiles: list[Image.Image],
) -> list[Image.Image]:
    """Remove internal transparent margins and make every cell fully opaque."""

    tile_size = padded_tiles[0].width
    resampling = getattr(Image, "Resampling", Image).LANCZOS
    edge_to_edge_tiles: list[Image.Image] = []

    for tile in padded_tiles:
        alpha_bounds = tile.getchannel("A").getbbox()
        if alpha_bounds is None:
            raise RuntimeError("An environment tile is empty.")

        trimmed = tile.crop(alpha_bounds)
        side = max(trimmed.size)
        square = Image.new("RGBA", (side, side), (0, 0, 0, 255))
        square.alpha_composite(
            trimmed,
            (
                (side - trimmed.width) // 2,
                (side - trimmed.height) // 2,
            ),
        )
        edge_to_edge_tiles.append(
            square.resize((tile_size, tile_size), resampling)
        )

    return edge_to_edge_tiles


def validate_edge_to_edge_tiles(
    directory: Path,
) -> None:
    expected_size: tuple[int, int] | None = None
    for name in NAMES:
        path = directory / f"{name}.png"
        with Image.open(path) as image:
            tile = image.convert("RGBA")
        if expected_size is None:
            expected_size = tile.size
        elif tile.size != expected_size:
            raise RuntimeError(f"{path} has an inconsistent size.")
        if tile.width != tile.height:
            raise RuntimeError(f"{path} is not square.")
        if tile.getchannel("A").getextrema() != (255, 255):
            raise RuntimeError(f"{path} still contains transparent pixels.")


def main() -> None:
    arguments = parse_args()
    project_root = arguments.project_root.resolve()
    source_path = project_root / arguments.source
    frames_directory = project_root / arguments.frames_directory
    atlas_path = project_root / arguments.atlas

    with Image.open(source_path) as image:
        source = image.convert("RGBA")
    rgba = np.asarray(source)
    components = find_components(rgba[:, :, 3] > 0, minimum_area=12)
    assignments = assign_components(
        components,
        source.width,
        source.height,
        COLUMNS,
        ROWS,
    )
    isolated = isolate_assets(rgba, assignments)
    padded_tiles = square_canvases(isolated)
    tiles = make_edge_to_edge_tiles(padded_tiles)

    frames_directory.mkdir(parents=True, exist_ok=True)
    for name, tile in zip(NAMES, tiles, strict=True):
        tile.save(frames_directory / f"{name}.png")
    validate_edge_to_edge_tiles(frames_directory)

    tile_size = tiles[0].width
    atlas = Image.new(
        "RGBA",
        (COLUMNS * tile_size, ROWS * tile_size),
        (0, 0, 0, 0),
    )
    entries: list[dict[str, object]] = []
    for index, (name, tile) in enumerate(zip(NAMES, tiles, strict=True)):
        column = index % COLUMNS
        row = index // COLUMNS
        x = column * tile_size
        y = row * tile_size
        atlas.alpha_composite(tile, (x, y))
        entries.append(
            {
                "name": name,
                "atlas_coords": [column, row],
                "pixel_rect": [x, y, tile_size, tile_size],
            }
        )

    atlas_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(atlas_path)
    manifest_path = atlas_path.with_suffix(".json")
    manifest_path.write_text(
        json.dumps(
            {
                "image": str(atlas_path.relative_to(project_root)),
                "columns": COLUMNS,
                "rows": ROWS,
                "tile_size": tile_size,
                "size": [atlas.width, atlas.height],
                "entries": entries,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    if arguments.preview is not None:
        create_preview(atlas, project_root / arguments.preview)

    print(
        f"Built {len(tiles)} tiles at {tile_size}px: "
        f"{atlas_path.relative_to(project_root)}"
    )


if __name__ == "__main__":
    main()
