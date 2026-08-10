@tool
extends EditorScript

func _run() -> void:
	var root := PanelContainer.new()
	root.name = "FloorInfoHUD"
	root.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	root.offset_left = 24
	root.offset_bottom = -24
	root.offset_right = 24 + 200
	root.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.theme_type_variation = &"TerminalPanel"
	
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 4)
	root.add_child(content)
	content.owner = root
	
	var title := Label.new()
	title.name = "TitleLabel"
	title.theme_type_variation = &"HeaderLarge"
	content.add_child(title)
	title.owner = root
	
	var desc := Label.new()
	desc.name = "DescLabel"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(200, 0)
	content.add_child(desc)
	desc.owner = root
	
	var script = load("res://scripts/ui/components/floor_info_hud.gd")
	root.set_script(script)
	
	var packed_scene := PackedScene.new()
	packed_scene.pack(root)
	
	ResourceSaver.save(packed_scene, "res://scenes/ui/components/floor_info_hud.tscn")
	print("Saved floor_info_hud.tscn successfully")
	
	var game_hud_scene = load("res://scenes/ui/game_hud.tscn")
	var game_hud = game_hud_scene.instantiate()
	var inst = game_hud.get_node_or_null("HudRoot/FloorInfoHUD")
	if inst != null:
		inst.grow_vertical = Control.GROW_DIRECTION_BEGIN
		inst.remove_meta("offset_top") # Just in case, actually set properties to match
		inst.offset_left = 24
		inst.offset_bottom = -24
		inst.offset_right = 24 + 200
		
		# to clear overrides we can re-instance it or just set them to the defaults
		# actually, if we just replace it...
		inst.free()
		var new_inst = load("res://scenes/ui/components/floor_info_hud.tscn").instantiate()
		game_hud.get_node("HudRoot").add_child(new_inst)
		new_inst.owner = game_hud
		
		var packed_hud = PackedScene.new()
		packed_hud.pack(game_hud)
		ResourceSaver.save(packed_hud, "res://scenes/ui/game_hud.tscn")
		print("Saved game_hud.tscn successfully")
