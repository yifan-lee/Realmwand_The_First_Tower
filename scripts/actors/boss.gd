@tool
class_name Boss
extends Enemy

## Boss 默认按 24×24 的单格碰撞体计算。
## grid_size=(3,3) 时，碰撞体就是 72×72，与三倍 Boss 网格一致。
@export var collision_scale_multiplier: float = 1.0:
	set(value):
		collision_scale_multiplier = maxf(value, 0.01)
		if is_node_ready():
			_update_size()


func get_collision_tile_size() -> Vector2:
	return Vector2(24.0, 24.0) * collision_scale_multiplier
