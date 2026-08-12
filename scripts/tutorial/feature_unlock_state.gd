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


func capture_save_data() -> Array[String]:
	var result: Array[String] = []
	for feature_id: StringName in _unlocked_features.keys():
		result.append(String(feature_id))
	return result


func restore_save_data(data: Variant) -> void:
	_unlocked_features.clear()

	if not data is Array:
		return

	for feature_value: Variant in data:
		var feature_id := StringName(String(feature_value))
		if feature_id.is_empty():
			continue
		_unlocked_features[feature_id] = true
		feature_unlocked.emit(feature_id)
