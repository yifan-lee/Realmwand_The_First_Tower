#!/usr/bin/env python3
"""Build strict 32px atlases from the isolated unfinished-world concept art."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


TILE_SIZE = 32


@dataclass(frozen=True)
class Placement:
    name: str
    source: str
    column: int
    row: int


@dataclass(frozen=True)
class AtlasSpec:
    key: str
    filename: str
    columns: int
    rows: int
    placements: tuple[Placement, ...]


def _grid_placements(
    names: tuple[str, ...],
    source_directory: str,
    columns: int,
    row_offset: int = 0,
) -> tuple[Placement, ...]:
    return tuple(
        Placement(
            name=name,
            source=f"{source_directory}/{name}.png",
            column=index % columns,
            row=index // columns + row_offset,
        )
        for index, name in enumerate(names)
    )


ENVIRONMENT_NAMES = (
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

WEARABLE_NAMES = tuple(
    f"{slot}_tier_{tier}"
    for tier in range(1, 5)
    for slot in (
        "head_mp",
        "chest_def",
        "legs_hp",
        "hands_atk",
        "feet_spd",
    )
)

WEAPON_NAMES = tuple(
    f"{weapon}_tier_{tier}"
    for tier in range(1, 5)
    for weapon in (
        "one_hand_sword_atk",
        "two_hand_sword_atk",
        "dagger_spd",
        "shield_def",
        "staff_mp",
        "one_hand_dao_hp",
        "two_hand_dao_hp",
    )
)

INTERACTABLE_NAMES = tuple(
    f"{kind}_{attribute}"
    for kind in ("npc", "statue", "terminal")
    for attribute in ("atk", "def", "spd", "universal")
)

ITEM_NAMES = tuple(
    f"{item}_tier_{tier}"
    for tier in range(1, 5)
    for item in (
        "hp",
        "mp",
        "atk_token",
        "def_token",
        "spd_token",
        "universal_token",
    )
)

MONSTER_NAMES = tuple(
    f"{archetype}_tier_{tier}"
    for tier in range(1, 5)
    for archetype in ("atk", "def", "spd", "balanced")
)

ATLASES = (
    AtlasSpec(
        "environment",
        "unfinished_world_tiles_32.png",
        5,
        4,
        _grid_placements(ENVIRONMENT_NAMES, "tiles", 5),
    ),
    AtlasSpec(
        "equipment",
        "unfinished_world_equipment_32.png",
        7,
        8,
        (
            *_grid_placements(
                WEARABLE_NAMES,
                "equipment/wearable_v2",
                5,
            ),
            *_grid_placements(
                WEAPON_NAMES,
                "equipment/weapons_v2",
                7,
                row_offset=4,
            ),
        ),
    ),
    AtlasSpec(
        "interactables",
        "unfinished_world_interactables_32.png",
        4,
        3,
        _grid_placements(INTERACTABLE_NAMES, "interactables", 4),
    ),
    AtlasSpec(
        "items",
        "unfinished_world_items_32.png",
        6,
        4,
        _grid_placements(ITEM_NAMES, "items", 6),
    ),
    AtlasSpec(
        "monsters",
        "unfinished_world_monsters_32.png",
        4,
        4,
        _grid_placements(MONSTER_NAMES, "monsters", 4),
    ),
)


def build_atlas(
    project_root: Path,
    source_root: Path,
    output_root: Path,
    spec: AtlasSpec,
) -> dict[str, object]:
    atlas = Image.new(
        "RGBA",
        (spec.columns * TILE_SIZE, spec.rows * TILE_SIZE),
        (0, 0, 0, 0),
    )
    resampling = getattr(Image, "Resampling", Image).LANCZOS
    entries: list[dict[str, object]] = []

    for placement in spec.placements:
        source_path = source_root / placement.source
        with Image.open(source_path) as image:
            tile = image.convert("RGBA").resize(
                (TILE_SIZE, TILE_SIZE),
                resampling,
            )
        if tile.getchannel("A").getbbox() is None:
            raise RuntimeError(f"{source_path} is empty.")

        pixel_x = placement.column * TILE_SIZE
        pixel_y = placement.row * TILE_SIZE
        atlas.alpha_composite(tile, (pixel_x, pixel_y))
        entries.append(
            {
                "name": placement.name,
                "atlas_coords": [placement.column, placement.row],
                "pixel_rect": [pixel_x, pixel_y, TILE_SIZE, TILE_SIZE],
                "source": str(source_path.relative_to(project_root)),
            }
        )

    output_path = output_root / spec.filename
    output_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output_path)

    return {
        "image": str(output_path.relative_to(project_root)),
        "columns": spec.columns,
        "rows": spec.rows,
        "size": [atlas.width, atlas.height],
        "entries": entries,
    }


def create_preview(atlas_path: Path, preview_path: Path) -> None:
    with Image.open(atlas_path) as image:
        atlas = image.convert("RGBA")
    background = Image.new("RGBA", atlas.size, (233, 228, 216, 255))
    background.alpha_composite(atlas)
    resampling = getattr(Image, "Resampling", Image).NEAREST
    preview = background.resize(
        (background.width * 4, background.height * 4),
        resampling,
    )
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(preview_path)


def create_preview_overview(preview_directory: Path) -> None:
    cell_width = 600
    cell_height = 700
    overview = Image.new("RGB", (cell_width * 3, cell_height * 2), (96, 96, 96))
    resampling = getattr(Image, "Resampling", Image).LANCZOS

    for index, spec in enumerate(ATLASES):
        preview_path = preview_directory / spec.filename
        with Image.open(preview_path) as image:
            preview = image.convert("RGB")
        preview.thumbnail((cell_width - 32, cell_height - 32), resampling)
        column = index % 3
        row = index // 3
        offset = (
            column * cell_width + (cell_width - preview.width) // 2,
            row * cell_height + (cell_height - preview.height) // 2,
        )
        overview.paste(preview, offset)

    overview.save(preview_directory / "unfinished_world_atlases_overview.png")


def validate_atlas(path: Path, spec: AtlasSpec) -> None:
    with Image.open(path) as image:
        if image.mode != "RGBA":
            raise RuntimeError(f"{path} is not RGBA.")
        if image.size != (
            spec.columns * TILE_SIZE,
            spec.rows * TILE_SIZE,
        ):
            raise RuntimeError(f"{path} has the wrong dimensions.")

        alpha = image.getchannel("A")
        occupied_cells = {
            (placement.column, placement.row) for placement in spec.placements
        }
        for row in range(spec.rows):
            for column in range(spec.columns):
                box = (
                    column * TILE_SIZE,
                    row * TILE_SIZE,
                    (column + 1) * TILE_SIZE,
                    (row + 1) * TILE_SIZE,
                )
                has_content = alpha.crop(box).getbbox() is not None
                should_have_content = (column, row) in occupied_cells
                if has_content != should_have_content:
                    state = "unexpected content" if has_content else "empty tile"
                    raise RuntimeError(
                        f"{path} has {state} at {column},{row}."
                    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path("."))
    parser.add_argument(
        "--source-root",
        type=Path,
        default=Path("assets/concepts/unfinished_world/split"),
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=Path("assets/tiles"),
    )
    parser.add_argument("--preview-directory", type=Path)
    arguments = parser.parse_args()

    project_root = arguments.project_root.resolve()
    source_root = (project_root / arguments.source_root).resolve()
    output_root = (project_root / arguments.output_root).resolve()
    manifest: dict[str, object] = {
        "tile_size": [TILE_SIZE, TILE_SIZE],
        "atlases": {},
    }

    for spec in ATLASES:
        atlas_data = build_atlas(
            project_root,
            source_root,
            output_root,
            spec,
        )
        atlas_path = output_root / spec.filename
        validate_atlas(atlas_path, spec)
        manifest["atlases"][spec.key] = atlas_data
        if arguments.preview_directory is not None:
            create_preview(
                atlas_path,
                arguments.preview_directory / spec.filename,
            )
        print(
            f"{spec.filename}: "
            f"{spec.columns}x{spec.rows} cells, "
            f"{atlas_path.stat().st_size} bytes"
        )
    if arguments.preview_directory is not None:
        create_preview_overview(arguments.preview_directory)

    manifest_path = output_root / "unfinished_world_atlases_32.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
