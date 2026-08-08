#!/usr/bin/env python3
"""Split generated player action sheets and build strict square-cell atlases."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


SOURCE_CELL_SIZE = 313
BASE_CELL_SIZE = 400
ALPHA_THRESHOLD = 1
COMPONENT_DILATION_SIZE = 11
FRAME_MARGIN = 16
DIRECTIONS = ("down", "left", "right", "up")
OUTPUT_SIZES = (256, 32)


@dataclass(frozen=True)
class ActionSpec:
    name: str
    filename: str
    columns: int
    frame_duration: float
    loop: bool


ACTIONS = (
    ActionSpec("walk", "player_walk_sheet.png", 4, 0.12, True),
    ActionSpec("attack", "player_attack_sheet.png", 4, 0.09, False),
    ActionSpec("hurt", "player_hurt_sheet.png", 2, 0.14, False),
    ActionSpec("interact", "player_interact_sheet.png", 3, 0.18, False),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
    )
    parser.add_argument(
        "--preview-directory",
        type=Path,
        default=None,
    )
    return parser.parse_args()


def _find_component_owners(
    source: Image.Image,
    columns: int,
) -> np.ndarray:
    """Assign complete foreground components to their nearest animation cell.

    Image-generated poses are not guaranteed to remain inside the nominal grid.
    Assigning connected foreground regions first prevents an arm, weapon, or
    effect from being split between two frames.
    """

    alpha = np.asarray(source.getchannel("A"), dtype=np.uint8)
    binary = Image.fromarray(
        np.where(alpha >= ALPHA_THRESHOLD, 255, 0).astype(np.uint8),
        mode="L",
    )
    expanded = binary.filter(
        ImageFilter.MaxFilter(COMPONENT_DILATION_SIZE),
    )
    mask = np.asarray(expanded, dtype=np.uint8) > 0

    parent: list[int] = []
    runs: list[tuple[int, int, int, int]] = []
    previous_runs: list[tuple[int, int, int]] = []

    def find(label: int) -> int:
        root = label
        while parent[root] != root:
            root = parent[root]
        while parent[label] != label:
            next_label = parent[label]
            parent[label] = root
            label = next_label
        return root

    def union(first: int, second: int) -> None:
        first_root = find(first)
        second_root = find(second)
        if first_root != second_root:
            parent[second_root] = first_root

    for y, row in enumerate(mask):
        edges = np.diff(np.pad(row.astype(np.int8), (1, 1)))
        starts = np.flatnonzero(edges == 1)
        ends = np.flatnonzero(edges == -1) - 1
        current_runs: list[tuple[int, int, int]] = []
        previous_index = 0

        for start_value, end_value in zip(starts, ends, strict=True):
            start = int(start_value)
            end = int(end_value)
            label = len(parent)
            parent.append(label)

            while (
                previous_index < len(previous_runs)
                and previous_runs[previous_index][1] < start - 1
            ):
                previous_index += 1

            overlap_index = previous_index
            while (
                overlap_index < len(previous_runs)
                and previous_runs[overlap_index][0] <= end + 1
            ):
                union(label, previous_runs[overlap_index][2])
                overlap_index += 1

            current_runs.append((start, end, label))
            runs.append((y, start, end, label))

        previous_runs = current_runs

    component_stats: dict[int, list[float]] = {}
    for y, start, end, label in runs:
        root = find(label)
        length = end - start + 1
        stats = component_stats.setdefault(root, [0.0, 0.0, 0.0])
        stats[0] += (start + end) * length / 2
        stats[1] += y * length
        stats[2] += length

    frame_anchors = [
        (
            (column + 0.5) * source.width / columns,
            (row + 0.5) * source.height / len(DIRECTIONS),
        )
        for row in range(len(DIRECTIONS))
        for column in range(columns)
    ]
    cell_width = source.width / columns
    cell_height = source.height / len(DIRECTIONS)
    component_owner: dict[int, int] = {}
    for root, (sum_x, sum_y, count) in component_stats.items():
        center_x = sum_x / count
        center_y = sum_y / count
        component_owner[root] = min(
            range(len(frame_anchors)),
            key=lambda index: (
                (center_x - frame_anchors[index][0]) / cell_width
            )
            ** 2
            + (
                (center_y - frame_anchors[index][1]) / cell_height
            )
            ** 2,
        )

    owners = np.full(mask.shape, -1, dtype=np.int16)
    for y, start, end, label in runs:
        owners[y, start : end + 1] = component_owner[find(label)]
    return owners


def _center_component(
    source: Image.Image,
    owners: np.ndarray,
    owner_index: int,
    frame_name: str,
) -> Image.Image:
    source_pixels = np.asarray(source, dtype=np.uint8)
    alpha = source_pixels[:, :, 3]
    frame_pixels = source_pixels.copy()
    frame_pixels[:, :, 3] = np.where(
        owners == owner_index,
        alpha,
        0,
    ).astype(np.uint8)
    isolated = Image.fromarray(frame_pixels, mode="RGBA")
    alpha_bounds = isolated.getchannel("A").getbbox()
    if alpha_bounds is None:
        raise RuntimeError(f"{frame_name}: frame is empty.")

    content = isolated.crop(alpha_bounds)
    content_alpha = np.asarray(content.getchannel("A"), dtype=np.uint8)
    max_content_size = BASE_CELL_SIZE - FRAME_MARGIN * 2
    scale = min(
        1.0,
        max_content_size / content.width,
        max_content_size / content.height,
    )
    if scale < 1.0:
        content = content.resize(
            (
                max(1, round(content.width * scale)),
                max(1, round(content.height * scale)),
            ),
            getattr(Image, "Resampling", Image).LANCZOS,
        )
        content_alpha = np.asarray(content.getchannel("A"), dtype=np.uint8)

    column_weights = content_alpha.sum(axis=0, dtype=np.uint64)
    row_weights = content_alpha.sum(axis=1, dtype=np.uint64)
    center_x = int(
        np.searchsorted(
            np.cumsum(column_weights),
            column_weights.sum() / 2,
        )
    )
    center_y = int(
        np.searchsorted(
            np.cumsum(row_weights),
            row_weights.sum() / 2,
        )
    )
    desired_x = BASE_CELL_SIZE // 2 - center_x
    desired_y = BASE_CELL_SIZE // 2 - center_y
    paste_x = min(
        max(desired_x, FRAME_MARGIN),
        BASE_CELL_SIZE - FRAME_MARGIN - content.width,
    )
    paste_y = min(
        max(desired_y, FRAME_MARGIN),
        BASE_CELL_SIZE - FRAME_MARGIN - content.height,
    )
    frame = Image.new(
        "RGBA",
        (BASE_CELL_SIZE, BASE_CELL_SIZE),
        (0, 0, 0, 0),
    )
    frame.alpha_composite(content, (paste_x, paste_y))
    return frame


def _load_frames(
    transparent_root: Path,
) -> dict[tuple[str, str, int], Image.Image]:
    frames: dict[tuple[str, str, int], Image.Image] = {}

    for action in ACTIONS:
        source_path = transparent_root / action.filename
        with Image.open(source_path) as image:
            source = image.convert("RGBA")

        if (
            source.width < SOURCE_CELL_SIZE * action.columns
            or source.height < SOURCE_CELL_SIZE * len(DIRECTIONS)
        ):
            raise RuntimeError(
                f"{source_path}: source size {source.size} is too small."
            )

        owners = _find_component_owners(source, action.columns)
        for row, direction in enumerate(DIRECTIONS):
            for column in range(action.columns):
                frame_name = f"{action.name}_{direction}_{column:02d}"
                owner_index = row * action.columns + column
                frames[(action.name, direction, column)] = _center_component(
                    source,
                    owners,
                    owner_index,
                    frame_name,
                )

    return frames


def _save_individual_frames(
    frames: dict[tuple[str, str, int], Image.Image],
    animation_root: Path,
) -> None:
    resampling = getattr(Image, "Resampling", Image).LANCZOS
    roots = {
        BASE_CELL_SIZE: animation_root / "frames_original",
        256: animation_root / "frames_256",
    }

    for (action, direction, frame_index), frame in frames.items():
        filename = f"{direction}_{frame_index:02d}.png"
        for size, output_root in roots.items():
            output_path = output_root / action / filename
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output = frame
            if size != BASE_CELL_SIZE:
                output = frame.resize((size, size), resampling)
            output.save(output_path)


def _build_atlas(
    frames: dict[tuple[str, str, int], Image.Image],
    size: int,
) -> tuple[Image.Image, list[dict[str, object]]]:
    resampling = getattr(Image, "Resampling", Image).LANCZOS
    total_columns = sum(action.columns for action in ACTIONS)
    atlas = Image.new(
        "RGBA",
        (total_columns * size, len(DIRECTIONS) * size),
        (0, 0, 0, 0),
    )
    entries: list[dict[str, object]] = []
    column_offset = 0

    for action in ACTIONS:
        for row, direction in enumerate(DIRECTIONS):
            for frame_index in range(action.columns):
                frame = frames[(action.name, direction, frame_index)]
                if size != BASE_CELL_SIZE:
                    frame = frame.resize((size, size), resampling)
                column = column_offset + frame_index
                atlas.alpha_composite(
                    frame,
                    (column * size, row * size),
                )
                entries.append(
                    {
                        "name": (
                            f"{action.name}_{direction}_{frame_index:02d}"
                        ),
                        "action": action.name,
                        "direction": direction,
                        "frame": frame_index,
                        "atlas_coords": [column, row],
                        "pixel_rect": [
                            column * size,
                            row * size,
                            size,
                            size,
                        ],
                    }
                )
        column_offset += action.columns

    return atlas, entries


def _create_preview(atlas_32: Image.Image, path: Path) -> None:
    scale = 6
    checker = Image.new("RGBA", atlas_32.size, (225, 225, 225, 255))
    draw = ImageDraw.Draw(checker)
    for y in range(0, checker.height, 8):
        for x in range(0, checker.width, 8):
            if (x // 8 + y // 8) % 2 == 0:
                draw.rectangle(
                    (x, y, x + 7, y + 7),
                    fill=(185, 185, 185, 255),
                )
    checker.alpha_composite(atlas_32)
    preview = checker.resize(
        (checker.width * scale, checker.height * scale),
        getattr(Image, "Resampling", Image).NEAREST,
    )
    preview_draw = ImageDraw.Draw(preview)
    for column in range(sum(action.columns for action in ACTIONS) + 1):
        x = column * 32 * scale
        preview_draw.line((x, 0, x, preview.height), fill=(255, 0, 255), width=1)
    for row in range(len(DIRECTIONS) + 1):
        y = row * 32 * scale
        preview_draw.line((0, y, preview.width, y), fill=(255, 0, 255), width=1)
    path.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(path)


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    animation_root = (
        project_root
        / "assets/concepts/unfinished_world/player_animation"
    )
    transparent_root = animation_root / "transparent"
    sprite_root = project_root / "assets/sprites/player"
    sprite_root.mkdir(parents=True, exist_ok=True)

    frames = _load_frames(transparent_root)
    _save_individual_frames(frames, animation_root)

    atlases: dict[str, object] = {}
    entries_256: list[dict[str, object]] = []
    atlas_32: Image.Image | None = None
    for size in (BASE_CELL_SIZE, *OUTPUT_SIZES):
        atlas, entries = _build_atlas(frames, size)
        suffix = "original" if size == BASE_CELL_SIZE else str(size)
        filename = f"unfinished_world_player_actions_{suffix}.png"
        atlas.save(sprite_root / filename)
        atlases[suffix] = {
            "image": str((sprite_root / filename).relative_to(project_root)),
            "cell_size": size,
            "columns": sum(action.columns for action in ACTIONS),
            "rows": len(DIRECTIONS),
            "size": [atlas.width, atlas.height],
        }
        if size == 256:
            entries_256 = entries
        if size == 32:
            atlas_32 = atlas

    action_metadata: list[dict[str, object]] = []
    column_offset = 0
    for action in ACTIONS:
        action_metadata.append(
            {
                "name": action.name,
                "start_column": column_offset,
                "frame_count": action.columns,
                "frame_duration": action.frame_duration,
                "loop": action.loop,
            }
        )
        column_offset += action.columns

    manifest = {
        "directions": list(DIRECTIONS),
        "row_mapping": {
            direction: row for row, direction in enumerate(DIRECTIONS)
        },
        "actions": action_metadata,
        "atlases": atlases,
        "entries_256": entries_256,
    }
    manifest_path = sprite_root / "unfinished_world_player_actions.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    if args.preview_directory is not None:
        if atlas_32 is None:
            raise RuntimeError("32px atlas was not generated.")
        _create_preview(
            atlas_32,
            args.preview_directory
            / "unfinished_world_player_actions_32_preview.png",
        )

    print(f"Built {len(frames)} frames.")
    print(f"Manifest: {manifest_path.relative_to(project_root)}")


if __name__ == "__main__":
    main()
