extends Floor

@export var switch_wall_position: Vector2
@export var closed_wall_source_id: int = -1
@export var closed_wall_atlas_coords: Vector2i = Vector2i(-1, -1)
@export var closed_wall_alternative_tile: int = 0

@onready var floor_switch: TowerSwitch = $Switch
@onready var walls: TileMapLayer = $Map/Walls


func _ready() -> void:
	super()

	floor_switch.state_changed.connect(
		_on_switch_state_changed
	)
	_apply_switch_map_state()


func _on_switch_state_changed(
	_switch_id: int,
	_is_active: bool
) -> void:
	_apply_switch_map_state()


func restore_runtime_state(state: Dictionary) -> void:
	super(state)
	_apply_switch_map_state()


func _apply_switch_map_state() -> void:
	var wall_global_position := to_global(
		switch_wall_position
	)
	var wall_cell := walls.local_to_map(
		walls.to_local(wall_global_position)
	)

	if floor_switch.is_active:
		walls.erase_cell(wall_cell)
		return

	assert(
		closed_wall_source_id >= 0,
		"Floor 1 closed wall source is not configured"
	)
	walls.set_cell(
		wall_cell,
		closed_wall_source_id,
		closed_wall_atlas_coords,
		closed_wall_alternative_tile
	)
