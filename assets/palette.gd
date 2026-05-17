class_name Palette
extends RefCounted

## Project-wide colour constants. Every Color literal in production code
## should reference one of these names — raw `Color(r, g, b, a)` literals
## are unreadable at the call site. When real art lands and these placeholder
## shapes go away, change the values here and every consumer follows.
##
## .tscn caveat: Godot's scene serializer can't reference a script constant
## inside a property assignment, so scenes pull their colour at runtime via
## their owning script's _ready(). The constants here are the single source
## of truth; the .tscn shapes use whatever the script assigns and ignore any
## leftover inline Color() (which has been stripped from the .tscn files
## this constant class shipped with).

# Backgrounds / world
const ARENA_BG := Color(0.15, 0.15, 0.18, 1.0)  # deep gray-violet
const FLOOR_GRID_LINE := Color(0.25, 0.25, 0.28, 1.0)  # slightly lighter, low contrast on ARENA_BG

# Actors
const PLAYER_BODY := Color(0.3, 0.6, 1.0, 1.0)  # cyan-blue
const PLAYER_DAMAGE_FLASH := Color(1.0, 0.3, 0.3, 1.0)  # bright red, brief tween
const ENEMY_BODY := Color(0.85, 0.25, 0.25, 1.0)  # crimson

# Pickups / projectiles
const XP_GEM := Color(0.3, 1.0, 0.5, 1.0)  # vibrant green
const PROJECTILE_BASIC := Color(1.0, 0.95, 0.4, 1.0)  # warm yellow
