#!/usr/bin/env python3
"""Safely split transparent concept sheets into isolated square PNG files."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image


@dataclass(frozen=True)
class SheetSpec:
    filename: str
    columns: int
    rows: int
    output_directory: str
    names: tuple[str, ...]


SHEETS = (
    SheetSpec(
        "player_design_sheet.png",
        4,
        2,
        "player",
        (
            "front_wand_left",
            "front_wand_right",
            "side_left",
            "side_right",
            "walk",
            "interact",
            "attack",
            "hurt",
        ),
    ),
    SheetSpec(
        "monster_archetypes_sheet.png",
        4,
        4,
        "monsters",
        tuple(
            f"{archetype}_tier_{tier}"
            for tier in range(1, 5)
            for archetype in ("atk", "def", "spd", "balanced")
        ),
    ),
    SheetSpec(
        "wearable_equipment_sheet.png",
        5,
        4,
        "equipment/wearable",
        tuple(
            f"{slot}_tier_{tier}"
            for tier in range(1, 5)
            for slot in ("head", "chest", "legs", "feet", "hands")
        ),
    ),
    SheetSpec(
        "weapons_defense_sheet.png",
        4,
        4,
        "equipment/weapons",
        tuple(
            f"{weapon}_tier_{tier}"
            for tier in range(1, 5)
            for weapon in ("one_hand", "two_hand", "shield", "offhand")
        ),
    ),
    SheetSpec(
        "wearable_equipment_sheet_v2.png",
        5,
        4,
        "equipment/wearable_v2",
        tuple(
            f"{slot}_tier_{tier}"
            for tier in range(1, 5)
            for slot in (
                "head_mp",
                "chest_def",
                "legs_hp",
                "hands_atk",
                "feet_spd",
            )
        ),
    ),
    SheetSpec(
        "expanded_weapons_sheet_v2.png",
        7,
        4,
        "equipment/weapons_v2",
        tuple(
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
        ),
    ),
    SheetSpec(
        "items_tokens_sheet.png",
        6,
        4,
        "items",
        tuple(
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
        ),
    ),
    SheetSpec(
        "exchange_interactables_sheet.png",
        4,
        3,
        "interactables",
        tuple(
            f"{kind}_{attribute}"
            for kind in ("npc", "statue", "terminal")
            for attribute in ("atk", "def", "spd", "universal")
        ),
    ),
    SheetSpec(
        "environment_tiles_sheet.png",
        5,
        4,
        "tiles",
        (
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
        ),
    ),
)


class UnionFind:
    def __init__(self) -> None:
        self.parent: list[int] = []

    def add(self) -> int:
        label = len(self.parent)
        self.parent.append(label)
        return label

    def find(self, label: int) -> int:
        root = label
        while self.parent[root] != root:
            root = self.parent[root]
        while self.parent[label] != label:
            parent = self.parent[label]
            self.parent[label] = root
            label = parent
        return root

    def union(self, first: int, second: int) -> None:
        first_root = self.find(first)
        second_root = self.find(second)
        if first_root != second_root:
            self.parent[second_root] = first_root


@dataclass
class Run:
    y: int
    x_start: int
    x_end: int
    label: int


@dataclass
class Component:
    runs: list[Run]
    area: int = 0
    x_sum: float = 0.0
    y_sum: float = 0.0

    @property
    def center(self) -> tuple[float, float]:
        return self.x_sum / self.area, self.y_sum / self.area

    @property
    def bounds(self) -> tuple[int, int, int, int]:
        return (
            min(run.x_start for run in self.runs),
            min(run.y for run in self.runs),
            max(run.x_end for run in self.runs),
            max(run.y for run in self.runs),
        )


def _row_runs(row: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    padded = np.pad(row, (1, 1), constant_values=False)
    transitions = np.diff(padded.astype(np.int8))
    starts = np.flatnonzero(transitions == 1)
    ends = np.flatnonzero(transitions == -1) - 1
    return starts, ends


def find_components(mask: np.ndarray, minimum_area: int) -> list[Component]:
    union_find = UnionFind()
    runs: list[Run] = []
    previous_runs: list[Run] = []

    for y in range(mask.shape[0]):
        starts, ends = _row_runs(mask[y])
        current_runs: list[Run] = []
        previous_index = 0

        for x_start, x_end in zip(starts.tolist(), ends.tolist(), strict=True):
            label = union_find.add()
            current = Run(y, x_start, x_end, label)

            while (
                previous_index < len(previous_runs)
                and previous_runs[previous_index].x_end < x_start - 1
            ):
                previous_index += 1

            overlap_index = previous_index
            while (
                overlap_index < len(previous_runs)
                and previous_runs[overlap_index].x_start <= x_end + 1
            ):
                union_find.union(label, previous_runs[overlap_index].label)
                overlap_index += 1

            current_runs.append(current)
            runs.append(current)

        previous_runs = current_runs

    components: dict[int, Component] = {}
    for run in runs:
        root = union_find.find(run.label)
        component = components.setdefault(root, Component([]))
        length = run.x_end - run.x_start + 1
        component.runs.append(run)
        component.area += length
        component.x_sum += (run.x_start + run.x_end) * length / 2.0
        component.y_sum += run.y * length

    return [
        component
        for component in components.values()
        if component.area >= minimum_area
    ]


def assign_components(
    components: list[Component],
    width: int,
    height: int,
    columns: int,
    rows: int,
) -> list[list[Component]]:
    initial_assignments: list[list[Component]] = [
        [] for _ in range(columns * rows)
    ]
    cell_width = width / columns
    cell_height = height / rows

    for component in components:
        center_x, center_y = component.center
        column = min(columns - 1, max(0, int(center_x / cell_width)))
        row = min(rows - 1, max(0, int(center_y / cell_height)))
        initial_assignments[row * columns + column].append(component)

    if any(not assignment for assignment in initial_assignments):
        raise RuntimeError("A grid cell has no foreground component anchor.")

    anchors = [max(assignment, key=lambda item: item.area) for assignment in initial_assignments]
    anchor_owners = {id(anchor): index for index, anchor in enumerate(anchors)}
    assignments: list[list[Component]] = [[] for _ in range(columns * rows)]

    for component in components:
        locked_owner = anchor_owners.get(id(component))
        if locked_owner is not None:
            assignments[locked_owner].append(component)
            continue

        component_x_min, component_y_min, component_x_max, component_y_max = (
            component.bounds
        )
        component_center_x, component_center_y = component.center
        best_owner = 0
        best_score: tuple[float, float] | None = None

        for owner, anchor in enumerate(anchors):
            anchor_x_min, anchor_y_min, anchor_x_max, anchor_y_max = anchor.bounds
            horizontal_gap = max(
                anchor_x_min - component_x_max,
                component_x_min - anchor_x_max,
                0,
            )
            vertical_gap = max(
                anchor_y_min - component_y_max,
                component_y_min - anchor_y_max,
                0,
            )
            boundary_distance = horizontal_gap**2 + vertical_gap**2
            anchor_center_x, anchor_center_y = anchor.center
            center_distance = (
                (component_center_x - anchor_center_x) ** 2
                + (component_center_y - anchor_center_y) ** 2
            )
            score = (boundary_distance, center_distance)
            if best_score is None or score < best_score:
                best_score = score
                best_owner = owner

        assignments[best_owner].append(component)

    return assignments


def isolate_assets(
    rgba: np.ndarray,
    assignments: list[list[Component]],
) -> list[Image.Image]:
    isolated: list[Image.Image] = []

    for components in assignments:
        if not components:
            raise RuntimeError("A grid cell has no assigned foreground components.")

        x_min = min(run.x_start for component in components for run in component.runs)
        x_max = max(run.x_end for component in components for run in component.runs)
        y_min = min(run.y for component in components for run in component.runs)
        y_max = max(run.y for component in components for run in component.runs)

        crop = np.zeros((y_max - y_min + 1, x_max - x_min + 1, 4), dtype=np.uint8)
        for component in components:
            for run in component.runs:
                destination_y = run.y - y_min
                destination_start = run.x_start - x_min
                destination_end = run.x_end - x_min + 1
                crop[destination_y, destination_start:destination_end] = rgba[
                    run.y, run.x_start : run.x_end + 1
                ]

        isolated.append(Image.fromarray(crop, mode="RGBA"))

    return isolated


def square_canvases(images: list[Image.Image]) -> list[Image.Image]:
    maximum_extent = max(max(image.size) for image in images)
    padding = max(8, round(maximum_extent * 0.06))
    side = maximum_extent + padding * 2
    canvases: list[Image.Image] = []

    for image in images:
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        offset = ((side - image.width) // 2, (side - image.height) // 2)
        canvas.alpha_composite(image, offset)
        canvases.append(canvas)

    return canvases


def save_assets(
    canvases: list[Image.Image],
    names: tuple[str, ...],
    original_directory: Path,
    normalized_directory: Path,
) -> None:
    original_directory.mkdir(parents=True, exist_ok=True)
    normalized_directory.mkdir(parents=True, exist_ok=True)
    resampling = getattr(Image, "Resampling", Image).LANCZOS

    for canvas, name in zip(canvases, names, strict=True):
        canvas.save(original_directory / f"{name}.png")
        canvas.resize((256, 256), resampling).save(
            normalized_directory / f"{name}.png"
        )


def validate_assets(directory: Path, names: tuple[str, ...]) -> None:
    expected_side: int | None = None

    for name in names:
        path = directory / f"{name}.png"
        with Image.open(path) as image:
            if image.mode != "RGBA":
                raise RuntimeError(f"{path} is not RGBA.")
            if image.width != image.height:
                raise RuntimeError(f"{path} is not square.")
            if expected_side is None:
                expected_side = image.width
            elif image.width != expected_side:
                raise RuntimeError(f"{path} has an inconsistent canvas size.")

            alpha = np.asarray(image.getchannel("A"))
            if not np.any(alpha):
                raise RuntimeError(f"{path} is empty.")
            border = np.concatenate(
                (alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1])
            )
            if np.any(border):
                raise RuntimeError(f"{path} has foreground touching its border.")


def create_preview(
    directory: Path,
    names: tuple[str, ...],
    columns: int,
    rows: int,
    output_path: Path,
) -> None:
    tile_size = 160
    content_size = 144
    preview = Image.new(
        "RGBA",
        (columns * tile_size, rows * tile_size),
        (233, 228, 216, 255),
    )
    resampling = getattr(Image, "Resampling", Image).LANCZOS

    for index, name in enumerate(names):
        with Image.open(directory / f"{name}.png") as image:
            tile = image.convert("RGBA")
        tile.thumbnail((content_size, content_size), resampling)
        column = index % columns
        row = index // columns
        offset = (
            column * tile_size + (tile_size - tile.width) // 2,
            row * tile_size + (tile_size - tile.height) // 2,
        )
        preview.alpha_composite(tile, offset)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(output_path)


def create_preview_overview(preview_directory: Path) -> None:
    cell_width = 560
    cell_height = 440
    overview = Image.new("RGB", (cell_width * 3, cell_height * 3), (96, 96, 96))
    resampling = getattr(Image, "Resampling", Image).LANCZOS

    for index, spec in enumerate(SHEETS):
        preview_path = (
            preview_directory / f"{Path(spec.filename).stem}_split_preview.png"
        )
        with Image.open(preview_path) as image:
            preview = image.convert("RGB")
        preview.thumbnail((cell_width - 24, cell_height - 24), resampling)
        column = index % 3
        row = index // 3
        offset = (
            column * cell_width + (cell_width - preview.width) // 2,
            row * cell_height + (cell_height - preview.height) // 2,
        )
        overview.paste(preview, offset)

    overview.save(preview_directory / "all_split_preview.png")


def process_sheet(
    asset_root: Path,
    spec: SheetSpec,
    preview_directory: Path | None,
) -> None:
    input_path = asset_root / "transparent" / spec.filename
    with Image.open(input_path) as image:
        rgba_image = image.convert("RGBA")
    rgba = np.asarray(rgba_image)
    mask = rgba[:, :, 3] > 0

    components = find_components(mask, minimum_area=12)
    assignments = assign_components(
        components,
        rgba_image.width,
        rgba_image.height,
        spec.columns,
        spec.rows,
    )
    if len(spec.names) != spec.columns * spec.rows:
        raise RuntimeError(f"{spec.filename} has an invalid name mapping.")

    isolated = isolate_assets(rgba, assignments)
    canvases = square_canvases(isolated)
    original_directory = asset_root / "split_original" / spec.output_directory
    normalized_directory = asset_root / "split" / spec.output_directory
    save_assets(canvases, spec.names, original_directory, normalized_directory)
    validate_assets(original_directory, spec.names)
    validate_assets(normalized_directory, spec.names)
    if preview_directory is not None:
        create_preview(
            normalized_directory,
            spec.names,
            spec.columns,
            spec.rows,
            preview_directory / f"{Path(spec.filename).stem}_split_preview.png",
        )

    print(
        f"{spec.filename}: {len(spec.names)} assets, "
        f"{len(components)} components, "
        f"original square {canvases[0].width}px"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--asset-root",
        type=Path,
        default=Path("assets/concepts/unfinished_world"),
    )
    parser.add_argument("--preview-directory", type=Path)
    arguments = parser.parse_args()

    for spec in SHEETS:
        process_sheet(
            arguments.asset_root,
            spec,
            arguments.preview_directory,
        )
    if arguments.preview_directory is not None:
        create_preview_overview(arguments.preview_directory)


if __name__ == "__main__":
    main()
