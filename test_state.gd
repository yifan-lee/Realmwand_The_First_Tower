@tool
extends SceneTree

func _init():
	var script = load("res://scripts/floors/floor_3.gd")
	var instance = script.new()
	instance.is_rule_active = false
	var state = instance.capture_runtime_state()
	print("Captured state: ", state)
	
	instance.is_rule_active = true
	instance.apply_runtime_state(state)
	print("Applied state. is_rule_active is now: ", instance.is_rule_active)
	quit()
