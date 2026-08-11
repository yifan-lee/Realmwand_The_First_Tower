class_name FeatureUnlockState
extends Node


signal feature_unlocked(
	feature_id: StringName
)


var _unlocked_features: Dictionary = {}


func is_unlocked(feature_id: StringName) -> bool:
	return _unlocked_features.get(
		feature_id,
		false
	)


func unlock(feature_id: StringName) -> void:
	if feature_id.is_empty():
		return

	if is_unlocked(feature_id):
		return

	_unlocked_features[feature_id] = true
	feature_unlocked.emit(feature_id)