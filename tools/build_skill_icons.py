#!/usr/bin/env python3
"""Split high-resolution skill sheets into consistent square icon files."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from split_concept_sheets import (
    assign_components,
    find_components,
    isolate_assets,
)


@dataclass(frozen=True)
class SkillSheetSpec:
    filename: str
    category: str
    columns: int
    rows: int
    families: tuple[str, ...]
    grid_crop: bool = False

    @property
    def names(self) -> tuple[str, ...]:
        return tuple(
            f"{family}_tier_{tier}"
            for tier in range(1, self.rows + 1)
            for family in self.families
        )


SHEETS = (
    SkillSheetSpec(
        "physical_weapons_sheet.png",
        "physical",
        4,
        4,
        (
            "sword_slash",
            "greatsword_cleave",
            "spear_thrust",
            "hammer_smash",
        ),
    ),
    SkillSheetSpec(
        "physical_agile_sheet.png",
        "physical",
        4,
        4,
        (
            "dagger_stab",
            "dual_blade_slash",
            "bow_power_shot",
            "fist_punch",
        ),
    ),
    SkillSheetSpec(
        "magic_elements_sheet.png",
        "magic",
        4,
        4,
        (
            "fire_burst",
            "ice_shard",
            "lightning_orb",
            "earth_spike",
        ),
    ),
    SkillSheetSpec(
        "magic_polarities_sheet.png",
        "magic",
        4,
        4,
        (
            "wind_vortex",
            "water_orb",
            "shadow_orb",
            "holy_ray",
        ),
    ),
    SkillSheetSpec(
        "magic_advanced_sheet.png",
        "magic",
        4,
        4,
        (
            "poison_burst",
            "arcane_missile",
            "gravity_well",
            "meteor_fall",
        ),
        True,
    ),
    SkillSheetSpec(
        "support_stats_sheet.png",
        "support",
        5,
        4,
        (
            "buff_atk",
            "buff_def",
            "buff_spd",
            "buff_hp",
            "buff_mp",
        ),
    ),
)
FOREGROUND_ALPHA_THRESHOLD = 16


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
    )
    parser.add_argument(
        "--asset-root",
        type=Path,
        default=Path("assets/skills"),
    )
    parser.add_argument("--preview", type=Path)
    return parser.parse_args()


def load_icons(
    transparent_root: Path,
) -> dict[SkillSheetSpec, list[Image.Image]]:
    icons: dict[SkillSheetSpec, list[Image.Image]] = {}
    for spec in SHEETS:
        source_path = transparent_root / spec.filename
        with Image.open(source_path) as image:
            source = image.convert("RGBA")
        rgba = np.asarray(source)
        if spec.grid_crop:
            isolated: list[Image.Image] = []
            for row in range(spec.rows):
                for column in range(spec.columns):
                    box = (
                        round(column * source.width / spec.columns),
                        round(row * source.height / spec.rows),
                        round((column + 1) * source.width / spec.columns),
                        round((row + 1) * source.height / spec.rows),
                    )
                    cell = source.crop(box)
                    cell_alpha = np.asarray(cell.getchannel("A"))
                    foreground = np.where(
                        cell_alpha >= FOREGROUND_ALPHA_THRESHOLD,
                        255,
                        0,
                    ).astype(np.uint8)
                    bounds = Image.fromarray(foreground).getbbox()
                    if bounds is None:
                        raise RuntimeError(f"{source_path}: empty grid cell.")
                    isolated.append(cell.crop(bounds))
            icons[spec] = isolated
            continue

        components = find_components(
            rgba[:, :, 3] >= FOREGROUND_ALPHA_THRESHOLD,
            minimum_area=12,
        )
        try:
            assignments = assign_components(
                components,
                source.width,
                source.height,
                spec.columns,
                spec.rows,
            )
        except RuntimeError as error:
            raise RuntimeError(f"{source_path}: {error}") from error
        isolated = isolate_assets(rgba, assignments)
        if len(isolated) != len(spec.names):
            raise RuntimeError(
                f"{source_path}: expected {len(spec.names)} icons, "
                f"found {len(isolated)}."
            )
        icons[spec] = isolated
    return icons


def create_canvases(
    icons: dict[SkillSheetSpec, list[Image.Image]],
) -> tuple[dict[SkillSheetSpec, list[Image.Image]], int]:
    maximum_extent = max(
        max(icon.size)
        for sheet_icons in icons.values()
        for icon in sheet_icons
    )
    padding = max(12, round(maximum_extent * 0.04))
    side = maximum_extent + padding * 2
    canvases: dict[SkillSheetSpec, list[Image.Image]] = {}

    for spec, sheet_icons in icons.items():
        sheet_canvases: list[Image.Image] = []
        for icon in sheet_icons:
            canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
            canvas.alpha_composite(
                icon,
                (
                    (side - icon.width) // 2,
                    (side - icon.height) // 2,
                ),
            )
            sheet_canvases.append(canvas)
        canvases[spec] = sheet_canvases
    return canvases, side


def save_icons(
    asset_root: Path,
    canvases: dict[SkillSheetSpec, list[Image.Image]],
    side: int,
) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    for spec, sheet_canvases in canvases.items():
        output_directory = asset_root / spec.category
        output_directory.mkdir(parents=True, exist_ok=True)
        for index, (name, canvas) in enumerate(
            zip(spec.names, sheet_canvases, strict=True)
        ):
            output_path = output_directory / f"{name}.png"
            canvas.save(output_path)
            alpha = np.asarray(canvas.getchannel("A"))
            if not np.any(alpha):
                raise RuntimeError(f"{output_path} is empty.")
            border = np.concatenate(
                (alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1])
            )
            if np.any(border):
                raise RuntimeError(
                    f"{output_path} touches its canvas border."
                )
            entries.append(
                {
                    "name": name,
                    "category": spec.category,
                    "family": spec.families[index % spec.columns],
                    "tier": index // spec.columns + 1,
                    "image": str(
                        output_path.relative_to(asset_root.parents[1])
                    ),
                    "source_sheet": str(
                        (asset_root / "source" / spec.filename).relative_to(
                            asset_root.parents[1]
                        )
                    ),
                    "source_coords": [
                        index % spec.columns,
                        index // spec.columns,
                    ],
                    "size": [side, side],
                }
            )
    return entries


def create_preview(
    asset_root: Path,
    entries: list[dict[str, object]],
    output_path: Path,
) -> None:
    columns = 10
    cell_size = 96
    rows = (len(entries) + columns - 1) // columns
    preview = Image.new(
        "RGBA",
        (columns * cell_size, rows * cell_size),
        (224, 224, 224, 255),
    )
    draw = ImageDraw.Draw(preview)
    for y in range(0, preview.height, 12):
        for x in range(0, preview.width, 12):
            if (x // 12 + y // 12) % 2 == 0:
                draw.rectangle(
                    (x, y, x + 11, y + 11),
                    fill=(184, 184, 184, 255),
                )

    resampling = getattr(Image, "Resampling", Image).LANCZOS
    for index, entry in enumerate(entries):
        image_path = asset_root.parents[1] / str(entry["image"])
        with Image.open(image_path) as image:
            icon = image.convert("RGBA")
        icon.thumbnail((cell_size - 8, cell_size - 8), resampling)
        column = index % columns
        row = index // columns
        preview.alpha_composite(
            icon,
            (
                column * cell_size + (cell_size - icon.width) // 2,
                row * cell_size + (cell_size - icon.height) // 2,
            ),
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(output_path)


def main() -> None:
    arguments = parse_args()
    project_root = arguments.project_root.resolve()
    asset_root = project_root / arguments.asset_root
    icons = load_icons(asset_root / "transparent")
    canvases, side = create_canvases(icons)
    entries = save_icons(asset_root, canvases, side)

    manifest_path = asset_root / "skills_manifest.json"
    manifest_path.write_text(
        json.dumps(
            {
                "icon_count": len(entries),
                "icon_size": [side, side],
                "categories": {
                    category: sum(
                        entry["category"] == category for entry in entries
                    )
                    for category in ("physical", "magic", "support")
                },
                "entries": entries,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    if arguments.preview is not None:
        create_preview(
            asset_root,
            entries,
            project_root / arguments.preview,
        )

    print(f"Built {len(entries)} skill icons at {side}px.")
    print(f"Manifest: {manifest_path.relative_to(project_root)}")


if __name__ == "__main__":
    main()
