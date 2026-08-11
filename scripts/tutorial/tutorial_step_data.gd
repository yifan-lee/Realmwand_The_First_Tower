class_name TutorialStepData
extends Resource


enum CompletionEvent {
	ITEM_ADDED,
	MENU_OPENED,
	ITEM_FOCUSED,
	ITEM_SELECTED,
}


@export var step_id: StringName
@export_multiline var prompt_text: String
@export var completion_event: CompletionEvent
@export var target_item_id: StringName
@export var next_step_id: StringName