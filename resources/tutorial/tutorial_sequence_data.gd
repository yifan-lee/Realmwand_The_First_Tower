class_name TutorialSequenceData
extends Resource


enum TriggerEvent {
	ITEM_ADDED,
}

@export var sequence_id: StringName
@export var steps: Array[TutorialStepData] = []
@export var trigger_event: TriggerEvent
@export var trigger_item_type: ItemData.ItemType