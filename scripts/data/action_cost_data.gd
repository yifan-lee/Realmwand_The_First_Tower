class_name ActionCostData
extends Resource

enum CostType {
	HP,
	MP,
	FP,
	COOLDOWN,
	CAST_TIME,
}

@export var cost_type: CostType = CostType.MP
@export var value: float = 0.0


func get_cooldown() -> int:
	if cost_type == CostType.COOLDOWN:
		return int(value)
	return 0


func get_description() -> String:
	match cost_type:
		CostType.HP:
			return "消耗生命：%.0f" % value
		CostType.MP:
			return "消耗魔力：%.0f" % value
		CostType.FP:
			return "消耗专注：%.0f" % value
		CostType.COOLDOWN:
			return "冷却：%d 次行动" % get_cooldown()
		CostType.CAST_TIME:
			return "吟唱：行动条倒退 %.0f%%" % (value * 100.0)
	return ""
