class_name IdGenerator
extends RefCounted

## 通用唯一ID生成器
## node: 当前在场景中的节点 (如 Enemy, Pickup)
## resource: 绑定的数据资源 (如 EnemyData, ItemData) 可传 null
static func generate_instance_id(node: Node, resource: Resource = null) -> String:
	var data_name := "unknown"
	if resource != null and not resource.resource_path.is_empty():
		data_name = resource.resource_path.get_file().get_basename()
		
	var scene_name := "dynamic"
	var node_identifier := node.name
	if node.owner != null:
		scene_name = node.owner.name
		# 针对可能有同名节点深层嵌套的情况，用相对路径最保险
		node_identifier = str(node.owner.get_path_to(node)).replace("/", "_")
		
	return "%s_%s_%s" % [scene_name, data_name, node_identifier]
