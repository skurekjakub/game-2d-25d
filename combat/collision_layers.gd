class_name CollisionLayers
extends RefCounted

## Centralised collision-layer bitfield values. Mirrors the named layers in
## project.godot [layer_names]. Use these constants in any GDScript that
## sets collision_layer / collision_mask at runtime (tests, factories,
## procedural spawns). .tscn files still carry the raw integers because
## Godot serializes the bitfield positionally — but the inspector shows
## the project.godot labels alongside, so editing in-editor stays readable.

const ENVIRONMENT: int = 1 << 0  # 1   — walls, static world geometry
const PLAYER: int = 1 << 1  # 2   — the Player's CharacterBody2D
const ENEMIES: int = 1 << 2  # 4   — every Enemy CharacterBody2D

## Convenient masks (compose with `|` when you need a custom one).

const MASK_NONE: int = 0
const MASK_ENVIRONMENT: int = ENVIRONMENT  # 1
const MASK_PLAYER: int = PLAYER  # 2
const MASK_ENEMIES: int = ENEMIES  # 4
const MASK_ENVIRONMENT_AND_ENEMIES: int = ENVIRONMENT | ENEMIES  # 5  (Enemy.body)
