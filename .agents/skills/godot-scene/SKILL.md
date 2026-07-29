---
name: godot-scene
description: Enforce scene-first Godot development. Use whenever planning, creating, modifying, refactoring, or reviewing a Godot scene, node tree, UI layout, reusable component, or a GDScript that may create or configure visible nodes.
---

# Godot Scene-First Workflow

Treat the scene as the source of truth for all design-time structure. Treat GDScript as behavior attached to that structure.

## Prerequisite

Run `godot-mcp-setup` first. If Godot MCP Pro is unavailable, stop all Godot scene, script, and resource work.

## Classify Before Editing

Classify every requested element before creating it.

| Put it in a scene/resource | Put it in script |
| --- | --- |
| Node hierarchy and names | Input, state transitions, rules, and signal handling |
| UI hierarchy, anchors, offsets, size, theme, and baseline text | State-derived presentation and temporary feedback |
| Fixed sprite, material, animation, collision, and inspector settings | Runtime calculations and data-driven decisions |
| Reusable UI, entity, and tween components | Spawning when quantity or lifetime is unknown before play |

Use this test: if a human designer can decide the node, its parent, its base appearance, or its layout before pressing Play, serialize it in a `.tscn` or `.tres` and make it visible in the editor.

## Non-Negotiable Rules

- Build every design-time node tree through Godot MCP Pro. Never hand-edit `.tscn` files.
- Do not use `_ready()` or another script callback to create a fixed screen, fixed UI layout, or fixed child-node hierarchy.
- Do not hard-code fixed layout or art-direction values in scripts: anchors, offsets, positions, sizes, theme overrides, colors, fonts, materials, or base transforms belong in the Inspector.
- Do not leave an empty scene whose real structure is assembled by a script. Stop and move that structure into the scene before continuing.
- Make reusable UI, entities, and reusable animation/tween effects independent scenes. Configure their defaults in the Inspector and expose only genuine behavior controls with `@export`.
- Store game data that designers should edit independently in `.tres` resources or JSON, not in scene-building code.

## Resource Rules

- Create a typed custom `Resource` and save an external `.tres` when data has a fixed schema, needs Inspector editing, is reused by more than one scene or system, or should be tuned independently by design. Use it for character, ability, item, palette, theme, material, and configuration definitions.
- Use JSON only for large external tables, mod-facing data, or data that requires external tooling. Do not use a Dictionary or GDScript constants as a substitute for a resource definition.
- Keep shared definitions as external `.tres` files under `resources/data/` or `resources/themes/`. Allow a scene-local SubResource only when it is small, unique to that scene, and not intended for reuse.
- Assign resources through typed exported properties and Inspector references. Read shared resources as definitions; keep health, cooldowns, temporary state, and other instance data on runtime nodes or state objects. Never write runtime state back into a shared `.tres`.
- Create, edit, assign, and inspect resources through Godot MCP Pro. Never hand-edit `.tres` files.

## Color Rules

- Use shared `Theme.tres` for fixed UI colors, fonts, StyleBoxes, and Control states. Use scene or material Inspector properties for fixed world visuals. Use `ColorPalette.tres` for semantic data colors such as faction, rarity, element, and runtime state.
- Do not use a script to apply fixed UI or art-direction colors on startup. Reference the Theme, material, palette, or scene property that owns the fixed value.
- Use GDScript colors only for runtime state, interaction feedback, or dynamically generated content. Write every color literal exactly as `Color("#RRGGBBAA")`, including `FF` for an opaque alpha channel.
- Do not write normalized component literals such as `Color(1.0, 0.5, 0.0)`, named colors such as `Color.RED`, or any other color-literal form in GDScript.

## Allowed Runtime Construction

Construct nodes in code only when their quantity, lifetime, or identity is unknowable before play: spawned actors, pooled effects, procedurally generated content, network replicas, and temporary debug instrumentation.

For every exception:

1. Instantiate a prebuilt `PackedScene` whenever the runtime object has a visual or gameplay structure.
2. Keep the factory focused on lifecycle and data; do not rebuild a static UI or entity subtree node-by-node.
3. Add a short `Runtime-only:` comment explaining why the object cannot exist in a saved scene.

## Required Workflow

1. State the intended scene tree, required external resources, and runtime-only exceptions before editing.
2. Open the target scene with MCP and inspect its existing tree.
3. Create or change design-time nodes with `create_scene`, `add_node`, `add_scene_instance`, `update_property`, `connect_signal`, and `save_scene`. Create or edit required `.tres` resources with MCP before assigning them in the Inspector.
4. Write `.gd` only after the node tree exists. Attach it with MCP. Use node references and signals to control existing nodes rather than constructing their layout.
5. Put visual, layout, material, shader, animation, color, and reusable-component defaults in Inspector-visible properties or referenced resources. Use `@export` only for values that are intended to be tuned as behavior or resource references.
6. When refactoring a script-built fixed structure, create the scene structure first, transfer its static values to Inspector properties, then delete the construction code. Do not keep a compatibility layer.

## Required Validation

Before completion:

1. Validate changed scripts and check editor errors.
2. Inspect the saved scene tree, relevant Inspector properties, and resource references through MCP; they must contain the intended fixed structure and data.
3. Run the scene. For visible work, capture and inspect a screenshot; for interaction, simulate input and assert the result.
4. Run `godot-mvp-test` for project-level regression, goal-specific validation, evidence storage, and progress recording.

## Completion Report

Report the saved scene/component paths, the fixed structure placed in scenes/resources, any allowed runtime-only construction and its reason, and validation evidence. Do not claim success if fixed structure remains hidden in script code.
