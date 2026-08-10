@tool
class_name VisualUtils
extends RefCounted

const TILE_SIZE: float = 32.0

## 根据给定的网格尺寸，自动缩放贴图以完美贴合网格。
## [param sprite]: 需要缩放的 Sprite2D 节点
## [param grid_size]: 该物体占据的网格数量（例如 1x1, 3x3）
## [param scale_multiplier]: 额外的缩放倍数，常用于抵消原图中的透明边框带来的“视觉偏小”问题
static func auto_scale_sprite(sprite: Node2D, grid_size: Vector2i = Vector2i(1, 1), scale_multiplier: float = 1.0) -> void:
	if sprite == null:
		return
		
	var texture_size = Vector2.ZERO
	
	if sprite is Sprite2D and sprite.texture != null:
		texture_size = sprite.texture.get_size()
	elif sprite is AnimatedSprite2D and sprite.sprite_frames != null:
		var tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if tex != null:
			texture_size = tex.get_size()
			
	if texture_size.x > 0:
		var target_width = grid_size.x * TILE_SIZE
		var required_scale = target_width / texture_size.x
		
		# 应用基础缩放和手动补偿倍数
		var final_scale = required_scale * scale_multiplier
		sprite.scale = Vector2(final_scale, final_scale)
