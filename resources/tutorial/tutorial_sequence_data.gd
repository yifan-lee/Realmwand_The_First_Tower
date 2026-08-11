class_name TutorialSequenceData
extends Resource


enum TriggerEvent {
	ITEM_ADDED,
	BATTLE_STARTED,
	SKILL_LEARNED,
}

@export var sequence_id: StringName
@export var steps: Array[TutorialStepData] = []
@export var trigger_event: TriggerEvent
@export var trigger_item_type: ItemData.ItemType
@export var trigger_item_id: StringName = &""
@export var trigger_cost_type: ActionCostData.CostType = ActionCostData.CostType.MP