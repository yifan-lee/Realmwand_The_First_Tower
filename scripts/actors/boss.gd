@tool
class_name Boss
extends Enemy

@export_group("Boss Settings")
## 控制 Boss 占用的地块大小，例如 (2, 2) 代表 2x2
@export var grid_size: Vector2i = Vector2i(2, 2):
	set(value):
		grid_size = value
		if is_node_ready():
			_update_size()

const TILE_BASE_SIZE = Vector2(24, 20)

func _ready() -> void:
	super._ready()
	_update_size()

func _refresh_visual() -> void:
	super._refresh_visual()
	# Boss sprite scaling can be handled here if needed,
	# For now we rely on standard Enemy scaling or manual Inspector scale.
	pass

func _update_size() -> void:
	var shape_node = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
		
	var rect_shape = shape_node.shape as RectangleShape2D
	if rect_shape == null:
		# If the shape is not created yet, we could instantiate it, but we expect MCP/Editor to have created it.
		rect_shape = RectangleShape2D.new()
		shape_node.shape = rect_shape
		
	rect_shape.size = Vector2(TILE_BASE_SIZE.x * grid_size.x, TILE_BASE_SIZE.y * grid_size.y)
	
	# Usually, standard tile grid centers are top-left or centered. 
	# If the base size is 1x1 centered, a 2x2 boss needs a shift to align to grid if the anchor is top-left.
	# For now, keep it centered at the Boss node position, which is standard.
