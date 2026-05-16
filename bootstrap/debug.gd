extends Node

var god_mode: bool = false
var time_scale: float = 1.0
var show_overlay: bool = false


func _ready() -> void:
	if OS.is_debug_build():
		print("[Debug] enabled (debug build)")


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_F4:
			god_mode = not god_mode
			print("[Debug] god_mode = %s" % god_mode)
		KEY_F12:
			show_overlay = not show_overlay
			print("[Debug] show_overlay = %s" % show_overlay)
		# F1/F2/F3/F5/F6/F7 added in milestone 1.7 when their targets exist
